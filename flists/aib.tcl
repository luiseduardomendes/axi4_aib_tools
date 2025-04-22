# AIB files
# ${PROJ_DIR}/ca/dv/aib.f

add_files -fileset sim_1 [list \
    ${PHY_DIR}/v2.0/rev1/rtl/aib_adapt_2doto.v \
    ${PHY_DIR}/v2.0/rev1/rtl/aib_adapt_rxchnl.v \
    ${PHY_DIR}/v2.0/rev1/rtl/aib_adaptrxdbi_rxdp.v \
    ${PHY_DIR}/v2.0/rev1/rtl/aib_adaptrxdp_async_fifo.v \
    ${PHY_DIR}/v2.0/rev1/rtl/aib_adaptrxdp_fifo_ptr.v \
    ${PHY_DIR}/v2.0/rev1/rtl/aib_adaptrxdp_fifo_ram.v \
    ${PHY_DIR}/v2.0/rev1/rtl/aib_adaptrxdp_fifo.v \
    ${PHY_DIR}/v2.0/rev1/rtl/aib_adapt_txchnl.v \
    ${PHY_DIR}/v2.0/rev1/rtl/aib_adapttxdbi_txdp.v \
    ${PHY_DIR}/v2.0/rev1/rtl/aib_adapttxdp_async_fifo.v \
    ${PHY_DIR}/v2.0/rev1/rtl/aib_adapttxdp_fifo_ptr.v \
    ${PHY_DIR}/v2.0/rev1/rtl/aib_adapttxdp_fifo_ram.v \
    ${PHY_DIR}/v2.0/rev1/rtl/aib_adapttxdp_fifo.v \
    ${PHY_DIR}/v2.0/rev1/rtl/aib_aliasd.v \
    ${PHY_DIR}/v2.0/rev1/rtl/aib_aux_channel.v \
    ${PHY_DIR}/v2.0/rev1/rtl/aib_avmm_adapt_csr.v \
    ${PHY_DIR}/v2.0/rev1/rtl/aib_avmm_io_csr.v \
    ${PHY_DIR}/v2.0/rev1/rtl/aib_avmm_rdl_intf.sv \
    ${PHY_DIR}/v2.0/rev1/rtl/aib_avmm.v \
    ${PHY_DIR}/v2.0/rev1/rtl/aib_bitsync.v \
    ${PHY_DIR}/v2.0/rev1/rtl/aib_bsr_red_wrap.v \
    ${PHY_DIR}/v2.0/rev1/rtl/aib_buffx1_top.v \
    ${PHY_DIR}/v2.0/rev1/rtl/aib_channel.v \
    ${PHY_DIR}/v2.0/rev1/rtl/aib_dcc.v \
    ${PHY_DIR}/v2.0/rev1/rtl/aib_io_buffer.sv \
    ${PHY_DIR}/v2.0/rev1/rtl/aib_ioring.v \
    ${PHY_DIR}/v2.0/rev1/rtl/aib_jtag_bscan.v \
    ${PHY_DIR}/v2.0/rev1/rtl/aib_model_top.v \
    ${PHY_DIR}/v2.0/rev1/rtl/aib_mux21.v \
    ${PHY_DIR}/v2.0/rev1/rtl/aib_redundancy.v \
    ${PHY_DIR}/v2.0/rev1/rtl/aib_rstnsync.v \
    ${PHY_DIR}/v2.0/rev1/rtl/aib_sm.v \
    ${PHY_DIR}/v2.0/rev1/rtl/aib_sr_ms.v \
    ${PHY_DIR}/v2.0/rev1/rtl/aib_sr_sl.v \
    ${PHY_DIR}/v2.0/rev1/rtl/dll.sv \
]