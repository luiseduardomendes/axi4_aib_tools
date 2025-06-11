# Logic Link Files
# ${PROJ_DIR}/llink/rtl/llink.f

read_verilog -sv ${PROJ_DIR}/llink/rtl/ll_receive.sv
read_verilog -sv ${PROJ_DIR}/llink/rtl/ll_rx_ctrl.sv
read_verilog -sv ${PROJ_DIR}/llink/rtl/ll_rx_push.sv
read_verilog -sv ${PROJ_DIR}/llink/rtl/ll_transmit.sv
read_verilog -sv ${PROJ_DIR}/llink/rtl/ll_tx_cred.sv
read_verilog -sv ${PROJ_DIR}/llink/rtl/ll_tx_ctrl.sv
read_verilog -sv ${PROJ_DIR}/llink/rtl/ll_auto_sync.sv
