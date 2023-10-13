/*********************************************************************************
 *
 * mipi_bridge.h
 *
 *  Created on: 11.11.2022
 *      Author: Peter Bartmann
 *
 ********************************************************************************/

#ifndef MIPI_BRIDGE_H_
#define MIPI_BRIDGE_H_


#include "system.h"
#include "alt_types.h"
#include "common_types.h"


#define MIPI_BRIDGE_CHECK_FAILED  170 // ToDo: move codes into separate header file?
#define MIPI_BRIDGE_INIT_FAILED   171


void set_hwrst_mipibr(void);
void release_hwrst_mipibr(void);

//void set_swrst_mipibr(void);
//void release_swrst_mipibr(void);
//void mipibr_sleep(void);
//void mipibr_wakeup(void);

void mipi_clear_error(void);
void mipi_show_error_info(bool_t more_info);

int check_mipi_bridge(void);
int init_mipi_bridge(void);


#endif /* MIPI_BRIDGE_H_ */
