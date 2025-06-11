
# Top Module
read_verilog -sv ${TOOLS_DIR}/rtl/full_examples/aib_axi_top.v

# Master and Slave Bridges
source ${TOOLS_DIR}/rtl/axi_aib_bridges/aib_axi_bridge.f

# EMIB Files
source ${TOOLS_DIR}/flists/emib.tcl1