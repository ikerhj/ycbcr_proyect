/*********************************************************************************
 *
 * adv7513.h
 *
 *  Created on: 11.09.2018
 *      Author: Peter Bartmann
 *
 ********************************************************************************/

#include "system.h"
#include "alt_types.h"
#include "common_types.h"

#include "i2c.h"


#ifndef ADV7513_H_
#define ADV7513_H_

#define ADV7513_CHIP_ID     0x13
#define ADV7513_REG_STATUS  0x42

#define ADV_INIT_FAILED 150 // ToDo: move codes into separate header file?

typedef enum {
  RGB_full = 0,
  RGB_limited,
  YCbCr_601_full,
  YCbCr_601_limited,
  YCbCr_709_full,
  YCbCr_709_limited
} color_format_t;

#define MAX_COLOR_FORMATS  YCbCr_709_limited

typedef enum {
  PR_AUTO = 0,
  PR_MANUAL
} pr_mode_t;


bool_t adv_power_rdy(void);
bool_t adv_hpd_state(void);
bool_t adv_monitor_sense_state(void);

void set_cfg_adv7513(bool_t use_rgb);
int check_adv7513(void);
bool_t init_adv7513(bool_t use_rgb);


#endif /* ADV7513_H_ */
