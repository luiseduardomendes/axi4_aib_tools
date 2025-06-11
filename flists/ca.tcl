# C Aligner files
# ${PROJ_DIR}/ca/rtl/ca.f

read_verilog -sv ${PROJ_DIR}/ca/rtl/ca.sv
read_verilog -sv ${PROJ_DIR}/ca/rtl/ca_tx_strb.sv
read_verilog -sv ${PROJ_DIR}/ca/rtl/ca_rx_align.sv
read_verilog -sv ${PROJ_DIR}/ca/rtl/ca_rx_align_fifo.sv
read_verilog -sv ${PROJ_DIR}/ca/rtl/ca_tx_mux.sv

# still depends on common file list
source ${TOOLS_DIR}/flists/common.tcl
