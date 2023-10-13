/*********************************************************************************
 *
 * i2c.h
 *
 *  Created on: 12.03.2021
 *      Author: Peter Bartmann
 *
 ********************************************************************************/

#ifndef I2C_H_
#define I2C_H_


#include "system.h"
#include "alt_types.h"
#include "common_types.h"

#define ADV7513_I2C_BASE    (0x72>>1)
#define SI5338_I2C_BASE	    (0xE0>>1)
#define OV8865_I2C_BASE     (0x6C>>1)
#define MIPIBR_I2C_BASE     (0x1C>>1)


typedef struct i2c_reg_16b_16b_t {
  alt_u8 addr[2];
  alt_u8 data[2];
} i2c_reg_16b_16b_t;

typedef struct i2c_reg_16b_8b_t {
  alt_u8 addr[2];
  alt_u8 data;
} i2c_reg_16b_8b_t;

typedef struct i2c_reg_8b_8b_t {
  alt_u8 addr;
  alt_u8 data;
} i2c_reg_8b_8b_t;


typedef struct consec_regs_t {
  alt_u8 start_addr[2];
  alt_u8 consec_length;
} consec_regs_t;

typedef struct consec_regs8b_t {
  alt_u8 start_addr;
  alt_u8 consec_length;
} consec_regs8b_t;

typedef enum {
  ONBOARD_DEVICES = 0,
  GPIO_CAMERA,
  GPIO_MIPI
} i2c_devices_t;

extern i2c_reg_16b_16b_t tmp_reg_16b_16b;
extern i2c_reg_16b_8b_t  tmp_reg_16b_8b;
extern i2c_reg_8b_8b_t   tmp_reg_8b_8b;

void set_i2c_device(i2c_devices_t i2c_device);

void i2c_reg_bitset(alt_u8 i2c_dev, alt_u8 *regaddr, bool_t long_addr, alt_u8 bit, bool_t dbl_byte);
void i2c_reg_bitclear(alt_u8 i2c_dev, alt_u8 *regaddr, bool_t long_addr, alt_u8 bit, bool_t dbl_byte);
void i2c_readregs(alt_u8 i2c_dev, const alt_u8 *regaddr, bool_t long_addr, alt_u8 *retvals, alt_u8 rd_length);
void i2c_writeregs(alt_u8 i2c_dev, const alt_u8 *regaddr, bool_t long_addr, const alt_u8 *wrvals, alt_u8 wr_length);
void i2c_writeregs_withmask(alt_u8 i2c_dev, const alt_u8 *regaddr, bool_t long_addr, const alt_u8 *wrvals, const alt_u8 *wrmasks, alt_u8 wr_length);

#endif /* I2C_H_ */
