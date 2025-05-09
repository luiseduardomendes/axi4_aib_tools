set PROJ_DIR /home/mendes/axi4_aib/aib-protocols
set TOOLS_DIR ${PROJ_DIR}/../axi4_aib_tools
set AIB2_RTL_ROOT ${PROJ_DIR}/../aib-phy-hardware/v2.0/rev1.1/rtl/bca
set AIB2_ROOT ${PROJ_DIR}/../aib-phy-hardware/v2.0/

set flist ${TOOLS_DIR}/rtl/full_examples/axi_lite/aib_axi_bridge_master.f

read_verilog ${TOOLS_DIR}/rtl/full_examples/axi_lite/aib_axi_bridge_master.v
read_verilog ${TOOLS_DIR}/rtl/interfaces/axi_if.v

source $flist

set_property file_type SystemVerilog [get_files *.v]

set_property top aib_axi_bridge_master [get_files *.v]
