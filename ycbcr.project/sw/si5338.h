/*********************************************************************************
 *
 * si5338.h
 *
 *  Created on: 12.03.2021
 *      Author: Peter Bartmann
 *
 ********************************************************************************/

#ifndef SI5338_H_
#define SI5338_H_


#include "system.h"
#include "alt_types.h"
#include "common_types.h"
#include "i2c.h"

#define SI5338_INIT_FAILED_0 140 // ToDo: move codes into separate header file?
#define SI5338_INIT_FAILED_1 141


typedef enum {
  FREE_1080p_16t9 = 0,
  FREE_1200p_4t3,
  FREE_1440p_4t3,
  FREE_1440p_16t9
} clk_config_t;
#define NUM_SUPPORTED_CONFIGS_SI5338 (FREE_1440p_16t9+1)

bool_t si5338_pll_lockstatus(void);
int check_si5338(void);
bool_t init_si5338(clk_config_t target_cfg);
bool_t configure_clk_si5338(clk_config_t target_cfg, bool_t verify);


#endif /* SI5338_H_ */
