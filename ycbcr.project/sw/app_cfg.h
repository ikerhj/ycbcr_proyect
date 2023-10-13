/*********************************************************************************
 *
 * app_cfg.h
 *
 *  Created on: 19.12.2021
 *      Author: Peter Bartmann
 *
 ********************************************************************************/

#ifndef APP_CFG_H_
#define APP_CFG_H_

#include <stdio.h>

#define SW_FW_MAIN  1
#define SW_FW_SUB   0

#ifndef DEBUG
  #define db_printf(...)
#else
  #define db_printf(...) printf(__VA_ARGS__)
#endif


#endif /* APP_CFG_H_ */
