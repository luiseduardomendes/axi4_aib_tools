# C Aligner files
# ${PROJ_DIR}/ca/rtl/ca.f

add_files -fileset sim_1 [list \
    ${PROJ_DIR}/ca/rtl/ca.sv \
    ${PROJ_DIR}/ca/rtl/ca_tx_strb.sv \
    ${PROJ_DIR}/ca/rtl/ca_rx_align.sv \
    ${PROJ_DIR}/ca/rtl/ca_rx_align_fifo.sv \
    ${PROJ_DIR}/ca/rtl/ca_tx_mux.sv \
]

# still depends on common file list
source ${TOOLS_ROOT}/flists/common.tcl
