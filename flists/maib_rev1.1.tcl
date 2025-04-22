# MAIB Rev 1.1 files
# {PHY_DIR}/v2.0/rev1.1/dv/flist/maib_rev1.1.cf

add_files -fileset sim_1 [list \
    ${PHY_DIR}/v2.0/rev1.1/rtl/bca/src/rtl/aib_top/aib_phy_top.v \
    ${PHY_DIR}/v2.0/rev1.1/rtl/maib_rev1.1/maib_top_96pin.sv \
    ${FM_ROOT}/maib_lib_sim_model.v \
    ${FM_ROOT}/maib_top_96pin.sv \
    ${FM_ROOT}/ndaibadapt_wrap.v \
    ${FM_ROOT}/maib_ch.v \
    ${V1S_ROOT}/aibndaux_lib/rtl/aibndaux_top_slave.v \
    ${V1S_ROOT}/aibndaux_lib/rtl/aibndaux_pasred_simple.v \
]