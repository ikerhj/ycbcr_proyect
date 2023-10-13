/*********************************************************************************
 *
 * main.c
 *
 *  Created on: 02.11.2022
 *      Author: Peter Bartmann
 *
 ********************************************************************************/

#include "app_cfg.h"

#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include "alt_types.h"
#include "common_types.h"
#include <sys/alt_sys_init.h>
#include "i2c_opencores.h"
#include "altera_avalon_pio_regs.h"
#include "system.h"
#include "adv7513.h"
#include "si5338.h"
#include "ov8865.h"
#include "mipi_bridge.h"

#define SUCCESS 0

#define PLL_LOCK_2_D8M_TIMEOUT_MS 5

typedef struct {
  bool_t d8m_pll_locked;
  bool_t si5338_i2c_up;
  union {
    bool_t si5338_locked;
    bool_t vid_pll_locked;
  };
  bool_t adv7513_i2c_up;
  bool_t adv7513_hdmi_up;
  bool_t mipibr_i2c_up;
  bool_t mipibr_cfg_up;
  bool_t ov8865_i2c_up;
  bool_t ov8865_cfg_up;
} periphal_state_t;


periphal_state_t periphal_state = {FALSE,FALSE,{FALSE},FALSE,FALSE,FALSE,FALSE,FALSE,FALSE};


bool_t get_d8m_pll_lock()
{
  return (IORD_ALTERA_AVALON_PIO_DATA(PLL_LOCK_STATES_BASE) & 0x01);
};

bool_t get_n_use_rgb2ycbcr()
{
  return (IORD_ALTERA_AVALON_PIO_DATA(N_USE_RGB2YCBCR_BASE) & 0x01);
};

bool_t get_vid_pll_lock()
{
  if (IS_C5G_BOARD)     return si5338_pll_lockstatus();
  if (IS_DE10STD_BOARD) return ((IORD_ALTERA_AVALON_PIO_DATA(PLL_LOCK_STATES_BASE) & 0x02) >> 1);
  return FALSE;
};

bool_t get_cpu_sync()
{
  return (IORD_ALTERA_AVALON_PIO_DATA(CPU_SYNC_IN_BASE) & 0x01);
};



void d8m_startup_sequence(void) {
  set_hwrst_ov8865();
  set_hwrst_mipibr();
  usleep(2000);
  release_hwrst_ov8865();
  usleep(2000);
  release_hwrst_mipibr();
}

void d8m_init(void) {
  db_printf("d8m_init(): change i2c device to mipi decoder (gpio)...");
  set_i2c_device(GPIO_MIPI);
  db_printf(" done.\n");
  periphal_state.mipibr_i2c_up = check_mipi_bridge() == SUCCESS;
  if (periphal_state.mipibr_i2c_up) {
    periphal_state.mipibr_cfg_up = init_mipi_bridge() == SUCCESS;
//	usleep(500*1000);
  }

  if (periphal_state.mipibr_cfg_up) {
    db_printf("d8m_init(): change i2c device to camera sensor (gpio)...");
    set_i2c_device(GPIO_CAMERA);
    db_printf(" done.\n");
    periphal_state.ov8865_i2c_up = check_ov8865() == SUCCESS;
    if (periphal_state.ov8865_i2c_up) periphal_state.ov8865_cfg_up = init_ov8865(1) == SUCCESS;

    db_printf("d8m_init(): change i2c device to mipi decoder (gpio)...");
    set_i2c_device(GPIO_MIPI);
    db_printf(" done.\n");

    mipi_clear_error();
    usleep(50*1000);
    mipi_clear_error();
    usleep(1000*1000);
  //    mipi_show_error_info(0);
    mipi_show_error_info(1);
  } else {
    db_printf("d8m_init(): skip camera sensor ... mipi bridge is not up!\n");
  }
}


int main()
{
  clk_config_t target_clk_cfg_pre = FREE_1080p_16t9;
  clk_config_t target_clk_cfg = FREE_1080p_16t9;

  bool_t n_use_rgb2ycbcr = get_n_use_rgb2ycbcr();
  bool_t n_use_rgb2ycbcr_pre = n_use_rgb2ycbcr;

  db_printf("main(): init I2C interface...");
  I2C_init(I2C_MASTER_BASE,ALT_CPU_FREQ,200000);
  db_printf(" done.\n");

  d8m_startup_sequence();

  db_printf("main(): I'm running on GX Starter Kit...\n");

  db_printf("main(): check D8M PLL lock status...");
  while(!get_d8m_pll_lock()) {};  // wait for d8m pll
  periphal_state.d8m_pll_locked = TRUE;
  db_printf(" done.\n");
  usleep(1000*PLL_LOCK_2_D8M_TIMEOUT_MS);

  db_printf("main(): change i2c device to on-board i2c devices (hdmi and pll)...");
  set_i2c_device(ONBOARD_DEVICES);
  db_printf(" done.\n");

  while(check_si5338()!= SUCCESS)
    db_printf("main(): unable to communicate with Si5338 - it does not make sense to continue without having a clock.\n");
  periphal_state.si5338_i2c_up = TRUE;
  periphal_state.si5338_locked = init_si5338(target_clk_cfg);

  db_printf("main(): continue with D8M module initialization.\n");
  d8m_init(); // changes I2C bus connections, must be reset/changed back afterwards

  db_printf("main(): change i2c device to on-board i2c devices (hdmi and pll)...");
  set_i2c_device(ONBOARD_DEVICES);
  db_printf(" done.\n");

  /* Event loop never exits. */
  while (1) {

    // check D8M PLL
    periphal_state.d8m_pll_locked = get_d8m_pll_lock();
    if (!periphal_state.d8m_pll_locked) {
      db_printf("main(): lost D8M PLL lock... wait for lock...");
      do {
        periphal_state.d8m_pll_locked = get_d8m_pll_lock();
      } while (!periphal_state.d8m_pll_locked);
      db_printf("locked.\n");
      usleep(1000*PLL_LOCK_2_D8M_TIMEOUT_MS);
      db_printf("main(): re-initialize D8M module.\n");
      d8m_init();
    }

    periphal_state.vid_pll_locked = get_vid_pll_lock();

    // check RGB to YCbCr config
    n_use_rgb2ycbcr = get_n_use_rgb2ycbcr();

    // Update target_clk_cfg variable here
    if (!periphal_state.si5338_locked)
      periphal_state.si5338_locked = init_si5338(target_clk_cfg);
    else if (target_clk_cfg_pre != target_clk_cfg)
      configure_clk_si5338(target_clk_cfg,0);

    if (!periphal_state.adv7513_i2c_up)
      periphal_state.adv7513_i2c_up = check_adv7513() == 0;

    if (periphal_state.adv7513_i2c_up) {
      if (!periphal_state.adv7513_hdmi_up)
          periphal_state.adv7513_hdmi_up = init_adv7513(n_use_rgb2ycbcr);
      else if (!adv_hpd_state() || !adv_monitor_sense_state())
        periphal_state.adv7513_hdmi_up = FALSE;
      else if (n_use_rgb2ycbcr != n_use_rgb2ycbcr_pre)
        set_cfg_adv7513(n_use_rgb2ycbcr);
    }

    if (!(!periphal_state.si5338_locked || !periphal_state.adv7513_hdmi_up)) {
      // ToDo: show hardware here that periphals are ready
    }

    // synchronize main loop with VSYNC
    if (periphal_state.si5338_locked) { // skip sync if clock is not locked
      while(!get_cpu_sync()){};  /* wait for CPU-SYNC goes high */
      while( get_cpu_sync()){};  /* wait for CPU-SYNC goes low  */
    }

    n_use_rgb2ycbcr_pre = n_use_rgb2ycbcr;
    target_clk_cfg_pre = target_clk_cfg;
    // ToDo: update other possible configuration values
  }

  return 0;
}
