/*********************************************************************************
 *
 * adv7513.c
 *
 *  Created on: 11.09.2018
 *      Author: Peter Bartmann
 *
 ********************************************************************************/

#include "app_cfg.h"

#include "alt_types.h"
#include "common_types.h"
#include "i2c.h"
#include "system.h"
#include "altera_avalon_pio_regs.h"

#include "adv7513.h"
#include "adv7513_regs_p.h"


#define adv7513_reg_bitset(regaddr_p,bit)         i2c_reg_bitset(ADV7513_I2C_BASE,regaddr_p,0,bit,0)
#define adv7513_reg_bitclear(regaddr_p,bit)       i2c_reg_bitclear(ADV7513_I2C_BASE,regaddr_p,0,bit,0)

#define adv7513_readreg_n(regaddr_p,retvals_p,n)  i2c_readregs(ADV7513_I2C_BASE,regaddr_p,0,retvals_p,n)
#define adv7513_writereg_n(regaddr_p,data_p,n)    i2c_writeregs(ADV7513_I2C_BASE,regaddr_p,0,data_p,n)

#define adv7513_readreg(regaddr_p,retvals_p)      adv7513_readreg_n(regaddr_p,retvals_p,1)
#define adv7513_writereg(regaddr_p,data_p)        adv7513_writereg_n(regaddr_p,data_p,1)

#define tmp_reg_read()                            i2c_readregs(ADV7513_I2C_BASE,&tmp_reg_8b_8b.addr,0,&tmp_reg_8b_8b.data,1)
#define tmp_reg_write()                           i2c_writeregs(ADV7513_I2C_BASE,&tmp_reg_8b_8b.addr,0,&tmp_reg_8b_8b.data,1)



bool_t adv_power_rdy(void) {
  tmp_reg_8b_8b.addr = ADV7513_REG_STATUS;
  tmp_reg_read();
  return ((tmp_reg_8b_8b.data & 0x70) == 0x70);
}

bool_t adv_hpd_state(void) {
  tmp_reg_8b_8b.addr = ADV7513_REG_STATUS;
  tmp_reg_read();
  return ((tmp_reg_8b_8b.data & 0x40) == 0x40);
}

bool_t adv_monitor_sense_state(void) {
  tmp_reg_8b_8b.addr = ADV7513_REG_STATUS;
  tmp_reg_read();
  return ((tmp_reg_8b_8b.data & 0x20) == 0x20);
}


void set_color_format(color_format_t color_format) {

  tmp_reg_8b_8b.addr = ADV7513_REG_VIDEO_INPUT_CFG1;
  tmp_reg_8b_8b.data = color_format > RGB_limited;
  tmp_reg_write();

  /*
  // following code uses CSC of ADV7513, we want to implement the color conversion by our own on FPGA
  tmp_reg_8b_8b.addr = ADV7513_REG_CSC_UPDATE;
  adv7513_reg_bitset(&tmp_reg_8b_8b.addr,ADV7513_CSC_UPDATE_BIT);
  for (int idx = 0; idx < CSC_COEFFICIENTS; idx++) {
    tmp_reg_16b_16b.addr[0] = ADV7513_REG_CSC_UPPER(idx);
    tmp_reg_16b_16b.addr[1] = ADV7513_REG_CSC_LOWER(idx);
    tmp_reg_16b_16b.data[0] = csc_reg_vals[color_format][2*idx    ];
    tmp_reg_16b_16b.data[1] = csc_reg_vals[color_format][2*idx + 1];
    adv7513_writereg(&tmp_reg_16b_16b.addr[0],&tmp_reg_16b_16b.data[0]);
    adv7513_writereg(&tmp_reg_16b_16b.addr[1],&tmp_reg_16b_16b.data[1]);
  }
  adv7513_reg_bitclear(&tmp_reg_8b_8b.addr,ADV7513_CSC_UPDATE_BIT);
  */
}

void set_pr_manual(pr_mode_t pr_mode, alt_u8 pr_set, alt_u8 pr_send2tx) {

  alt_u8 regval = 0x80;
  if (pr_mode == PR_MANUAL) regval |= (0b11 << 5);

  if (pr_set == 4) regval |= 0b10 << 3;
  if (pr_set == 2) regval |= 0b01 << 3;

  if (pr_send2tx == 4) regval |= 0b10 << 1;
  if (pr_send2tx == 2) regval |= 0b01 << 1;

  tmp_reg_8b_8b.addr = ADV7513_REG_PIXEL_REPETITION;
  tmp_reg_8b_8b.data = regval;
  tmp_reg_write();
}

inline void set_vclk_div(alt_u8 divider) {
  tmp_reg_8b_8b.addr = ADV7513_REG_INPUT_CLK_DIV;
  tmp_reg_16b_16b.addr[0] = ADV7513_REG_INT1(2);

  switch (divider) {
    case 2:
      tmp_reg_8b_8b.data = 0x65;
      tmp_reg_write();
      adv7513_reg_bitset(&tmp_reg_16b_16b.addr[0], 6);
      break;
    case 4:
      tmp_reg_8b_8b.data = 0x67;
      tmp_reg_write();
      adv7513_reg_bitset(&tmp_reg_16b_16b.addr[0], 6);
      break;
    default:
      tmp_reg_8b_8b.data = 0x61;
      tmp_reg_write();
      adv7513_reg_bitclear(&tmp_reg_16b_16b.addr[0], 6);
  }
}

void set_cfg_adv7513(bool_t use_rgb) {
  color_format_t color_format = use_rgb ? RGB_full : YCbCr_601_full;
  bool_t use_limited_colorspace = color_format & 0x01;

  db_printf("set_cfg_adv7513(): setup adv7513 with following settings:\n");
  db_printf("  - color format: %d\n",color_format);
  db_printf("  - limited color space: %d\n",use_limited_colorspace);

  tmp_reg_8b_8b.addr = ADV7513_REG_INFOFRAME_UPDATE;
  tmp_reg_8b_8b.data = 0xE0;  // [7] Auto Checksum Enable: 1 = Use automatically generated checksum
                              // [6] AVI Packet Update: 1 = AVI Packet I2C update active
                              // [5] Audio InfoFrame Packet Update: 1 = Audio InfoFrame Packet I2C update active
  tmp_reg_write();

  set_pr_manual(PR_MANUAL,1,1);

  tmp_reg_8b_8b.addr = ADV7513_REG_VIC_MANUAL;
  tmp_reg_8b_8b.data = 0x00;
  tmp_reg_write();

  set_color_format((color_format << 1) | use_limited_colorspace);
  tmp_reg_8b_8b.addr = ADV7513_REG_AVI_INFOFRAME(0);
  tmp_reg_8b_8b.data = ((color_format > 0) << 6 ) | 0x01; // [6:5] Output format: 00 = RGB, 01 = YCbCr 4:2:2, 10 = YCbCr 4:4:4
                                                          // [1:0] Scan Information: 01 = TV, 10 = PC
  tmp_reg_write();

//  if videoresolution is 16:9
  tmp_reg_16b_16b.addr[0] = ADV7513_REG_VIDEO_INPUT_CFG2;
  adv7513_reg_bitset(&tmp_reg_16b_16b.addr[0],1);   // set 16:9 aspect ratio of input video
  tmp_reg_8b_8b.addr = ADV7513_REG_AVI_INFOFRAME(1);
  if (color_format < YCbCr_601_full) tmp_reg_8b_8b.data = 0x2A;
  else if (color_format < YCbCr_709_full) tmp_reg_8b_8b.data = (0x01 << 6) | 0x2A;
  else tmp_reg_8b_8b.data = (0x2 << 6) | 0x2A;
  // tmp_reg_8b_8b.data : [7:6] Colorimetry: 00 = no data, 01 = ITU601, 10 = ITU709
  //                      [5:4] Picture Aspect Ratio: 10 = 16:9
  //                      [3:0] Active Format Aspect Ratio: 1010 = 16:9 (center)
  tmp_reg_write();

//  if videoresolution is 4:3
//  tmp_reg_16b_16b.addr[0] = ADV7513_REG_VIDEO_INPUT_CFG2;
//  adv7513_reg_bitclear(&tmp_reg_16b_16b.addr[0]);   // set 4:3 aspect ratio of input video
//  tmp_reg_8b_8b.addr = ADV7513_REG_AVI_INFOFRAME(1);
//  tmp_reg_8b_8b.data = (color_format << 6) | 0x19;  // [7:6] Colorimetry: 00 = no data, 01 = ITU601, 10 = ITU709
//                                                    // [5:4] Picture Aspect Ratio: 01 = 4:3
//                                                    // [3:0] Active Format Aspect Ratio: 1001 = 4:3 (center)
//  tmp_reg_write();


  tmp_reg_8b_8b.addr = ADV7513_REG_AVI_INFOFRAME(2);
//  if (use_limited_colorspace) tmp_reg_8b_8b.data = 0x04;  // [3:2] Quantization range: 01 = limited range
//  else                        tmp_reg_8b_8b.data = 0x08;  // [3:2] Quantization range: 10 = full range
  tmp_reg_8b_8b.data = (0x08 >> use_limited_colorspace);
  tmp_reg_write();

  tmp_reg_8b_8b.addr = ADV7513_REG_INFOFRAME_UPDATE;
  tmp_reg_8b_8b.data = 0x80;  // [7] Auto Checksum Enable: 1 = Use automatically generated checksum
                              // [6] AVI Packet Update: 0 = AVI Packet I2C update inactive
                              // [5] Audio InfoFrame Packet Update: 0 = Audio InfoFrame Packet I2C update inactive
  tmp_reg_write();

  db_printf("set_cfg_adv7513(): done!\n");
}

int check_adv7513()
{
  tmp_reg_8b_8b.addr = ADV7513_REG_CHIP_REVISION;
  db_printf("check_adv7513(): Checking for ADV7513 chip... ");
  adv7513_readreg(&tmp_reg_8b_8b.addr,&tmp_reg_8b_8b.data);
  if (tmp_reg_8b_8b.data != ADV7513_CHIP_ID) {
    db_printf("failed; exit with code -%d\n",ADV_INIT_FAILED);
    return -ADV_INIT_FAILED;
  }
  db_printf("success!\n");
  return 0;
}

bool_t init_adv7513(bool_t use_rgb) {
  // ToDo: show hw that we are about to initialize the adv7513 chip
  db_printf("init_adv7513(): start init process... ");
  if (!adv_power_rdy()) {
    db_printf("aborted (adv not ready).\n");
    return FALSE;
  }

  for (int idx=0; idx<ADV7513_INIT_LENGTH; idx++)
    adv7513_writereg(&adv7513_init[idx].addr,&adv7513_init[idx].data);

  db_printf("almost done. Continue with set_cfg_adv7513() for mode specific functions.\n");
  set_cfg_adv7513(use_rgb);

  db_printf("init_adv7513(): Leaving with success.");
  return TRUE;
}
