# Common Files
# ${PROJ_DIR}/common/rtl/common.f

read_verilog -sv ${PROJ_DIR}/common/rtl/asyncfifo.sv
read_verilog -sv ${PROJ_DIR}/common/rtl/levelsync_sr.sv
read_verilog -sv ${PROJ_DIR}/common/rtl/levelsync.sv
read_verilog -sv ${PROJ_DIR}/common/rtl/rrarb.sv
read_verilog -sv ${PROJ_DIR}/common/rtl/syncfifo_mem1r1w.sv
read_verilog -sv ${PROJ_DIR}/common/rtl/syncfifo.sv
read_verilog -sv ${PROJ_DIR}/common/rtl/level_delay.sv
read_verilog -sv ${PROJ_DIR}/common/rtl/syncfifo_reg.sv
read_verilog -sv ${PROJ_DIR}/common/rtl/syncfifo_ram.sv
read_verilog -sv ${PROJ_DIR}/common/rtl/rst_regen_low.sv

