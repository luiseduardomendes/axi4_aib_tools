
add_files -fileset sim_1 [list \
    ${PROJ_DIR}/axi4-st/axi_st_d64/axi_st_d64_master_top.sv \
    ${PROJ_DIR}/axi4-st/axi_st_d64/axi_st_d64_master_concat.sv \
    ${PROJ_DIR}/axi4-st/axi_st_d64/axi_st_d64_master_name.sv \
]

add_files -fileset sim_1 [list \
    ${PROJ_DIR}/axi4-st/axi_st_d64/axi_st_d64_slave_top.sv \
    ${PROJ_DIR}/axi4-st/axi_st_d64/axi_st_d64_slave_concat.sv \
    ${PROJ_DIR}/axi4-st/axi_st_d64/axi_st_d64_slave_name.sv \
]