/*********************************************************************************
 *
 * si5338.c
 *
 *  Created on: 12.03.2021
 *      Author: Peter Bartmann
 *
 * File created with the help of ClockBuilder Pro v2.29 [2018-11-04]
 *
 ********************************************************************************/

#include "app_cfg.h"
#include "si5338.h"

#include "unistd.h"
#include "stdio.h"
#include "alt_types.h"
#include "common_types.h"
#include "i2c.h"
#include "system.h"
#include "altera_avalon_pio_regs.h"

#include "si5338_regs_p.h"


#define PLL_LOCK_MAXWAIT_US         1000
#define PLL_LOCK_2_FPGA_TIMEOUT_MS  5


#define si5338_readreg_n(regaddr_p,retvals_p,n)               i2c_readregs(SI5338_I2C_BASE,regaddr_p,0,retvals_p,n)
#define si5338_writereg_n(regaddr_p,data_p,n)                 i2c_writeregs(SI5338_I2C_BASE,regaddr_p,0,data_p,n)
#define si5338_writereg_n_withmask(regaddr_p,data_p,mask_p,n) i2c_writeregs_withmask(SI5338_I2C_BASE,regaddr_p,0,data_p,mask_p,n)

#define si5338_readreg(regaddr_p,retvals_p)                   si5338_readreg_n(regaddr_p,retvals_p,1)
#define si5338_writereg(regaddr_p,data_p)                     si5338_writereg_n(regaddr_p,data_p,1)
#define si5338_writereg_withmask(regaddr_p,data_p,mask_p)     si5338_writereg_n_withmask(regaddr_p,data_p,mask_p,1)

#define tmp_reg_read()                                        i2c_readregs(SI5338_I2C_BASE,&tmp_reg_8b_8b.addr,0,&tmp_reg_8b_8b.data,1)
#define tmp_reg_write()                                       i2c_writeregs(SI5338_I2C_BASE,&tmp_reg_8b_8b.addr,0,&tmp_reg_8b_8b.data,1)



bool_t si5338_pll_lockstatus(void) {
  tmp_reg_8b_8b.addr = PLL_LOSSLOCK_REG;
  tmp_reg_read();
  return ((tmp_reg_8b_8b.data & (1<<PLL_LOSSLOCK_BIT)) == 0x00);
}


int check_si5338()
{
  tmp_reg_8b_8b.addr = SI5338_ID_REG;

  db_printf("check_si5338(): reading I2C address from SI5338... ");
  tmp_reg_read();

  if ( tmp_reg_8b_8b.data == 0xff) {
    db_printf("reading 0xff; probably no response. Exit with code -%d\n",SI5338_INIT_FAILED_0);
    return -SI5338_INIT_FAILED_0;
  }

  tmp_reg_8b_8b.data &= 0x07;
  if (tmp_reg_8b_8b.data > 1) {
    db_printf("reading not as expected (read 0x%02x). Exit with code -%d\n",tmp_reg_8b_8b.data,SI5338_INIT_FAILED_1);
    return -SI5338_INIT_FAILED_1;
  }
  db_printf("reading revision id 0x%02x; success!\n",tmp_reg_8b_8b.data);
  return 0;
}

bool_t configure_clk_si5338(clk_config_t target_cfg, bool_t verify) {
  // ToDo: show hardware that we are reconfiguring the PLL (must initiate reset of video pipeline and hold until done)
  bool_t retval = TRUE;
  
  db_printf("configure_clk_si5338(): set new configuration (cfg no.: %d)... \n",target_cfg);
  int idx,jdx,kdx;
  
  // disable outputs
  tmp_reg_8b_8b.addr = OEB_REG;
  tmp_reg_8b_8b.data = OEB_REG_VAL_OFF;
  tmp_reg_write();

  jdx=0;
  for (idx=0; idx<LENGTH_CONFIG_SEQUENCE_SI5338; idx++) {
    si5338_writereg_n(&config_reg_sequence[idx].start_addr,&config_regs[target_cfg].reg_val[jdx],config_reg_sequence[idx].consec_length);
    jdx += config_reg_sequence[idx].consec_length;
  }

  // soft reset
  tmp_reg_8b_8b.addr = SOFT_RST_REG;
  tmp_reg_8b_8b.data = (1<<SOFT_RST_BIT);
  tmp_reg_write();
  // enable outputs
  tmp_reg_8b_8b.addr = OEB_REG;
  tmp_reg_8b_8b.data = OEB_REG_VAL_CLK2_ON;
  tmp_reg_write();
  
  idx = PLL_LOCK_MAXWAIT_US;
  while (!si5338_pll_lockstatus()) {  // wait for PLL lock
    if (idx == 0) {
      db_printf(" - PLL does not lock. Exit with no success!\n");
      return FALSE;
    }
    usleep(1);
    idx--;
  };
  usleep(1000*PLL_LOCK_2_FPGA_TIMEOUT_MS);

  if (verify == TRUE) {
    db_printf(" - Verification:\n");
    kdx=0;
    for (idx=0; idx<LENGTH_CONFIG_SEQUENCE_SI5338; idx++) {
      for (jdx=0; jdx<config_reg_sequence[idx].consec_length; jdx++) {
        tmp_reg_8b_8b.addr = config_reg_sequence[idx].start_addr + jdx;
        tmp_reg_read();
        if (tmp_reg_8b_8b.data != config_regs[target_cfg].reg_val[kdx]) {
          db_printf("   o error at reg 0x%02x: read 0x%02x, expected 0x%02x. Will exit with fail.\n",
                    tmp_reg_8b_8b.addr,tmp_reg_8b_8b.data,config_regs[target_cfg].reg_val[kdx]);
          retval = FALSE;
        }
        kdx++;
      }
    }
    if (retval == TRUE) db_printf("   o success.\n");
    else db_printf("   o failed!\n");
  }

  if (retval == TRUE) db_printf(" - Done!\n");
  else db_printf(" - Failed!\n");
  return retval;
}

bool_t init_si5338(clk_config_t target_cfg) {
  // ToDo: show hardware that we are configuring the PLL (hw must hold reset of video pipeline until done)
  db_printf("init_si5338(): starting initialization and go over to configure PLL.\n");
  int idx,jdx;

  // disable outputs
  tmp_reg_8b_8b.addr = OEB_REG;
  tmp_reg_8b_8b.data = OEB_REG_VAL_OFF;
  tmp_reg_write();
  // write needed for proper operation
  tmp_reg_8b_8b.addr = DIS_LOL_REG;
  tmp_reg_8b_8b.data = DIS_LOL_REG_VAL;
  tmp_reg_write();

  jdx = 0;
  for (idx=0; idx<LENGTH_INIT_SEQUENCE_SI5338; idx++) {
    si5338_writereg_n_withmask(&init_reg_sequence[idx].start_addr,&init_regs.reg_val[jdx],&init_regs.reg_mask[jdx],init_reg_sequence[idx].consec_length);
    jdx += init_reg_sequence[idx].consec_length;
  }

  return configure_clk_si5338(target_cfg,1);
}

