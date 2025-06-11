set ROOT_PROJ_DIR ${TOOLS_DIR}/..

set PROJ_DIR  ${ROOT_PROJ_DIR}/aib-protocols
set AIB_ROOT  ${ROOT_PROJ_DIR}/aib-phy-hardware

# Define RTL directory
set AIB2_ROOT ${AIB_ROOT}/v2.0/
set AIBv1_1_ROOT ${AIB_ROOT}/v2.0/rev1.1

set AIBv1_ROOT ${AIB_ROOT}/v2.0/rev1
set AIBv1_RTL_ROOT ${AIBv1_ROOT}/rtl
set RTL_ROOT ${AIBv1_RTL_ROOT}

#Rev 1 Root
set AIBV1_DV_ROOT ${AIBv1_ROOT}/dv

#Gen1 Root
set GEN1_ROOT ${AIB_ROOT}/v1.0/rev2/rtl/
set V1S_ROOT ${GEN1_ROOT}/v1_slave

#Rev 1.1 Root
set AIB2v1_1_RTL_ROOT ${AIBv1_1_ROOT}/rtl/bca
set MAIBv1_1_RTL_ROOT ${AIBv1_1_ROOT}/rtl/maib_rev1.1
set AIBv1_1_DV_ROOT ${AIBv1_1_ROOT}/dv
set AIB2_RTL_ROOT ${AIB2v1_1_RTL_ROOT}
set FM_ROOT ${MAIBv1_1_RTL_ROOT}