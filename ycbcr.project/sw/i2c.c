/*********************************************************************************
 *
 * i2c.c
 *
 *  Created on: 02.12.2022
 *      Author: Peter Bartmann
 *
 ********************************************************************************/

#include "app_cfg.h"
#include "i2c.h"

#include "unistd.h"
#include "stdio.h"
#include "alt_types.h"
#include "common_types.h"
#include "i2c_opencores.h"
#include "system.h"
#include "altera_avalon_pio_regs.h"

i2c_reg_16b_16b_t tmp_reg_16b_16b;
i2c_reg_16b_8b_t  tmp_reg_16b_8b;
i2c_reg_8b_8b_t   tmp_reg_8b_8b;

void set_i2c_device(i2c_devices_t i2c_device) {
  IOWR_ALTERA_AVALON_PIO_DATA(I2C_DEVICE_SELECT_BASE, (alt_u8) i2c_device);
}

void i2c_reg_bitset(alt_u8 i2c_dev, alt_u8 *regaddr, bool_t long_addr, alt_u8 bit, bool_t dbl_byte) {
  if ((bit > 15) || (!dbl_byte & (bit > 7))) return;

  i2c_readregs(i2c_dev,regaddr,long_addr,&tmp_reg_16b_16b.data[0],1+dbl_byte);

  if (bit > 7) tmp_reg_16b_16b.data[0] = tmp_reg_16b_16b.data[0] | (1 << (bit-8));
  else         tmp_reg_16b_16b.data[1] = tmp_reg_16b_16b.data[1] | (1 << bit);

  i2c_writeregs(i2c_dev,regaddr,long_addr,&tmp_reg_16b_16b.data[0],1+dbl_byte);
}

void i2c_reg_bitclear(alt_u8 i2c_dev, alt_u8 *regaddr, bool_t long_addr, alt_u8 bit, bool_t dbl_byte) {
  if ((bit > 15) || (!dbl_byte & (bit > 7))) return;

  i2c_readregs(i2c_dev,regaddr,long_addr,&tmp_reg_16b_16b.data[0],1+dbl_byte);

  if (bit > 7) tmp_reg_16b_16b.data[0] = tmp_reg_16b_16b.data[0] & ~(1 << (bit-8));
  else         tmp_reg_16b_16b.data[1] = tmp_reg_16b_16b.data[1] & ~(1 << bit);

  i2c_writeregs(i2c_dev,regaddr,long_addr,&tmp_reg_16b_16b.data[0],1+dbl_byte);
}



void i2c_readregs(alt_u8 i2c_dev, const alt_u8 *regaddr, bool_t long_addr, alt_u8 *retvals, alt_u8 rd_length)
{
  if (rd_length < 1) return;

  alt_u8 idx;
  alt_u8 rd_length_local = rd_length;
  if (~long_addr && ((alt_u16) rd_length + (alt_u16) regaddr[0] > 255)) rd_length_local = 256 - regaddr[0];

  //Phase 1 - setup start address
  I2C_start(I2C_MASTER_BASE, i2c_dev, 0);
  I2C_write(I2C_MASTER_BASE, regaddr[0], 0);
  if (long_addr) I2C_write(I2C_MASTER_BASE, regaddr[1], 0);

  //Phase 2 - read register values
  I2C_start(I2C_MASTER_BASE, i2c_dev, 1);
  for (idx = 0; idx < rd_length_local; idx++)
    retvals[idx] = (alt_u8) I2C_read(I2C_MASTER_BASE, idx == (rd_length_local-1));
}

void i2c_writeregs(alt_u8 i2c_dev, const alt_u8 *regaddr, bool_t long_addr, const alt_u8 *wrvals, alt_u8 wr_length)
{
  if (wr_length < 1) return;

  alt_u8 idx;
  alt_u8 wr_length_local = wr_length;
  if (~long_addr && ((alt_u16) wr_length + (alt_u16) regaddr[0] > 255)) wr_length_local = 256 - regaddr[0];

  //Phase 1 - setup start address
  I2C_start(I2C_MASTER_BASE, i2c_dev, 0);
  I2C_write(I2C_MASTER_BASE, regaddr[0], 0);
  if (long_addr) I2C_write(I2C_MASTER_BASE, regaddr[1], 0);

  //Phase 2 - write register values
  for (idx = 0; idx < wr_length_local; idx++)
    I2C_write(I2C_MASTER_BASE, wrvals[idx], idx == (wr_length_local-1));
}

void i2c_writeregs_withmask(alt_u8 i2c_dev, const alt_u8 *regaddr, bool_t long_addr, const alt_u8 *wrvals, const alt_u8 *wrmasks, alt_u8 wr_length)
{
  if (wr_length < 1) return;

  alt_u8 idx = 0;
  alt_u8 wr_length_local = wr_length;
  if (~long_addr && ((alt_u16) wr_length + (alt_u16) regaddr[0] > 255)) wr_length_local = 256 - regaddr[0];
  alt_u8 regaddr_local[2] = {regaddr[0],regaddr[1]};
  alt_u8 regval_local;


  do {
    if (~long_addr) regaddr_local[0] = regaddr[0] + idx;
    else            regaddr_local[1] = regaddr[1] + idx;

    //Phase 1 - setup start address for current loop
    I2C_start(I2C_MASTER_BASE, i2c_dev, 0);
    I2C_write(I2C_MASTER_BASE, regaddr_local[0], 0);
    if (long_addr) I2C_write(I2C_MASTER_BASE, regaddr_local[1], 0);

    if (wrmasks[idx] == 0xFF) { // write without care about care on wrmask
      //Phase 2 - write register values
      for ( ; idx < wr_length_local; idx++) {
        if (idx == wr_length_local-1 || wrmasks[idx+1] != 0xFF) {
          I2C_write(I2C_MASTER_BASE, wrvals[idx],1);
          break;
        } else {
          I2C_write(I2C_MASTER_BASE, wrvals[idx],0);
        }
      }
    } else {
      //Phase 2 - read register value first
      I2C_start(I2C_MASTER_BASE, i2c_dev, 1);
      regval_local = (((alt_u8) I2C_read(I2C_MASTER_BASE, 1)) & ~wrmasks[idx]) | (wrvals[idx] & wrmasks[idx]);

      // Phase 3 - write modified value
      i2c_writeregs(i2c_dev,&regaddr_local[0],long_addr,&regval_local,1);
    }
    idx++;
  } while (idx < wr_length_local);
}

