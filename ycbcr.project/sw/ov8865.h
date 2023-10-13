/*********************************************************************************
 *
 * ov8865.h
 *
 *  Created on: 10.11.2022
 *      Author: Peter Bartmann
 *
 ********************************************************************************/

#ifndef OV8865_H_
#define OV8865_H_


#include "system.h"
#include "alt_types.h"
#include "common_types.h"


#define OV8865_CHECK_FAILED 160 // ToDo: move codes into separate header file?
#define OV8865_INIT_FAILED  161


void set_hwrst_ov8865(void);
void release_hwrst_ov8865(void);

int check_ov8865(void);
int init_ov8865(bool_t verify);


#endif /* OV8865_H_ */
