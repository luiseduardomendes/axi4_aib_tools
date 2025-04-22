# Common Files
# ${PROJ_DIR}/common/rtl/common.f

add_files -fileset sim_1 [list \
    ${PROJ_DIR}/common/rtl/asyncfifo.sv \
    ${PROJ_DIR}/common/rtl/levelsync_sr.sv \
    ${PROJ_DIR}/common/rtl/levelsync.sv \
    ${PROJ_DIR}/common/rtl/rrarb.sv \
    ${PROJ_DIR}/common/rtl/syncfifo_mem1r1w.sv \
    ${PROJ_DIR}/common/rtl/syncfifo.sv \
    ${PROJ_DIR}/common/rtl/level_delay.sv \
    ${PROJ_DIR}/common/rtl/syncfifo_reg.sv \
    ${PROJ_DIR}/common/rtl/syncfifo_ram.sv \
    ${PROJ_DIR}/common/rtl/rst_regen_low.sv \
]
