read_verilog ${AIB2_ROOT}/rev1/dv/interface/dut_if_mac.sv
read_verilog ${AIB2_ROOT}/rev1/dv/interface/avalon_mm_if.sv

# Bridges
read_verilog -sv ${TOOLS_DIR}/rtl/axi_aib_bridges/aib_axi_bridge_master.v
read_verilog -sv ${TOOLS_DIR}/rtl/axi_aib_bridges/aib_axi_bridge_slave.v

# Generated Files
source ${TOOLS_DIR}/rtl/axi_mm/axi_mm.f

# FSM Configuration
source ${TOOLS_DIR}/rtl/aib_fsm/aib_fsm.f

# Logic Link Files
source ${TOOLS_DIR}/flists/llink.tcl

# Common Files
source ${TOOLS_DIR}/flists/common.tcl

# Channel Alignment Files
source ${TOOLS_DIR}/flists/ca.tcl

# AIB Files
source ${TOOLS_DIR}/flists/aib.tcl
