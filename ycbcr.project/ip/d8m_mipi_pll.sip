set_global_assignment -entity "d8m_mipi_pll" -library "lib_d8m_mipi_pll" -name IP_TOOL_NAME "altera_pll"
set_global_assignment -entity "d8m_mipi_pll" -library "lib_d8m_mipi_pll" -name IP_TOOL_VERSION "22.1"
set_global_assignment -entity "d8m_mipi_pll" -library "lib_d8m_mipi_pll" -name IP_TOOL_ENV "mwpim"
set_global_assignment -library "lib_d8m_mipi_pll" -name SPD_FILE [file join $::quartus(sip_path) "d8m_mipi_pll.spd"]

set_global_assignment -library "lib_d8m_mipi_pll" -name MISC_FILE [file join $::quartus(sip_path) "d8m_mipi_pll_sim/d8m_mipi_pll.vho"]
