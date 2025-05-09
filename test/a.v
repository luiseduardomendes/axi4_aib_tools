
top_aib #(.DWIDTH(DATAWIDTH), .TOTAL_CHNL_NUM(TOTAL_CHNL_NUM)) aib_model_inst(
	.avmm_clk(avmm_clk),
	.osc_clk(osc_clk),
	.m1_data_in_f(data_in_f),
    	.m1_data_out_f(data_out_f),
    	.m1_data_in(data_in), //output data to pad
    	.m1_data_out(data_out),
	.m1_m_ns_fwd_clk({TOTAL_CHNL_NUM{ms_fwd_clk}}), //output data clock
    	.m1_m_ns_rcv_clk({TOTAL_CHNL_NUM{ms_fwd_clk}}),
    	.m1_m_fs_rcv_clk(w_m1_m_fs_rcv_clk),
    	.m1_m_fs_fwd_clk(w_m1_m_fs_fwd_clk),
    	.m1_m_wr_clk({TOTAL_CHNL_NUM{ms_wr_clk}}),      // shared input AXI AIB
    	.m1_m_rd_clk({TOTAL_CHNL_NUM{ms_rd_clk}}),
	.usermode_en(usermode_en),
	.m1_ms_tx_transfer_en(m1_ms_tx_transfer_en),        // communication with AIB -> AXI 
    	.m1_ms_rx_transfer_en(m1_ms_rx_transfer_en),
    	.m1_sl_tx_transfer_en(m1_sl_tx_transfer_en),    // communication with AIB -> AXI
    	.m1_sl_rx_transfer_en(m1_sl_rx_transfer_en),
	.m1_i_osc_clk(osc_clk),   //Only for master mode
	.m1_por_out(por_out),                               // communication with AIB -> AXI
	.s1_gen1_data_in_f(gen1_data_in_f),
    	.s1_gen1_data_out_f(gen1_data_out_f),   
	.s1_m_wr_clk({TOTAL_CHNL_NUM{sl_wr_clk}}),          // shared input AXI AIB
    	.s1_m_rd_clk({TOTAL_CHNL_NUM{sl_rd_clk}}),
	.s1_m_ns_fwd_clk({TOTAL_CHNL_NUM{sl_fwd_clk}}),
	.s1_m_fs_fwd_clk(w_s1_m_fs_fwd_clk),
    	.s1_ms_rx_transfer_en(s1_ms_rx_transfer_en),
    	.s1_ms_tx_transfer_en(s1_ms_tx_transfer_en),    // communication with AIB -> AXI
    	.s1_sl_rx_transfer_en(s1_sl_rx_transfer_en),
    	.s1_sl_tx_transfer_en(s1_sl_tx_transfer_en)     // communication with AIB -> AXI

);


aximm_d128_h2h_wrapper_top #(.AXI_CHNL_NUM(AXI_CHNL_NUM),
                             .SYNC_FIFO(SYNC_FIFO)
 ) aximm_inst(
  .lane_clk_a		 (lane_clk_a),  
  .lane_clk_b		 (lane_clk_b),
  .L_clk_wr              (ms_wr_clk),
  .L_rst_wr_n            (i_w_m_wr_rst_n),
  .por_in		 (por_out),                             // communication with AIB -> AXI 
  .usermode_en		 (usermode_en), 
  .init_ar_credit        (8'h00),
  .init_aw_credit        (8'h00),
  .init_w_credit         (8'h00),
  .L_user_arid           (w_user_arid   ),
  .L_user_arsize         (w_user_arsize ),
  .L_user_arlen          (w_user_arlen  ),
  .L_user_arburst        (w_user_arburst),
  .L_user_araddr         (w_user_araddr ),
  .L_user_arvalid        (w_user_arvalid),
  .L_user_arready        (w_user_arready),
  .L_user_awid           (w_user_awid   ),
  .L_user_awsize         (w_user_awsize ),
  .L_user_awlen          (w_user_awlen  ),
  .L_user_awburst        (w_user_awburst),
  .L_user_awaddr         (w_user_awaddr ),
  .L_user_awvalid        (w_user_awvalid),
  .L_user_awready        (w_user_awready),
  .L_user_wid            (w_user_wid   ),
  .L_user_wdata          (w_user_wdata ),
  .L_user_wstrb          (w_user_wstrb ),
  .L_user_wlast          (w_user_wlast ),
  .L_user_wvalid         (w_user_wvalid),
  .L_user_wready         (w_user_wready),
  .L_user_rid            (w_user_rid     ),
  .L_user_rdata          (w_user_rdata   ),
  .L_user_rlast          (w_user_rlast   ),
  .L_user_rresp          (w_user_rresp   ),
  .L_user_rvalid         (w_user_rvalid  ),
  .L_user_rready         (w_user_rready  ),
  .L_user_bid            (w_user_bid    ),
  .L_user_bresp          (w_user_bresp  ),
  .L_user_bvalid         (w_user_bvalid ),
  .L_user_bready         (w_user_bready ),
  .tx_ar_debug_status  	 (),
  .tx_aw_debug_status  	 (),
  .tx_w_debug_status   	 (),
  .rx_r_debug_status   	 (),
  .rx_b_debug_status   	 (),
  .l_gen_mode         	 (1'b0),
  .f_gen_mode         	 (1'b0),

  .i_delay_x_value	 (delay_x_value),
  .i_delay_y_value	 (delay_y_value),
  .i_delay_z_value	 (delay_z_value),
  
  .F_clk_wr              (sl_wr_clk),
  .F_rst_wr_n            (i_w_s_wr_rst_n),

  // Control signals
  
  .init_r_credit         (8'h00),
  .init_b_credit         (8'h00),
  .F_user_arid           (w_F_user_arid    ),
  .F_user_arsize         (w_F_user_arsize  ),
  .F_user_arlen          (w_F_user_arlen   ),
  .F_user_arburst        (w_F_user_arburst ),
  .F_user_araddr         (w_F_user_araddr  ),
  .F_user_arvalid        (w_F_user_arvalid ),
  .F_user_arready        (w_F_user_arready),
  .F_user_awid           (w_F_user_awid   ),
  .F_user_awsize         (w_F_user_awsize ),
  .F_user_awlen          (w_F_user_awlen  ),
  .F_user_awburst        (w_F_user_awburst),
  .F_user_awaddr         (w_F_user_awaddr ),
  .F_user_awvalid        (w_F_user_awvalid),
  .F_user_awready        (w_F_user_awready),
  .F_user_wid            (w_F_user_wid   ),
  .F_user_wdata          (w_F_user_wdata ),
  .F_user_wstrb          (w_F_user_wstrb ),
  .F_user_wlast          (w_F_user_wlast ),
  .F_user_wvalid         (w_F_user_wvalid),
  .F_user_wready         (w_F_user_wready),
  .F_user_rid            (w_F_user_rid   ),
  .F_user_rdata          (w_F_user_rdata ),
  .F_user_rlast          (w_F_user_rlast ),
  .F_user_rresp          (w_F_user_rresp ),
  .F_user_rvalid         (w_F_user_rvalid),
  .F_user_rready         (w_F_user_rready),
  .F_user_bid            (w_F_user_bid   ),
  .F_user_bresp          (w_F_user_bresp ),
  .F_user_bvalid         (w_F_user_bvalid),
  .F_user_bready         (w_F_user_bready), 
  .master_sl_tx_transfer_en(m1_sl_tx_transfer_en[1:0]),     // communication with AIB -> AXI 
  .master_ms_tx_transfer_en(m1_ms_tx_transfer_en[1:0]),     // communication with AIB -> AXI 
  .slave_ms_tx_transfer_en(s1_ms_tx_transfer_en[1:0]),      // communication with AIB -> AXI 
  .slave_sl_tx_transfer_en(s1_sl_tx_transfer_en[1:0]),      // communication with AIB -> AXI 
  .tx_dout_L_ca2phy      (w_tx_dout_L_ca2phy),//connect
  .tx_dout_F_ca2phy      (w_tx_dout_F_ca2phy),
  .rx_din_L_phy2ca	 (w_rx_din_L_phy2ca),
  .rx_din_F_phy2ca	 (w_rx_din_F_phy2ca),//connect
  .ca_L_align_done	 (master_align_done),
  .ca_L_align_error      (master_align_err),  
  .ca_F_align_done	 (slave_align_done),                 
  .ca_F_align_error	 (slave_align_err)
);