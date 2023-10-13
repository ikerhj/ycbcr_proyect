/*********************************************************************************
 *
 * mipi_bridge_regs_p.h
 *
 *  Created on: 15.02.2023
 *      Author: Peter Bartmann, Xie Changfeng
 *
 ********************************************************************************/

#include "app_cfg.h"
#include "mipi_bridge.h"
#include "i2c.h"


#ifndef MIPI_BRIDGE_REGS_P_
#define MIPI_BRIDGE_REGS_P_


#define MIPIBR_CHIP_REV_ID_REG      0x0000
  #define MIPIBR_CHIP_REV_ID_REG_H    0x00
  #define MIPIBR_CHIP_REV_ID_REG_L    0x00
  #define MIPIBR_CHIP_ID_VALUE        0x44
  #define MIPIBR_REV_ID_VALUE         0x01

#define MIPIBR_SYSCTL_REG       0x0002
  #define MIPIBR_SYSCTL_REG_H     0x00
  #define MIPIBR_SYSCTL_REG_L     0x02
  #define MIPBR_SLEEP_BIT         1
  #define MIPIBR_SRESET_BIT       0

#define MIPIBR_PHYClkCtl_REG        0x0056
  #define MIPIBR_PHYClkCtl_REG_H      0x00
  #define MIPIBR_PHYClkCtl_REG_L      0x56
#define MIPIBR_PHYData0Ctl_REG      0x0058
  #define MIPIBR_PHYData0Ctl_REG_H    0x00
  #define MIPIBR_PHYData0Ctl_REG_L    0x58
#define MIPIBR_PHYData1Ctl_REG      0x005A
  #define MIPIBR_PHYData1Ctl_REG_H    0x00
  #define MIPIBR_PHYData1Ctl_REG_L    0x5A
#define MIPIBR_PHYData2Ctl_REG      0x005C
  #define MIPIBR_PHYData2Ctl_REG_H    0x00
  #define MIPIBR_PHYData2Ctl_REG_L    0x5C
#define MIPIBR_PHYData3Ctl_REG      0x005E
  #define MIPIBR_PHYData3Ctl_REG_H    0x00
  #define MIPIBR_PHYData3Ctl_REG_L    0x5E
#define MIPIBR_PHYTimDly_REG        0x0060
  #define MIPIBR_PHYTimDly_REG_H      0x00
  #define MIPIBR_PHYTimDly_REG_L      0x60
#define MIPIBR_PHYSta_REG           0x0062
  #define MIPIBR_PHYSta_REG_H         0x00
  #define MIPIBR_PHYSta_REG_L         0x62
#define MIPIBR_CSIStatus_REG        0x0064
  #define MIPIBR_CSIStatus_REG_H      0x00
  #define MIPIBR_CSIStatus_REG_L      0x64
#define MIPIBR_CSIErrEn_REG         0x0066
  #define MIPIBR_CSIErrEn_REG_H       0x00
  #define MIPIBR_CSIErrEn_REG_L       0x66
#define MIPIBR_MDLSynErr_REG        0x0068
  #define MIPIBR_MDLSynErr_REG_H      0x00
  #define MIPIBR_MDLSynErr_REG_L      0x68
#define MIPIBR_FrmErrCnt_REG        0x0080
  #define MIPIBR_FrmErrCnt_REG_H      0x00
  #define MIPIBR_FrmErrCnt_REG_L      0x80
#define MIPIBR_MDLErrCnt_REG        0x0090
  #define MIPIBR_MDLErrCnt_REG_H      0x00
  #define MIPIBR_MDLErrCnt_REG_L      0x90


#define FIFO_LEVEL      16 // try others? [0~511]
  #define FIFO_LEVEL_H    ((FIFO_LEVEL>>8) & 0xFF)
  #define FIFO_LEVEL_L    (FIFO_LEVEL & 0xFF)
#define DATA_FORMAT     0x0011
  #define DATA_FORMAT_H   ((DATA_FORMAT>>8) & 0xFF)
  #define DATA_FORMAT_L   (DATA_FORMAT & 0xFF)

// REFCLK    20 MHz
// PPIrxCLK  100 MHz
// PCLK      50 MHz
// MCLK      25 MHz

#define PLL_PRD     1  // 0- 15
#define PLL_FBD     39 //0-511
#define PLL_FRS     1 //0-3

#define MCLK_HL     1 // (MCLK_HL+1)+ (MCLK_HL+1)


//2b'00: div 8, 2b'01: div 4, 2b'10: div 2
#define PPICLKDIV   2  // ppi_clk:must between 66~125MHz
#define MCLKREFDIV  2   // mclkref clock:  < 125MHz
#define SCLKDIV     1   // sys_clk clock:  < 100MHz

#define WORDCOUNT       800
  #define WORDCOUNT_H     ((WORDCOUNT>>8) & 0xFF)
  #define WORDCOUNT_L     (WORDCOUNT & 0xFF)


#define LENGTH_INIT_SEQUENCE_MIBR   13

const i2c_reg_16b_16b_t MipiBridgeReg[LENGTH_INIT_SEQUENCE_MIBR] = {
  {{0x00,0x02},{0x00,0x01}},                                      // System Control Register, set sleep
  {{0xFF,0xFF},{0,10}},                                           // delay
  {{0x00,0x02},{0x00,0x00}},                                      // System Control Register, set wake up
  {{0x00,0x16},{(PLL_PRD << 4),PLL_FBD}},                         // PLL Control Register 0
  {{0x00,0x18},{((PLL_FRS<<2)|0x2),((0x1<<1)|0x1)}},              // PLL Control Register 1
  {{0xFF,0xFF},{0,10}},                                           // delay
  {{0x00,0x18},{((PLL_FRS<<2)|0x3),((0x1<<4)|(0x1<<1)|0x1)}},     // PLL Control Register 1
  {{0x00,0x20},{0x00,((PPICLKDIV<<4)|(MCLKREFDIV<<2)|SCLKDIV)}},  // Clock Control Register 0
  {{0x00,0x0C},{MCLK_HL,MCLK_HL}},                                // MCLK Control Register
  {{0x00,0x60},{0x80,0x06}},
  {{0x00,0x06},{FIFO_LEVEL_H,FIFO_LEVEL_L}},                      // FiFo Control Register   [0~511]
                                                                  // when reaches to this level FiFo controller asserts FiFoRdy for Parallel port to start output data
  {{0x00,0x08},{DATA_FORMAT_H,DATA_FORMAT_L}},                    // Data FormatControl Register
//  {{0x00,0x22},{WORDCOUNT_H,WORDCOUNT_L}},                        // Word Count Register
  {{0x00,0x04},{0x80,0x47}} // Configuration Control Register
};


#endif /* MIPI_BRIDGE_REGS_P_ */
