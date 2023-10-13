/*********************************************************************************
 *
 * ov8865.c
 *
 *  Created on: 10.11.2022
 *      Author: Peter Bartmann
 *
 ********************************************************************************/

#include "app_cfg.h"
#include "ov8865.h"
#include "ov8865_regs_p.h"

#include "unistd.h"
#include "stdio.h"
#include "alt_types.h"
#include "common_types.h"
#include "i2c.h"
#include "system.h"
#include "altera_avalon_pio_regs.h"


#define ov8865_readreg_n(regaddr_p,retvals_p,n) i2c_readregs(OV8865_I2C_BASE,regaddr_p,1,retvals_p,n)
#define ov8865_writereg_n(regaddr_p,data_p,n)   i2c_writeregs(OV8865_I2C_BASE,regaddr_p,1,data_p,n)

#define ov8865_readreg(regaddr_p,retvals_p)     ov8865_readreg_n(regaddr_p,retvals_p,1)
#define ov8865_writereg(regaddr_p,data_p)       ov8865_writereg_n(regaddr_p,data_p,1)

#define tmp_reg_read()                          i2c_readregs(OV8865_I2C_BASE,&tmp_reg_16b_8b.addr[0],1,&tmp_reg_16b_8b.data,1)
#define tmp_reg_write()                         i2c_writeregs(OV8865_I2C_BASE,&tmp_reg_16b_8b.addr[0],1,&tmp_reg_16b_8b.data,1)



void set_hwrst_ov8865()
{
  db_printf("set_hwrst_ov8865():");
  IOWR_ALTERA_AVALON_PIO_DATA(CAMERA_PWDN_N_BASE,0x00);
  db_printf(" ok\n");
}

void release_hwrst_ov8865()
{
  db_printf("release_hwrst_ov8865():");
  IOWR_ALTERA_AVALON_PIO_DATA(CAMERA_PWDN_N_BASE,0x01);
  db_printf(" ok\n");
}

int check_ov8865()
{
  tmp_reg_16b_8b.addr[0] = OV8865_CHIP_ID_REG_H;
  tmp_reg_16b_8b.addr[1] = OV8865_CHIP_ID_REG_L(0);
  const alt_u8 idvals[3] = {OV8865_CHIP_ID_HH_VALUE,
                            OV8865_CHIP_ID_H_VALUE ,
                            OV8865_CHIP_ID_L_VALUE  };
  alt_u8 retvals[3];
  bool_t success = TRUE;

  int idx;

  db_printf("check_ov8865(): reading I2C address from OV8865... \n");
  ov8865_readreg_n(&tmp_reg_16b_8b.addr[0],&retvals[0],3);
  for (idx=0; idx<3; idx++) {
    if (idvals[idx] == retvals[idx]){
      db_printf(" ... reg no. 0x%04x ok\n",OV8865_CHIP_ID_REG(idx));
    } else {
      db_printf(" ... reg no. 0x%04x not ok (expected 0x%02x, got 0x%02x)\n",OV8865_CHIP_ID_REG(idx),idvals[idx],retvals[idx]);
      success = FALSE;
    }
  }

  tmp_reg_16b_8b.addr[0] = 0x38;
  tmp_reg_16b_8b.addr[1] = 0x09;
  for(idx=0; idx<10; idx++){
    tmp_reg_16b_8b.data = idx;
    tmp_reg_write();
    usleep(5);
    tmp_reg_16b_8b.data = 0xaa;
    tmp_reg_read();
    db_printf(" - test on reg. 0x3809: wrote %d, read %d\n",idx,tmp_reg_16b_8b.data);
    if (idx != tmp_reg_16b_8b.data) success = FALSE;
    usleep(5);
  }

  if (success) {
    db_printf(" ... success!\n");
    return 0;
  } else {
    db_printf(" ... id check failed!\n");
    return -OV8865_CHECK_FAILED;
  }
}

int init_ov8865(bool_t verify)
{
  int idx,jdx,kdx;

  bool_t success = TRUE;

  db_printf("init_ov8865(): start init seqeunce of OV8865... \n");

  jdx = 0;
  for(idx = 0; idx<LENGTH_INIT_SEQUENCE_OV8865; idx++)
  {
    if(init_reg_seq_ov8865[idx].start_addr[0] == 0xff &&
       init_reg_seq_ov8865[idx].start_addr[1] == 0xff ) {
      usleep(init_reg_vals_ov8865[jdx]*100);
      jdx++;
   } else {
      ov8865_writereg_n(&init_reg_seq_ov8865[idx].start_addr[0],&init_reg_vals_ov8865[jdx],init_reg_seq_ov8865[idx].consec_length);
      if (verify) {
        for (kdx = 0; kdx < init_reg_seq_ov8865[idx].consec_length; kdx++) {
          tmp_reg_16b_8b.addr[0] = init_reg_seq_ov8865[idx].start_addr[0];
          tmp_reg_16b_8b.addr[1] = init_reg_seq_ov8865[idx].start_addr[1] + kdx;
          if (tmp_reg_16b_8b.addr[0] == 0x01 && tmp_reg_16b_8b.addr[1] == 0x03) tmp_reg_16b_8b.data = init_reg_vals_ov8865[jdx];  // hack for software reset register
          else tmp_reg_read();
          db_printf("  - verification reg 0x%02x%02x (expected: 0x%02x, read: 0x%02x)",
                    tmp_reg_16b_8b.addr[0],tmp_reg_16b_8b.addr[1],init_reg_vals_ov8865[jdx],tmp_reg_16b_8b.data);
          if (init_reg_vals_ov8865[jdx] != tmp_reg_16b_8b.data) {
            db_printf(" ... failed!\n");
//            db_printf("  - verification failed at reg 0x%02x%02x (expected: 0x%02x, read: 0x%02x)\n",
//                      tmp_reg_16b_8b.addr[0],tmp_reg_16b_8b.addr[1],init_reg_vals_ov8865[jdx],tmp_reg_16b_8b.data);
            success = FALSE;
          } else {
            db_printf(" ... ok!\n");
          }
          jdx++;
        }
      } else {
        jdx += init_reg_seq_ov8865[idx].consec_length;
      }
    }
  }
  db_printf("init_ov8865(): %d registers written\n",jdx);
  if(success) {
    db_printf("  - ended with success!\n");
    return 0;
  } else {
    db_printf("  - verification failed!\n");
    return -OV8865_INIT_FAILED;
  }
}
