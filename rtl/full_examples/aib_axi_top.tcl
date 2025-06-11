set TOOLS_DIR /home/mendes/axi4_aib/axi4_aib_tools

source ${TOOLS_DIR}/env/env.tcl

source ${TOOLS_DIR}/rtl/axi_aib_bridges/aib_axi_bridge.f

set_property file_type SystemVerilog [get_files *.v]

