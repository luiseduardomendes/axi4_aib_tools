# Set environment variables
set TOOLS_ROOT /home/mendes/axi4_aib/axi4_aib_tools
set PROJ_DIR /home/mendes/axi4_aib/aib-protocols
set PHY_DIR /home/mendes/axi4_aib/aib-phy-hardware
set SIM_DIR ${PROJ_DIR}/axi4-mm/full_examples/sims
set tbench_dir ${SIM_DIR}/tb_mh2.1_sh1_d64
set flist_dir ${PROJ_DIR}/axi4-mm/full_examples/flists
source ${TOOLS_ROOT}/env/env.tcl

add_files -fileset sim_1 [list \
    ${SIM_DIR}/tb_mh2.1_sh1_d64/top_tb.v
]

set_property file_type {SystemVerilog} [get_files ${SIM_DIR}/tb_mh2.1_sh1_d64/top_tb.v]

# Add Verilog/SystemVerilog source files
source ${TOOLS_ROOT}/flists/full_examples/tb_axi_mm_mh2.1_sh1_d64.tcl
source ${TOOLS_ROOT}/flists/axi4-mm/axi_mm_d64.tcl
source ${TOOLS_ROOT}/flists/llink.tcl
source ${TOOLS_ROOT}/flists/ca.tcl
source ${TOOLS_ROOT}/flists/common.tcl
source ${TOOLS_ROOT}/flists/emib.tcl
source ${TOOLS_ROOT}/flists/aib.tcl
source ${TOOLS_ROOT}/flists/maib_rev1.1.tcl
source ${TOOLS_ROOT}/flists/others.tcl
source ${TOOLS_ROOT}/flists/agent.tcl

add_files -fileset sim_1 [list \
    ${SIM_DIR}/../common/top_aib.sv \
    ${SIM_DIR}/../common/aximm_aib_top.v \
    ${tbench_dir}/top_tb.v \
]

set_property file_type {SystemVerilog} [get_files *.v]

source ${TOOLS_ROOT}/include/full_examples/tb_mh2.1_sh1_d64.tcl

source ${TOOLS_ROOT}/define/full_examples/tb_mh2.1_sh1_d64.tcl

set_property top top_tb [get_filesets sim_1]

set_property -name {xsim.simulate.runtime} -value {1000ns} -objects [get_filesets sim_1]
set_property -name {xsim.simulate.log_all_signals} -value {true} -objects [get_filesets sim_1]


launch_simulation -simset [get_filesets sim_1] \
    -mode behavioral \
    -absolute_path \
    -install_path $::env(XILINX_VIVADO)
