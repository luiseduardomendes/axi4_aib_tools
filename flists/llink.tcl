# Logic Link Files
# ${PROJ_DIR}/llink/rtl/llink.f

add_files -fileset sim_1 [list \
    ${PROJ_DIR}/llink/rtl/ll_receive.sv \
    ${PROJ_DIR}/llink/rtl/ll_rx_ctrl.sv \
    ${PROJ_DIR}/llink/rtl/ll_rx_push.sv \
    ${PROJ_DIR}/llink/rtl/ll_transmit.sv \
    ${PROJ_DIR}/llink/rtl/ll_tx_cred.sv \
    ${PROJ_DIR}/llink/rtl/ll_tx_ctrl.sv \
    ${PROJ_DIR}/llink/rtl/ll_auto_sync.sv \
]
