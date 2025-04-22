add_files -fileset sim_1 [list \
    ${SIM_DIR}/../common/axi_st_multichannel_h2h_simplex_top.sv \
    ${PROJ_DIR}/common/dv/marker_gen.sv \
    ${PROJ_DIR}/common/dv/strobe_gen.sv \
    ${SIM_DIR}/../common/axist_rand_gen.v \
    ${SIM_DIR}/../common/axi_st_h2h_patgen_top.v \
    ${SIM_DIR}/../common/axi_st_wr_ctrl.v \
    ${SIM_DIR}/../common/axi_st_h2h_patchkr_top.v \
    ${SIM_DIR}/../common/axist_incr_gen.v \
    ${SIM_DIR}/../common/axi_st_h2h_csr.v \
    ${SIM_DIR}/../common/csr_ctrl_h2h.v \
    ${SIM_DIR}/../common/jtag2avmm_bridge.v \
    ${PROJ_DIR}/common/rtl/asyncfifo.sv \
    ${PROJ_DIR}/common/rtl/syncfifo_mem1r1w.sv \
]
