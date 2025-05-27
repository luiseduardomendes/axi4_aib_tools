read_verilog ${AIB2_ROOT}/rev1/dv/interface/dut_if_mac.sv
read_verilog ${AIB2_ROOT}/rev1/dv/interface/avalon_mm_if.sv

# Generated Files
read_verilog ${TOOLS_DIR}/rtl/full_examples/axi_lite/aib_calib_slave_fsm.v
read_verilog ${TOOLS_DIR}/rtl/axi_mm/axi_mm_slave_top.sv   
read_verilog ${TOOLS_DIR}/rtl/axi_mm/axi_mm_slave_concat.sv
read_verilog ${TOOLS_DIR}/rtl/axi_mm/axi_mm_slave_name.sv  

# Logic Link Files
read_verilog ${PROJ_DIR}/llink/rtl/ll_receive.sv
read_verilog ${PROJ_DIR}/llink/rtl/ll_rx_ctrl.sv
read_verilog ${PROJ_DIR}/llink/rtl/ll_rx_push.sv
read_verilog ${PROJ_DIR}/llink/rtl/ll_transmit.sv
read_verilog ${PROJ_DIR}/llink/rtl/ll_tx_cred.sv
read_verilog ${PROJ_DIR}/llink/rtl/ll_tx_ctrl.sv
read_verilog ${PROJ_DIR}/llink/rtl/ll_auto_sync.sv

# Common Files
read_verilog ${PROJ_DIR}/common/rtl/asyncfifo.sv
read_verilog ${PROJ_DIR}/common/rtl/levelsync_sr.sv
read_verilog ${PROJ_DIR}/common/rtl/levelsync.sv
read_verilog ${PROJ_DIR}/common/rtl/rrarb.sv
read_verilog ${PROJ_DIR}/common/rtl/syncfifo_mem1r1w.sv
read_verilog ${PROJ_DIR}/common/rtl/syncfifo.sv
read_verilog ${PROJ_DIR}/common/rtl/level_delay.sv
read_verilog ${PROJ_DIR}/common/rtl/syncfifo_reg.sv
read_verilog ${PROJ_DIR}/common/rtl/syncfifo_ram.sv
read_verilog ${PROJ_DIR}/common/rtl/rst_regen_low.sv

# Channel Alignment Files
read_verilog ${PROJ_DIR}/ca/rtl/ca.sv
read_verilog ${PROJ_DIR}/ca/rtl/ca_tx_strb.sv
read_verilog ${PROJ_DIR}/ca/rtl/ca_rx_align.sv
read_verilog ${PROJ_DIR}/ca/rtl/ca_rx_align_fifo.sv
read_verilog ${PROJ_DIR}/ca/rtl/ca_tx_mux.sv
read_verilog ${PROJ_DIR}/common/rtl/asyncfifo.sv
read_verilog ${PROJ_DIR}/common/rtl/syncfifo_mem1r1w.sv
read_verilog ${PROJ_DIR}/common/rtl/levelsync.sv
read_verilog ${PROJ_DIR}/common/rtl/level_delay.sv
read_verilog ${PROJ_DIR}/common/rtl/rst_regen_low.sv
read_verilog ${PROJ_DIR}/common/rtl/syncfifo.sv
read_verilog ${PROJ_DIR}/common/rtl/syncfifo_reg.sv
read_verilog ${PROJ_DIR}/common/rtl/syncfifo_ram.sv

# AIB Files
read_verilog ${AIB2_ROOT}/rev1/rtl/aib_adapt_2doto.v
read_verilog ${AIB2_ROOT}/rev1/rtl/aib_adapt_rxchnl.v
read_verilog ${AIB2_ROOT}/rev1/rtl/aib_adapt_txchnl.v
read_verilog ${AIB2_ROOT}/rev1/rtl/aib_adaptrxdbi_rxdp.v
read_verilog ${AIB2_ROOT}/rev1/rtl/aib_adaptrxdp_async_fifo.v
read_verilog ${AIB2_ROOT}/rev1/rtl/aib_adaptrxdp_fifo_ptr.v
read_verilog ${AIB2_ROOT}/rev1/rtl/aib_adaptrxdp_fifo_ram.v
read_verilog ${AIB2_ROOT}/rev1/rtl/aib_adaptrxdp_fifo.v
read_verilog ${AIB2_ROOT}/rev1/rtl/aib_adapttxdbi_txdp.v
read_verilog ${AIB2_ROOT}/rev1/rtl/aib_adapttxdp_async_fifo.v
read_verilog ${AIB2_ROOT}/rev1/rtl/aib_adapttxdp_fifo_ptr.v
read_verilog ${AIB2_ROOT}/rev1/rtl/aib_adapttxdp_fifo_ram.v
read_verilog ${AIB2_ROOT}/rev1/rtl/aib_adapttxdp_fifo.v
read_verilog ${AIB2_ROOT}/rev1/rtl/aib_aliasd.v
read_verilog ${AIB2_ROOT}/rev1/rtl/aib_aux_channel.v
read_verilog ${AIB2_ROOT}/rev1/rtl/aib_avmm_adapt_csr.v
read_verilog ${AIB2_ROOT}/rev1/rtl/aib_avmm_io_csr.v
read_verilog ${AIB2_ROOT}/rev1/rtl/aib_avmm_rdl_intf.sv
read_verilog ${AIB2_ROOT}/rev1/rtl/aib_avmm.v
read_verilog ${AIB2_ROOT}/rev1/rtl/aib_bitsync.v
read_verilog ${AIB2_ROOT}/rev1/rtl/aib_bsr_red_wrap.v
read_verilog ${AIB2_ROOT}/rev1/rtl/aib_buffx1_top.v
read_verilog ${AIB2_ROOT}/rev1/rtl/aib_channel.v
read_verilog ${AIB2_ROOT}/rev1/rtl/aib_dcc.v
read_verilog ${AIB2_ROOT}/rev1/rtl/aib_io_buffer.sv
read_verilog ${AIB2_ROOT}/rev1/rtl/aib_ioring.v
read_verilog ${AIB2_ROOT}/rev1/rtl/aib_jtag_bscan.v
read_verilog ${AIB2_ROOT}/rev1/rtl/aib_model_top.v
read_verilog ${AIB2_ROOT}/rev1/rtl/aib_mux21.v
read_verilog ${AIB2_ROOT}/rev1/rtl/aib_redundancy.v
read_verilog ${AIB2_ROOT}/rev1/rtl/aib_rstnsync.v
read_verilog ${AIB2_ROOT}/rev1/rtl/aib_sm.v
read_verilog ${AIB2_ROOT}/rev1/rtl/aib_sr_ms.v
read_verilog ${AIB2_ROOT}/rev1/rtl/aib_sr_sl.v
read_verilog ${AIB2_ROOT}/rev1/rtl/dll.sv

# Avalon Files
read_verilog ${AIB2_ROOT}/rev1/dv/interface/avalon_mm_if.sv