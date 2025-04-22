
add_files -fileset sim_1 [list \
    ${PHY_DIR}/v2.0/rev1/dv/test/task/agent_ch.sv \
]

set_property file_type "Verilog Header" [get_files ${PHY_DIR}/v2.0/rev1/dv/test/task/agent_ch.sv]
