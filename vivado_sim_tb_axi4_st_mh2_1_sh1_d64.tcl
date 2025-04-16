# Set environment variables
set PROJ_DIR /home/mendes/axi4_aib/aib-protocols
set PHY_DIR /home/mendes/axi4_aib/aib-phy-hardware
set SIM_DIR ${PROJ_DIR}/axi4-st/full_examples/sims
set tbench_dir ${SIM_DIR}/tb_mh2.1_sh1_d64
set flist_dir ${PROJ_DIR}/axi4-st/full_examples/flists

set AIBv1_ROOT ${AIB_ROOT}/v2.0/rev1
set AIBv1_RTL_ROOT ${AIBv1_ROOT}/rtl
set RTL_ROOT ${AIBv1_RTL_ROOT}

#Rev 1 Root
set AIBV1_DV_ROOT ${AIBv1_ROOT}/dv

## Define RTL directory
set AIB_ROOT ${PROJ_DIR}/../aib-phy-hardware
set AIBv1_1_ROOT ${AIB_ROOT}/v2.0/rev1.1


#Gen1 Root
set GEN1_ROOT ${AIB_ROOT}/v1.0/rev2/rtl/
set V1S_ROOT ${GEN1_ROOT}/v1_slave



#Rev 1.1 Root
set AIB2v1_1_RTL_ROOT ${AIBv1_1_ROOT}/rtl/bca
set MAIBv1_1_RTL_ROOT ${AIBv1_1_ROOT}/rtl/maib_rev1.1
set AIBv1_1_DV_ROOT ${AIBv1_1_ROOT}/dv
set AIB2_RTL_ROOT ${AIB2v1_1_RTL_ROOT}
set FM_ROOT ${MAIBv1_1_RTL_ROOT}



# Create project or open an existing one
# Uncomment the next line if you want to create a new project
# create_project sim_axi_st_multichannel_h2h_simplex ./sim_axi_proj -part xc7z020clg484-1

add_files -fileset sim_1 [list \
    ${SIM_DIR}/tb_mh2.1_sh1_d64/top_tb.v
]

set_property file_type {SystemVerilog} [get_files ${SIM_DIR}/tb_mh2.1_sh1_d64/top_tb.v]

# Add Verilog/SystemVerilog source files
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

add_files -fileset sim_1 [list \
    ${PROJ_DIR}/llink/rtl/ll_receive.sv \
    ${PROJ_DIR}/llink/rtl/ll_rx_ctrl.sv \
    ${PROJ_DIR}/llink/rtl/ll_rx_push.sv \
    ${PROJ_DIR}/llink/rtl/ll_transmit.sv \
    ${PROJ_DIR}/llink/rtl/ll_tx_cred.sv \
    ${PROJ_DIR}/llink/rtl/ll_tx_ctrl.sv \
    ${PROJ_DIR}/llink/rtl/ll_auto_sync.sv \
]

add_files -fileset sim_1 [list \
    ${PROJ_DIR}/ca/rtl/ca.sv \
    ${PROJ_DIR}/ca/rtl/ca_tx_strb.sv \
    ${PROJ_DIR}/ca/rtl/ca_rx_align.sv \
    ${PROJ_DIR}/ca/rtl/ca_rx_align_fifo.sv \
    ${PROJ_DIR}/ca/rtl/ca_tx_mux.sv \
    ${PROJ_DIR}/common/rtl/asyncfifo.sv \
    ${PROJ_DIR}/common/rtl/syncfifo_mem1r1w.sv \
    ${PROJ_DIR}/common/rtl/levelsync.sv \
    ${PROJ_DIR}/common/rtl/level_delay.sv \
    ${PROJ_DIR}/common/rtl/rst_regen_low.sv \
    ${PROJ_DIR}/common/rtl/syncfifo.sv \
    ${PROJ_DIR}/common/rtl/syncfifo_reg.sv \
    ${PROJ_DIR}/common/rtl/syncfifo_ram.sv \
]

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

add_files -fileset sim_1 [list \
    ${AIBV1_DV_ROOT}/emib/aliasv.sv \
    ${AIBV1_DV_ROOT}/emib/emib_ch_m1s2.sv \
    ${AIBV1_DV_ROOT}/emib/emib_ch_m2s1.sv \
    ${AIBV1_DV_ROOT}/emib/emib_ch_m2s2.sv \
    ${AIBV1_DV_ROOT}/emib/emib_m1s2.sv \
    ${AIBV1_DV_ROOT}/emib/emib_m2s1.sv \
    ${AIBV1_DV_ROOT}/emib/emib_m2s2.sv \
    ${AIBV1_DV_ROOT}/interface/dut_if_mac.sv \
    ${AIBV1_DV_ROOT}/interface/avalon_mm_if.sv \
    ${SIM_DIR}/../common/top_h2h_aib.sv \
    ${SIM_DIR}/../common/axist_aib_h2h_top.v \
    ${SIM_DIR}/../common/reset_control.v \
    ${tbench_dir}/top_tb.v \
]

add_files -fileset sim_1 [list \
    ${PHY_DIR}/v2.0/rev1/rtl/aib_adapt_2doto.v \
    ${PHY_DIR}/v2.0/rev1/rtl/aib_adapt_rxchnl.v \
    ${PHY_DIR}/v2.0/rev1/rtl/aib_adaptrxdbi_rxdp.v \
    ${PHY_DIR}/v2.0/rev1/rtl/aib_adaptrxdp_async_fifo.v \
    ${PHY_DIR}/v2.0/rev1/rtl/aib_adaptrxdp_fifo_ptr.v \
    ${PHY_DIR}/v2.0/rev1/rtl/aib_adaptrxdp_fifo_ram.v \
    ${PHY_DIR}/v2.0/rev1/rtl/aib_adaptrxdp_fifo.v \
    ${PHY_DIR}/v2.0/rev1/rtl/aib_adapt_txchnl.v \
    ${PHY_DIR}/v2.0/rev1/rtl/aib_adapttxdbi_txdp.v \
    ${PHY_DIR}/v2.0/rev1/rtl/aib_adapttxdp_async_fifo.v \
    ${PHY_DIR}/v2.0/rev1/rtl/aib_adapttxdp_fifo_ptr.v \
    ${PHY_DIR}/v2.0/rev1/rtl/aib_adapttxdp_fifo_ram.v \
    ${PHY_DIR}/v2.0/rev1/rtl/aib_adapttxdp_fifo.v \
    ${PHY_DIR}/v2.0/rev1/rtl/aib_aliasd.v \
    ${PHY_DIR}/v2.0/rev1/rtl/aib_aux_channel.v \
    ${PHY_DIR}/v2.0/rev1/rtl/aib_avmm_adapt_csr.v \
    ${PHY_DIR}/v2.0/rev1/rtl/aib_avmm_io_csr.v \
    ${PHY_DIR}/v2.0/rev1/rtl/aib_avmm_rdl_intf.sv \
    ${PHY_DIR}/v2.0/rev1/rtl/aib_avmm.v \
    ${PHY_DIR}/v2.0/rev1/rtl/aib_bitsync.v \
    ${PHY_DIR}/v2.0/rev1/rtl/aib_bsr_red_wrap.v \
    ${PHY_DIR}/v2.0/rev1/rtl/aib_buffx1_top.v \
    ${PHY_DIR}/v2.0/rev1/rtl/aib_channel.v \
    ${PHY_DIR}/v2.0/rev1/rtl/aib_dcc.v \
    ${PHY_DIR}/v2.0/rev1/rtl/aib_io_buffer.sv \
    ${PHY_DIR}/v2.0/rev1/rtl/aib_ioring.v \
    ${PHY_DIR}/v2.0/rev1/rtl/aib_jtag_bscan.v \
    ${PHY_DIR}/v2.0/rev1/rtl/aib_model_top.v \
    ${PHY_DIR}/v2.0/rev1/rtl/aib_mux21.v \
    ${PHY_DIR}/v2.0/rev1/rtl/aib_redundancy.v \
    ${PHY_DIR}/v2.0/rev1/rtl/aib_rstnsync.v \
    ${PHY_DIR}/v2.0/rev1/rtl/aib_sm.v \
    ${PHY_DIR}/v2.0/rev1/rtl/aib_sr_ms.v \
    ${PHY_DIR}/v2.0/rev1/rtl/aib_sr_sl.v \
    ${PHY_DIR}/v2.0/rev1/rtl/dll.sv \
]

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

add_files -fileset sim_1 [list \
    ${AIB2_RTL_ROOT}/ana_models/msv_models/aibio_dqs_dcs_cbb.sv \
    ${AIB2_RTL_ROOT}/ana_models/msv_models/aibio_adc_cbb.sv \
    ${AIB2_RTL_ROOT}/ana_models/msv_models/aibio_clkdist_inv1_cbb.sv \
    ${AIB2_RTL_ROOT}/ana_models/msv_models/aibio_clkdist_inv2_cbb.sv \
    ${AIB2_RTL_ROOT}/ana_models/msv_models/aibio_rxclk_cbb.sv \
    ${AIB2_RTL_ROOT}/ana_models/msv_models/aibio_vref_cbb.sv \
    ${AIB2_RTL_ROOT}/ana_models/msv_models/TXRX/aibio_txrx_cbb.sv \
    ${AIB2_RTL_ROOT}/ana_models/msv_models/TXRX/en_logic_xxpad.sv \
    ${AIB2_RTL_ROOT}/ana_models/msv_models/TXRX/pad_out_logic.sv \
    ${AIB2_RTL_ROOT}/ana_models/msv_models/TXRX/sampler.sv \
    ${AIB2_RTL_ROOT}/ana_models/msv_models/DLL/aibio_decoder2x4.sv \
    ${AIB2_RTL_ROOT}/ana_models/msv_models/DLL/aibio_decoder3x8.sv \
    ${AIB2_RTL_ROOT}/ana_models/msv_models/DLL/aibio_dll_top.sv \
    ${AIB2_RTL_ROOT}/ana_models/msv_models/DLL/aibio_lock_detector.sv \
    ${AIB2_RTL_ROOT}/ana_models/msv_models/DLL/aibio_outclk_mux16x1.sv \
    ${AIB2_RTL_ROOT}/ana_models/msv_models/DLL/aibio_outclk_select.sv \
    ${AIB2_RTL_ROOT}/ana_models/msv_models/DLL/aibio_piclk_dist.sv \
    ${AIB2_RTL_ROOT}/ana_models/msv_models/DLL/aibio_pimux4x1.sv \
    ${AIB2_RTL_ROOT}/ana_models/msv_models/DLL/aibio_se_to_diff.sv \
    ${AIB2_RTL_ROOT}/ana_models/msv_models/DLL/RX_DLL/aibio_3bit_bin_to_therm.sv \
    ${AIB2_RTL_ROOT}/ana_models/msv_models/DLL/RX_DLL/aibio_4bit_plus1.sv \
    ${AIB2_RTL_ROOT}/ana_models/msv_models/DLL/RX_DLL/aibio_bias_trim.sv \
    ${AIB2_RTL_ROOT}/ana_models/msv_models/DLL/RX_DLL/aibio_cdr_detect.sv \
    ${AIB2_RTL_ROOT}/ana_models/msv_models/DLL/RX_DLL/aibio_half_adder.sv \
    ${AIB2_RTL_ROOT}/ana_models/msv_models/DLL/RX_DLL/aibio_inpclk_select.sv \
    ${AIB2_RTL_ROOT}/ana_models/msv_models/DLL/RX_DLL/aibio_pi_codeupdate.sv \
    ${AIB2_RTL_ROOT}/ana_models/msv_models/DLL/RX_DLL/aibio_pi_decode.sv \
    ${AIB2_RTL_ROOT}/ana_models/msv_models/DLL/RX_DLL/aibio_pi_decode_sync.sv \
    ${AIB2_RTL_ROOT}/ana_models/msv_models/DLL/RX_DLL/aibio_pi_mixer_top.sv \
    ${AIB2_RTL_ROOT}/ana_models/msv_models/DLL/RX_DLL/aibio_pioddevn_mixer_top.sv \
    ${AIB2_RTL_ROOT}/ana_models/msv_models/DLL/RX_DLL/aibio_pioddevn_phsel_half.sv \
    ${AIB2_RTL_ROOT}/ana_models/msv_models/DLL/RX_DLL/aibio_pioddevn_top.sv \
    ${AIB2_RTL_ROOT}/ana_models/msv_models/DLL/RX_DLL/aibio_pi_phsel_halfside.sv \
    ${AIB2_RTL_ROOT}/ana_models/msv_models/DLL/RX_DLL/aibio_pi_phsel_quarter.sv \
    ${AIB2_RTL_ROOT}/ana_models/msv_models/DLL/RX_DLL/aibio_rxdll_cbb.sv \
    ${AIB2_RTL_ROOT}/ana_models/msv_models/DLL/TX_DLL/aibio_inpclk_select_txdll.sv \
    ${AIB2_RTL_ROOT}/ana_models/msv_models/DLL/TX_DLL/aibio_pulsegen_mux2x1.sv \
    ${AIB2_RTL_ROOT}/ana_models/msv_models/DLL/TX_DLL/aibio_pulsegen_mux8x1.sv \
    ${AIB2_RTL_ROOT}/ana_models/msv_models/DLL/TX_DLL/aibio_pulsegen_muxfinal.sv \
    ${AIB2_RTL_ROOT}/ana_models/msv_models/DLL/TX_DLL/aibio_pulsegen_oddevn_halfside.sv \
    ${AIB2_RTL_ROOT}/ana_models/msv_models/DLL/TX_DLL/aibio_pulsegen_phsel_halfside.sv \
    ${AIB2_RTL_ROOT}/ana_models/msv_models/DLL/TX_DLL/aibio_pulsegen_top.sv \
    ${AIB2_RTL_ROOT}/ana_models/msv_models/DLL/TX_DLL/aibio_txdll_cbb.sv \
    ${AIB2_RTL_ROOT}/ana_models/msv_models/AUX_CH/aibio_auxch_cbb.sv \
    ${AIB2_RTL_ROOT}/ana_models/msv_models/AUX_CH/aibio_auxch_Schmit_trigger.sv \
    ${AIB2_RTL_ROOT}/ana_models/msv_models/PVTMON/aibio_pvtmon_3to8dec.sv \
    ${AIB2_RTL_ROOT}/ana_models/msv_models/PVTMON/aibio_pvtmon_cbb.sv \
    ${AIB2_RTL_ROOT}/ana_models/msv_models/PVTMON/aibio_pvtmon_clk_divby2.sv \
    ${AIB2_RTL_ROOT}/ana_models/msv_models/PVTMON/aibio_pvtmon_clkdiv.sv \
    ${AIB2_RTL_ROOT}/ana_models/msv_models/PVTMON/aibio_pvtmon_ctr10b.sv \
    ${AIB2_RTL_ROOT}/ana_models/msv_models/PVTMON/aibio_pvtmon_ctrunit.sv \
    ${AIB2_RTL_ROOT}/ana_models/msv_models/PVTMON/aibio_pvtmon_dig.sv \
    ${AIB2_RTL_ROOT}/ana_models/msv_models/PVTMON/aibio_pvtmon_digview.sv \
    ${AIB2_RTL_ROOT}/ana_models/msv_models/PVTMON/aibio_pvtmon_ndmnn11.sv \
    ${AIB2_RTL_ROOT}/ana_models/msv_models/PVTMON/aibio_pvtmon_oscbank.sv \
    ${AIB2_RTL_ROOT}/ana_models/msv_models/PVTMON/aibio_pvtmon_pdmpp11.sv \
    ${AIB2_RTL_ROOT}/ana_models/msv_models/PVTMON/flop.sv \
    ${AIB2_RTL_ROOT}/ana_models/msv_models/PVTMON/mux2x1.sv \
    ${AIB2_RTL_ROOT}/src/rtl/common/aib_bit_sync.v \
    ${AIB2_RTL_ROOT}/src/rtl/common/aib_bus_sync.v \
    ${AIB2_RTL_ROOT}/src/rtl/common/aib_rst_sync.v \
    ${AIB2_RTL_ROOT}/src/rtl/common/aib_adapt_fifo_mem.v \
    ${AIB2_RTL_ROOT}/src/rtl/common/aib_adapt_fifo_ptr.v \
    ${AIB2_RTL_ROOT}/src/rtl/common/aib_clk_div.v \
    ${AIB2_RTL_ROOT}/src/rtl/common/aib_fifo_and_sel.v \
    ${AIB2_RTL_ROOT}/src/rtl/common/aib_fifo_rdata_ored.sv \
    ${AIB2_RTL_ROOT}/src/rtl/common/aib_fifo_rdata_buf.v \
    ${AIB2_RTL_ROOT}/src/rtl/common/aib_clk_div_sys.v \
    ${AIB2_RTL_ROOT}/src/rtl/common/aib_clk_div_roffcal.v \
    ${AIB2_RTL_ROOT}/src/rtl/common/aib_clk_div_rcomp.v \
    ${AIB2_RTL_ROOT}/src/rtl/common/aib_clk_div_dcs.v \
    ${AIB2_RTL_ROOT}/src/rtl/common/aib_bs_clk_gating.v \
    ${AIB2_RTL_ROOT}/src/rtl/common/aib_bscan.v \
    ${AIB2_RTL_ROOT}/src/rtl/aibadapt/aibadapt_rxchnl/aib_rx_bert.v \
    ${AIB2_RTL_ROOT}/src/rtl/aibadapt/aibadapt_rxchnl/aib_bert_chk.v \
    ${AIB2_RTL_ROOT}/src/rtl/aibadapt/aibadapt_txchnl/aib_tx_bert.sv \
    ${AIB2_RTL_ROOT}/src/rtl/aibadapt/aibadapt_txchnl/aib_bert_gen.v \
    ${AIB2_RTL_ROOT}/src/rtl/common/aib_bert_cdc.v \
    ${AIB2_RTL_ROOT}/behavior/clk_mux.v \
    ${AIB2_RTL_ROOT}/behavior/clk_gate_cel.v \
    ${AIB2_RTL_ROOT}/behavior/clk_or2_cel.v \
    ${AIB2_RTL_ROOT}/behavior/clk_or3_cel.v \
    ${AIB2_RTL_ROOT}/behavior/clk_and2_cel.v \
    ${AIB2_RTL_ROOT}/behavior/clk_and3_cel.v \
    ${AIB2_RTL_ROOT}/behavior/clk_and4_cel.v \
    ${AIB2_RTL_ROOT}/behavior/clk_den_flop.v \
    ${AIB2_RTL_ROOT}/behavior/clk_inv_cel.v \
    ${AIB2_RTL_ROOT}/behavior/dmux_cell.v \
    ${AIB2_RTL_ROOT}/behavior/clk_buf_cel.v \
    ${AIB2_RTL_ROOT}/behavior/clk_resize_cel.v \
    ${AIB2_RTL_ROOT}/src/rtl/common/aib_cdc_data_mux.v \
    ${AIB2_RTL_ROOT}/src/rtl/aibadapt/aibadapt_sr/aib_sr_fsm.v \
    ${AIB2_RTL_ROOT}/src/rtl/aibadapt/aibadapt_sr/aib_sr_master.v \
    ${AIB2_RTL_ROOT}/src/rtl/aibadapt/aibadapt_sr/aib_sr_slave.v \
    ${AIB2_RTL_ROOT}/src/rtl/aibadapt/aibadapt_rxchnl/aib_rxfifo_rdata_sel.sv \
    ${AIB2_RTL_ROOT}/src/rtl/aibadapt/aibadapt_rxchnl/aib_rxfifo_clk_gating.v \
    ${AIB2_RTL_ROOT}/src/rtl/aibadapt/aibadapt_txchnl/aib_txfifo_clk_gating.v \
    ${AIB2_RTL_ROOT}/src/rtl/aibadapt/aibadapt_rxchnl/aib_rxfifo_rd_dpath.sv \
    ${AIB2_RTL_ROOT}/src/rtl/aibadapt/aibadapt_txchnl/aib_txfifo_rd_dpath.sv \
    ${AIB2_RTL_ROOT}/src/rtl/aibadapt/aibadapt_rxchnl/aib_adapter_rxchnl.v \
    ${AIB2_RTL_ROOT}/src/rtl/aibadapt/aibadapt_txchnl/aib_adapter_txchnl.v \
    ${AIB2_RTL_ROOT}/src/rtl/aibadapt/aibadapt_rxchnl/aib_rx_dbi.v \
    ${AIB2_RTL_ROOT}/src/rtl/aibadapt/aibadapt_rxchnl/aib_rx_fifo_wam.v \
    ${AIB2_RTL_ROOT}/src/rtl/aibadapt/aibadapt_rxchnl/aib_adapt_rx_fifo.v \
    ${AIB2_RTL_ROOT}/src/rtl/aibadapt/aibadapt_txchnl/aib_tx_dbi.v \
    ${AIB2_RTL_ROOT}/src/rtl/aibadapt/aibadapt_txchnl/aib_adapt_tx_fifo.v \
    ${AIB2_RTL_ROOT}/src/rtl/aibadapt/aib_adapter.v \
    ${AIB2_RTL_ROOT}/src/rtl/aibadapt/aibadapt_avmm/aib_avalon_if.sv \
    ${AIB2_RTL_ROOT}/src/rtl/aibadapt/aibadapt_avmm/aib_avalon_adapt_reg.v \
    ${AIB2_RTL_ROOT}/src/rtl/aibadapt/aibadapt_avmm/aib_avalon_io_regs.v \
    ${AIB2_RTL_ROOT}/src/rtl/aibadapt/aibadapt_avmm/aib_avalon.v \
    ${AIB2_RTL_ROOT}/src/rtl/aib_fsm/aib_cdr_fsm.v \
    ${AIB2_RTL_ROOT}/src/rtl/aib_fsm/phase_adjust_fsm.v \
    ${AIB2_RTL_ROOT}/src/rtl/aib_fsm/phase_adjust_fsm_top.v \
    //${AIB2_RTL_ROOT}/src/rtl/aib_fsm/rx_offset_cal_fsm.v \
    ${AIB2_RTL_ROOT}/src/rtl/aib_fsm/rx_offset_cal_fsm_top.v \
    ${AIB2_RTL_ROOT}/src/rtl/aib_fsm/rx_offset_cal.v \
    ${AIB2_RTL_ROOT}/src/rtl/aib_fsm/rxoffset_top.v \
    ${AIB2_RTL_ROOT}/src/rtl/aib_fsm/rcomp_calibration_fsm.v \
    ${AIB2_RTL_ROOT}/src/rtl/aib_fsm/aib_ntl_fsm.v \
    ${AIB2_RTL_ROOT}/src/rtl/aib_fsm/aib_dcs_fsm.v \
    ${AIB2_RTL_ROOT}/src/rtl/aib_fsm/aib_dfx_mon.v \
    ${AIB2_RTL_ROOT}/src/rtl/aib_top/aib_channel_n.v \
    ${AIB2_RTL_ROOT}/src/rtl/aib_top/aibio_ana_top.v \
    ${AIB2_RTL_ROOT}/src/rtl/redundancy/aib_redundancy.v \
    ${AIB2_RTL_ROOT}/src/rtl/redundancy/aib_redundancy_wrp.v \
    ${AIB2_RTL_ROOT}/src/rtl/redundancy/aib_redundancy_wrp_top.v \
    ${AIB2_RTL_ROOT}/src/rtl/aib_top/aib_deskew_logic.v \
    ${AIB2_RTL_ROOT}/src/rtl/aib_fsm/aib_dll_ctrl_logic.v \
    ${AIB2_RTL_ROOT}/src/rtl/aib_top/aib_avmm_glue_logic.sv \
    ${AIB2_RTL_ROOT}/src/rtl/aib_top/aib_avmm_top.v \
    ${AIB2_RTL_ROOT}/src/rtl/aib_top/aib_phy_top.v \
]

add_files -fileset sim_1 [list \
    ${PHY_DIR}/v2.0/rev1/dv/test/task/agent_ch.sv \
]

set_property file_type "Verilog Header" [get_files ${PHY_DIR}/v2.0/rev1/dv/test/task/agent_ch.sv]

set_property file_type {SystemVerilog} [get_files *.v]

# 1. First set all include files and their properties
set include_files [list \
    ${PROJ_DIR}/axi4-st/full_examples/common/agent.sv \
    ${PROJ_DIR}/spi-aib/dv/interface/dut_sl1_port.inc \
    ${PHY_DIR}/v2.0/rev1/dv/interface/dut_emib.inc \
    ${PROJ_DIR}/axi4-st/full_examples/common/test_h2h.inc \
    ${PHY_DIR}/v2.0/rev1.1/dv/test/data/maib_prog_rev1.1.inc \
]

foreach file $include_files {
    if {[file exists $file]} {
        set_property file_type "Verilog Header" [get_files $file]
    } else {
        puts "WARNING: File not found - $file"
    }
}

# 2. Set include directories (critical for simulation)
set_property include_dirs [list \
    ${PROJ_DIR}/axi4-st/full_examples/common \
    ${PROJ_DIR}/spi-aib/dv/interface \
    ${PHY_DIR}/v2.0/rev1/dv/interface \
    ${PHY_DIR}/v2.0/rev1.1/dv/test/data \
] [get_filesets sim_1]

# 3. Set simulation properties BEFORE launching
# Define macros properly for simulation
# 1. First, set the VERILOG_DEFINE property on the simulation fileset
# For simple defines (no value needed):
set_property verilog_define {
    "FOR_SIM_ONLY"
    "AIB_MODEL"
    "VCS"
    "SL_AIB_GEN1"
    "MAIB_REV1DOT1"
    "MS_AIB_BCA"
    "TIMESCALE_EN"
    "BEHAVIORAL"
    "MAIB_PIN96"
    "ALTR_HPS_INTEL_MACROS_OFF"
    "SIM_DIR=\"${SIM_DIR}\""
} [get_filesets sim_1]

# For defines that need values (like paths):
#set_property verilog_define "SIM_DIR=\"${SIM_DIR}\"" [get_filesets sim_1]

# 3. Verify the macros are set correctly
puts "Current simulation defines: [get_property verilog_define [get_filesets sim_1]]"

# 4. Set top module
set_property top top_tb [get_filesets sim_1]

puts "Current top: [get_property top [get_filesets sim_1]]"

# 5. Configure simulation settings before launch
set_property -name {xsim.simulate.runtime} -value {1000ns} -objects [get_filesets sim_1]
set_property -name {xsim.simulate.log_all_signals} -value {true} -objects [get_filesets sim_1]

# Compile first
#compile_simulation -simulator xsim -simset [get_filesets sim_1]

# Then elaborate
#elaborate_simulation -simulator xsim -simset [get_filesets sim_1]

# Finally launch with specific options
launch_simulation -simset [get_filesets sim_1] \
    -mode behavioral \
    -absolute_path \
    -install_path $::env(XILINX_VIVADO)