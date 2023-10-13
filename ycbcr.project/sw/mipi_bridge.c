/*********************************************************************************
 *
 * mipi_bridge.c
 *
 *  Created on: 11.11.2022
 *      Author: Peter Bartmann
 *
 ********************************************************************************/

#include "app_cfg.h"
#include "mipi_bridge.h"
#include "mipi_bridge_regs_p.h"

#include "unistd.h"
#include "stdio.h"
#include "alt_types.h"
#include "common_types.h"
#include "i2c.h"
#include "system.h"
#include "altera_avalon_pio_regs.h"


#define mipibr_readreg_n(regaddr_p,retvals_p,n) i2c_readregs(MIPIBR_I2C_BASE,regaddr_p,1,retvals_p, 2*n)
#define mipibr_writereg_n(regaddr_p,data_p,n)   i2c_writeregs(MIPIBR_I2C_BASE,regaddr_p,1,data_p,2*n)

#define mipibr_readreg(regaddr_p,retvals_p)     mipibr_readreg_n(regaddr_p,retvals_p,1)
#define mipibr_writereg(regaddr_p,data_p)       mipibr_writereg_n(regaddr_p,data_p,1)

#define tmp_reg_read()                          i2c_readregs(MIPIBR_I2C_BASE,&tmp_reg_16b_16b.addr[0],1,&tmp_reg_16b_16b.data[0],2)
#define tmp_reg_write()                         i2c_writeregs(MIPIBR_I2C_BASE,&tmp_reg_16b_16b.addr[0],1,&tmp_reg_16b_16b.data[0],2)




void set_hwrst_mipibr()
{
  db_printf("set_hwrst_mipibr():");
  IOWR_ALTERA_AVALON_PIO_DATA(MIPI_RESET_N_BASE,0x00);
  db_printf(" ok\n");
}

void release_hwrst_mipibr()
{
  db_printf("release_hwrst_mipibr():");
  IOWR_ALTERA_AVALON_PIO_DATA(MIPI_RESET_N_BASE,0x01);
  db_printf(" ok\n");
}

//void set_swrst_mipibr()
//{
//  db_printf("set_swrst_mipibr():");
//  mipibr_reg_bitset(MIPIBR_SYSCTL_REG,MIPIBR_SRESET_BIT,0x0002);
//  db_printf(" ok\n");
//}
//
//void release_swrst_mipibr()
//{
//  db_printf("release_swrst_mipibr():");
//  mipibr_reg_bitclear(MIPIBR_SYSCTL_REG,MIPIBR_SRESET_BIT,0x0002);
//  db_printf(" ok\n");
//}
//
//void mipibr_sleep()
//{
//  db_printf("mipibr_sleep():");
//  mipibr_reg_bitset(MIPIBR_SYSCTL_REG,MIPBR_SLEEP_BIT,0x0002);
//  db_printf(" ok\n");
//}
//
//void mipibr_wakeup()
//{
//  db_printf(" mipibr_wakeup():");
//  mipibr_reg_bitclear(MIPIBR_SYSCTL_REG,MIPBR_SLEEP_BIT,0x0002);
//  db_printf(" ok\n");
//}

void mipi_clear_error(void){
  db_printf("mipi_clear_error(): cleanup ... ");

  tmp_reg_16b_16b.addr[0] = MIPIBR_CSIStatus_REG_H;
  tmp_reg_16b_16b.addr[1] = MIPIBR_CSIStatus_REG_L;
  tmp_reg_16b_16b.data[0] = 0x01;
  tmp_reg_16b_16b.data[0] = 0xFF;
  tmp_reg_write();  // clear error

//  tmp_reg_16b_16b.addr[0] = MIPIBR_MDLSynErr_REG_H;
  tmp_reg_16b_16b.addr[1] = MIPIBR_MDLSynErr_REG_L;
  tmp_reg_16b_16b.data[0] = 0x00;
  tmp_reg_16b_16b.data[0] = 0x00;
  tmp_reg_write();  // clear error

//  tmp_reg_16b_16b.addr[0] = MIPIBR_FrmErrCnt_REG_H;
  tmp_reg_16b_16b.addr[1] = MIPIBR_FrmErrCnt_REG_L;
  tmp_reg_write();  // clear error

//  tmp_reg_16b_16b.addr[0] = MIPIBR_MDLErrCnt_REG_H;
  tmp_reg_16b_16b.addr[1] = MIPIBR_MDLErrCnt_REG_L;
  tmp_reg_write();  // clear error


//  tmp_reg_16b_16b.addr[0] = 0x00;
  for (alt_u8 idx = 0x82; idx < 0x91; idx = idx + 2) {
    tmp_reg_16b_16b.addr[1] = idx;
    tmp_reg_write();
  }

  db_printf("done!\n");
}

void mipi_show_error_info(bool_t more_info){

  db_printf("mipi_show_error_info(): ");

  tmp_reg_16b_16b.addr[0] = MIPIBR_PHYSta_REG_H;
  tmp_reg_16b_16b.addr[1] = MIPIBR_PHYSta_REG_L;
  tmp_reg_read();
  db_printf("PHY_status=0x%02x%02x, ",tmp_reg_16b_16b.data[0],tmp_reg_16b_16b.data[1]);

  tmp_reg_16b_16b.addr[0] = MIPIBR_CSIStatus_REG_H;
  tmp_reg_16b_16b.addr[1] = MIPIBR_CSIStatus_REG_L;
  tmp_reg_read();
  db_printf("CSI_status=0x%02x%02x, ",tmp_reg_16b_16b.data[0],tmp_reg_16b_16b.data[1]);

  tmp_reg_16b_16b.addr[0] = MIPIBR_MDLSynErr_REG_H;
  tmp_reg_16b_16b.addr[1] = MIPIBR_MDLSynErr_REG_L;
  tmp_reg_read();
  db_printf("MDLSynErr=0x%02x%02x, ",tmp_reg_16b_16b.data[0],tmp_reg_16b_16b.data[1]);

  tmp_reg_16b_16b.addr[0] = MIPIBR_FrmErrCnt_REG_H;
  tmp_reg_16b_16b.addr[1] = MIPIBR_FrmErrCnt_REG_L;
  tmp_reg_read();
  db_printf("FrmErrCnt=0x%02x%02x, ",tmp_reg_16b_16b.data[0],tmp_reg_16b_16b.data[1]);

  tmp_reg_16b_16b.addr[0] = MIPIBR_MDLErrCnt_REG_H;
  tmp_reg_16b_16b.addr[1] = MIPIBR_MDLErrCnt_REG_L;
  tmp_reg_read();
  db_printf("MDLErrCnt=0x%02x%02x.\n",tmp_reg_16b_16b.data[0],tmp_reg_16b_16b.data[1]);

  if (more_info) {
    db_printf("mipi_show_error_info(): printing more info is requested - so here you go!\n");

    tmp_reg_16b_16b.addr[0] = 0x00;
    tmp_reg_16b_16b.addr[1] = 0x80;
    tmp_reg_read();
    db_printf("  - FrmErrCnt: 0x%02x%02x\n",tmp_reg_16b_16b.data[0],tmp_reg_16b_16b.data[1]);

//    tmp_reg_16b_16b.addr[0] = 0x00;
    tmp_reg_16b_16b.addr[1] = 0x82;
    tmp_reg_read();
    db_printf("  - CRCErrCnt: 0x%02x%02x\n",tmp_reg_16b_16b.data[0],tmp_reg_16b_16b.data[1]);

//    tmp_reg_16b_16b.addr[0] = 0x00;
    tmp_reg_16b_16b.addr[1] = 0x84;
    tmp_reg_read();
    db_printf("  - CorErrCnt: 0x%02x%02x\n",tmp_reg_16b_16b.data[0],tmp_reg_16b_16b.data[1]);

//    tmp_reg_16b_16b.addr[0] = 0x00;
    tmp_reg_16b_16b.addr[1] = 0x86;
    tmp_reg_read();
    db_printf("  - HdrErrCnt: 0x%02x%02x\n",tmp_reg_16b_16b.data[0],tmp_reg_16b_16b.data[1]);

//    tmp_reg_16b_16b.addr[0] = 0x00;
    tmp_reg_16b_16b.addr[1] = 0x88;
    tmp_reg_read();
    db_printf("  - EIDErrCnt: 0x%02x%02x\n",tmp_reg_16b_16b.data[0],tmp_reg_16b_16b.data[1]);

//    tmp_reg_16b_16b.addr[0] = 0x00;
    tmp_reg_16b_16b.addr[1] = 0x8A;
    tmp_reg_read();
    db_printf("  - CtlErrCnt: 0x%02x%02x\n",tmp_reg_16b_16b.data[0],tmp_reg_16b_16b.data[1]);

//    tmp_reg_16b_16b.addr[0] = 0x00;
    tmp_reg_16b_16b.addr[1] = 0x8C;
    tmp_reg_read();
    db_printf("  - SoTErrCnt: 0x%02x%02x\n",tmp_reg_16b_16b.data[0],tmp_reg_16b_16b.data[1]);

//    tmp_reg_16b_16b.addr[0] = 0x00;
    tmp_reg_16b_16b.addr[1] = 0x8E;
    tmp_reg_read();
    db_printf("  - SynErrCnt: 0x%02x%02x\n",tmp_reg_16b_16b.data[0],tmp_reg_16b_16b.data[1]);

//    tmp_reg_16b_16b.addr[0] = 0x00;
    tmp_reg_16b_16b.addr[1] = 0x90;
    tmp_reg_read();
    db_printf("  - MDLErrCnt: 0x%02x%02x\n",tmp_reg_16b_16b.data[0],tmp_reg_16b_16b.data[1]);

//    tmp_reg_16b_16b.addr[0] = 0x00;
    tmp_reg_16b_16b.addr[1] = 0xF8;
    tmp_reg_read();
    db_printf("  - FIFOSTATUS: 0x%02x%02x\n",tmp_reg_16b_16b.data[0],tmp_reg_16b_16b.data[1]);

//    tmp_reg_16b_16b.addr[0] = 0x00;
    tmp_reg_16b_16b.addr[1] = 0x6A;
    tmp_reg_read();
    db_printf("  - DataType: 0x%02x%02x\n",tmp_reg_16b_16b.data[0],tmp_reg_16b_16b.data[1]);

//    tmp_reg_16b_16b.addr[0] = 0x00;
    tmp_reg_16b_16b.addr[1] = 0x6E;
    tmp_reg_read();
    db_printf("  - CSIPktLen: 0x%02x%02x\n",tmp_reg_16b_16b.data[0],tmp_reg_16b_16b.data[1]);
  }
}

int check_mipi_bridge()
{
  bool_t success = TRUE;

  db_printf("check_mipi_bridge(): reading I2C address from MIPI bridge... \n");
  tmp_reg_16b_16b.addr[0] = MIPIBR_CHIP_REV_ID_REG_H;
  tmp_reg_16b_16b.addr[1] = MIPIBR_CHIP_REV_ID_REG_L;
  tmp_reg_read();


  if (tmp_reg_16b_16b.data[0] == MIPIBR_CHIP_ID_VALUE) {
  db_printf(" ... Chip ID: ok\n");
  } else {
    db_printf(" ... Chip ID: not ok (expected 0x%02x, got 0x%02x)\n",MIPIBR_CHIP_ID_VALUE,tmp_reg_16b_16b.data[0]);
    success = FALSE;
  }

  if (tmp_reg_16b_16b.data[1] == MIPIBR_REV_ID_VALUE) {
  db_printf(" ... revision ID: ok\n");
  } else {
    db_printf(" ... revision ID: not ok (expected 0x%02x, got 0x%02x)\n",MIPIBR_REV_ID_VALUE,tmp_reg_16b_16b.data[1]);
    success = FALSE;
  }

  if (success) {
    db_printf(" ... success!\n");
    return 0;
  } else {
    db_printf(" ... id check failed. Exit with code -%d\n",MIPI_BRIDGE_CHECK_FAILED);
    return -MIPI_BRIDGE_CHECK_FAILED;
  }
}

int init_mipi_bridge()
{
  bool_t success = TRUE;
  db_printf("init_mipi_bridge(): apply config... \n");

  for(int idx=0;idx<LENGTH_INIT_SEQUENCE_MIBR; idx++){
    if (MipiBridgeReg[idx].addr[0] == 0xFF && MipiBridgeReg[idx].addr[1] == 0xFF ) {
      usleep(MipiBridgeReg[idx].data[1]*1000);
    } else {
      db_printf(" ... write 0x%02x%02x to reg 0x%02x%02x",MipiBridgeReg[idx].data[0],MipiBridgeReg[idx].data[1],MipiBridgeReg[idx].addr[0],MipiBridgeReg[idx].addr[1]);
      mipibr_writereg(&MipiBridgeReg[idx].addr[0], &MipiBridgeReg[idx].data[0]);
      mipibr_readreg(&MipiBridgeReg[idx].addr[0], &tmp_reg_16b_16b.data[0]);
      db_printf(" ... read 0x%02x%02x", tmp_reg_16b_16b.data[0], tmp_reg_16b_16b.data[1]);
      if (MipiBridgeReg[idx].data[0] == tmp_reg_16b_16b.data[0] ||
          MipiBridgeReg[idx].data[1] == tmp_reg_16b_16b.data[1]  ) {
        db_printf(" ... done.\n");
      } else {
        success = FALSE;
        db_printf(" ... error.\n");
      }
    }
  }

  if (success) {
    db_printf(" ... success!\n");
    return 0;
  } else {
    db_printf(" ... failed. Exit with code -%d\n",MIPI_BRIDGE_INIT_FAILED);
    return -MIPI_BRIDGE_INIT_FAILED;
  }
}
