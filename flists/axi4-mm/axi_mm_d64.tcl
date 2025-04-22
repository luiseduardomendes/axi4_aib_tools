
add_files -fileset sim_1 [list \
    ${tbench_dir}/axi_mm/axi_mm_master_top.sv \
    ${tbench_dir}/axi_mm/axi_mm_master_concat.sv \
    ${tbench_dir}/axi_mm/axi_mm_master_name.sv \
]

add_files -fileset sim_1 [list \
    ${tbench_dir}/axi_mm/axi_mm_slave_top.sv \
    ${tbench_dir}/axi_mm/axi_mm_slave_concat.sv \
    ${tbench_dir}/axi_mm/axi_mm_slave_name.sv \
]