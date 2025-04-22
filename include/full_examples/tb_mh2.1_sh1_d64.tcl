set include_files [list \
    ${PROJ_DIR}/axi4-st/full_examples/common/agent.sv \
    ${PROJ_DIR}/spi-aib/dv/interface/dut_sl1_port.inc \
    ${PHY_DIR}/v2.0/rev1/dv/interface/dut_emib.inc \
    ${PROJ_DIR}/axi4-st/full_examples/common/test_h2h.inc \
    ${PHY_DIR}/v2.0/rev1.1/dv/test/data/maib_prog_rev1.1.inc \
]

add_files -fileset sim_1 $include_files

foreach file $include_files {
    if {[file exists $file]} {
        set_property file_type "Verilog Header" [get_files $file]
    } else {
        puts "WARNING: File not found - $file"
    }
}

set_property include_dirs [list \
    ${PROJ_DIR}/axi4-st/full_examples/common \
    ${PROJ_DIR}/spi-aib/dv/interface \
    ${PHY_DIR}/v2.0/rev1/dv/interface \
    ${PHY_DIR}/v2.0/rev1.1/dv/test/data \
] [get_filesets sim_1]