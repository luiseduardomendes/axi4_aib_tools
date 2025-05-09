// SPDX-License-Identifier: Apache-2.0
// Copyright (C) 2021 Intel Corporation.
/////////////////////////////////////////////////////////////////////////////////////////
//--------------------------------------------------------------------------------------
// Description: AXIMM AIB top
//
//
// Change log
// 
/////////////////////////////////////////////////////////////////////////////////////////
`timescale 1ps/1ps

module aximm_aib_top#(
	parameter DATAWIDTH = 40, 
	parameter ADDRWIDTH = 32, 
	parameter DWIDTH = 128
)(
	input 			i_w_m_wr_rst_n,
	input 			i_w_s_wr_rst_n,
	input [1:0]		lane_clk_a,	
	input [1:0]		lane_clk_b,
	input			rst_phy_n,
	input			clk_phy,
	input			clk_p_div2,
	input			clk_p_div4,
	
	input 			ms_wr_clk,
	input 			ms_rd_clk,
	input 			ms_fwd_clk,
	
	input			sl_wr_clk,
	input			sl_rd_clk,
	input			sl_fwd_clk,

	output 			tx_online,
	output 			rx_online,
	output [1:0]	test_done,
					
	input  [31:0] 	i_wr_addr, 
	input  [31:0] 	i_wrdata, 
	input 			i_wren, 
	input 			i_rden,
	output			o_master_readdatavalid,
	output [31:0] 	o_master_readdata,	
	output 			o_master_waitrequest,
	
	input 			avmm_clk, 
	input 			osc_clk
	
);

parameter TOTAL_CHNL_NUM = 24;

wire [0:0]    			s1_ms_rx_transfer_en;
wire [0:0]    			s1_ms_tx_transfer_en;
wire [0:0]    			s1_sl_rx_transfer_en;
wire [0:0]    			s1_sl_tx_transfer_en;
wire [0:0]    			m1_ms_tx_transfer_en;
wire [0:0]    			m1_ms_rx_transfer_en;
wire [0:0]    			m1_sl_tx_transfer_en;
wire [0:0]    			m1_sl_rx_transfer_en;

wire [DATAWIDTH*8-1:0]		data_in_f;
wire [DATAWIDTH*8-1:0]		data_out_f;
wire [DATAWIDTH*2-1:0]   	gen1_data_in_f;
wire [DATAWIDTH*2-1:0]   	gen1_data_out_f;
wire 						por_out;
wire [DATAWIDTH*2-1:0]   	data_in;
wire [DATAWIDTH*2-1:0]   	data_out;
wire [0 : 0]			w_m1_m_fs_rcv_clk;
wire [0 : 0]			w_m1_m_fs_fwd_clk;
wire [0 : 0]			w_s1_m_fs_fwd_clk;

wire 						slave_align_err;
wire 						slave_align_done ;
wire 						master_align_done;


wire [79:0]			w_tx_dout_L_ca2phy;
wire [79:0]			w_tx_dout_F_ca2phy;
wire [79:0]			w_rx_din_L_phy2ca;
wire [79:0]			w_rx_din_F_phy2ca;
wire [31:0]			 		delay_x_value;
wire [31:0]			 		delay_y_value;
wire [31:0]			 		delay_z_value;

wire [7:0] 			  		w_axi_rw_length;
wire [1:0] 			  		w_axi_rw_burst;
wire [2:0] 			  		w_axi_rw_size;
wire [ADDRWIDTH-1:0] 				w_axi_rw_addr;
wire						w_axi_wr;
wire                    			w_axi_rd;
wire 						usermode_en;
wire [   3:   0]   				w_user_arid          ;
wire [   2:   0]   				w_user_arsize        ;
wire [   7:   0]   				w_user_arlen         ;
wire [   1:   0]   				w_user_arburst       ;
wire [  31:   0]   				w_user_araddr        ;
wire               				w_user_arvalid       ;
wire               				w_user_arready       ;

// aw channel
wire [   3:   0]   				w_user_awid           ;
wire [   2:   0]   				w_user_awsize         ;
wire [   7:   0]   				w_user_awlen          ;
wire [   1:   0]   				w_user_awburst        ;
wire [  31:   0]   				w_user_awaddr         ;
wire               				w_user_awvalid        ;
wire               				w_user_awready        ;
					
// w channel						
wire [   3:   0]   				w_user_wid            ;
wire [ 	63:   0]   		w_user_wdata          ;
wire [  15:   0]   				w_user_wstrb          ;
wire               				w_user_wlast          ;
wire               				w_user_wvalid         ;
wire               				w_user_wready         ;
	
// r channel	
wire [   3:   0]   				w_user_rid            ;
wire [ 	63:   0]			w_user_rdata          ;
wire               				w_user_rlast          ;
wire [   1:   0]   				w_user_rresp          ;
wire               				w_user_rvalid         ;
wire               				w_user_rready         ;

// b channel
wire [   3:   0]   				w_user_bid            ;
wire [   1:   0]   				w_user_bresp          ;
wire               				w_user_bvalid         ;
wire               				w_user_bready         ;

wire [3:0]					w_F_user_arid  	;
wire [2:0]					w_F_user_arsize ;
wire [7:0]					w_F_user_arlen  ;
wire [1:0]					w_F_user_arburst;
wire [31:0]					w_F_user_araddr ;
wire 						w_F_user_arvalid;
wire 						w_F_user_arready;
wire [3:0]					w_F_user_awid   ;
wire [2:0]					w_F_user_awsize ;
wire [7:0]					w_F_user_awlen  ;
wire [1:0]					w_F_user_awburst ;
wire [31:0]					w_F_user_awaddr ;
wire 						w_F_user_awvalid ;
wire 						w_F_user_awready ;
wire [3:0]					w_F_user_wid    ;
wire [63:0]					w_F_user_wdata  ;
wire [15:0]					w_F_user_wstrb  ;
wire 						w_F_user_wlast  ;
wire 						w_F_user_wvalid ;
wire 						w_F_user_wready ;
wire [3:0]					w_F_user_rid    ;
wire [63:0]					w_F_user_rdata  ;
wire 						w_F_user_rlast  ;
wire [1:0]					w_F_user_rresp  ;
wire 						w_F_user_rvalid ;
wire 						w_F_user_rready ;
wire [3:0]					w_F_user_bid    ;
wire [1:0]					w_F_user_bresp  ;
wire 						w_F_user_bvalid ;
wire 						w_F_user_bready ;

wire [7:0]					w_mem_wr_addr;
wire [7:0]					w_mem_rd_addr;
wire [63:0]			w_mem_wr_data;
wire [63:0]			w_mem_rd_data;
wire 						w_mem_wr_en  ;
wire 						w_patgen_data_wr ;
wire 						w_read_complete ;
wire 						w_write_complete ;
wire [63:0]			w_patgen_exp_dout;
wire [1:0]					chkr_out;
wire 						master_align_err;
wire [63:0]			w_data_out_first;
wire 						w_data_out_first_valid;
wire [63:0]			w_data_out_last;
wire 						w_data_out_last_valid;
wire [63:0]			w_data_in_first;
wire 						w_data_in_first_valid;
wire [63:0]			w_data_in_last;
wire 						w_data_in_last_valid;
wire						master_sl_tx_transfer_en;     
wire						master_ms_tx_transfer_en;     
wire						slave_sl_tx_transfer_en;     
wire						slave_ms_tx_transfer_en;     
wire						mgmtclk_reset_n;
wire [1:0]					patchkr_out;

wire [DATAWIDTH-1:0]        s1_iopad_ch0_aib;
wire [DATAWIDTH-1:0]        s1_iopad_ch1_aib;
wire [DATAWIDTH-1:0]        s1_iopad_ch2_aib;
wire [DATAWIDTH-1:0]        s1_iopad_ch3_aib;
wire [DATAWIDTH-1:0]        s1_iopad_ch4_aib;
wire [DATAWIDTH-1:0]        s1_iopad_ch5_aib;
wire [DATAWIDTH-1:0]        s1_iopad_ch6_aib;
wire [DATAWIDTH-1:0]        s1_iopad_ch7_aib;
wire [DATAWIDTH-1:0]        s1_iopad_ch8_aib;
wire [DATAWIDTH-1:0]        s1_iopad_ch9_aib;
wire [DATAWIDTH-1:0]        s1_iopad_ch10_aib;
wire [DATAWIDTH-1:0]        s1_iopad_ch11_aib;
wire [DATAWIDTH-1:0]        s1_iopad_ch12_aib;
wire [DATAWIDTH-1:0]        s1_iopad_ch13_aib;
wire [DATAWIDTH-1:0]        s1_iopad_ch14_aib;
wire [DATAWIDTH-1:0]        s1_iopad_ch15_aib;
wire [DATAWIDTH-1:0]        s1_iopad_ch16_aib;
wire [DATAWIDTH-1:0]        s1_iopad_ch17_aib;
wire [DATAWIDTH-1:0]        s1_iopad_ch18_aib;
wire [DATAWIDTH-1:0]        s1_iopad_ch19_aib;
wire [DATAWIDTH-1:0]        s1_iopad_ch20_aib;
wire [DATAWIDTH-1:0]        s1_iopad_ch21_aib;
wire [DATAWIDTH-1:0]        s1_iopad_ch22_aib;
wire [DATAWIDTH-1:0]        s1_iopad_ch23_aib;


// Avalon MM Interface instantiation ------------------------------------------------------
avalon_mm_if #(.AVMM_WIDTH(32), .BYTE_WIDTH(4)) avmm_if_m1  (.clk(avmm_clk));
avalon_mm_if #(.AVMM_WIDTH(32), .BYTE_WIDTH(4)) avmm_if_s1  (.clk(avmm_clk));
//-----------------------------------------------------------------------------------------

// Mac Interface instantiation ------------------------------------------------------------
dut_if_mac #(.DWIDTH (40)) intf_m1 (.wr_clk(ms_wr_clk), .rd_clk(ms_rd_clk), .fwd_clk(ms_fwd_clk), .osc_clk(osc_clk));
dut_if_mac #(.DWIDTH (40)) intf_s1 (.wr_clk(sl_wr_clk), .rd_clk(sl_rd_clk), .fwd_clk(sl_fwd_clk), .osc_clk(osc_clk));
//-----------------------------------------------------------------------------------------

assign w_rx_din_F_phy2ca[79:0]  	    = intf_s1.gen1_data_out_f[79:0];
assign w_rx_din_L_phy2ca[79:0] 	  		= intf_s1.gen1_data_out_f[79:0];
assign gen1_data_in_f[(DATAWIDTH*2*1)-1 : (DATAWIDTH*2*0)] = w_tx_dout_F_ca2phy[79 : 0];

assign data_in	= 'b0;

assign data_in_f[(DATAWIDTH*8)-1:0] = 	{240'b0,w_tx_dout_L_ca2phy[(DATAWIDTH*2)-1 :0]};

assign tx_online = &{master_sl_tx_transfer_en,master_ms_tx_transfer_en,slave_sl_tx_transfer_en,slave_ms_tx_transfer_en} ;
assign rx_online = master_align_done & slave_align_done;


top_aib aib_model_inst(
	  .iopad_aib_ch0(s1_iopad_ch0_aib),
	
    .data_in_f(intf_s1.gen1_data_in_f),
    .data_out_f(intf_s1.gen1_data_out_f),
    .m_wr_clk(intf_s1.m_wr_clk),
    .m_fs_rcv_clk(),
    .m_rd_clk(intf_s1.m_rd_clk),

    .m_ns_fwd_clk(intf_s1.m_ns_fwd_clk),    

    .m_fs_fwd_clk(intf_s1.m_fs_fwd_clk),

    .fs_mac_rdy(intf_s1.fs_mac_rdy),
    .ns_mac_rdy(intf_s1.ns_mac_rdy),
    .fs_adapter_rstn(intf_s1.fs_adapter_rstn),
    .ns_adapter_rstn(intf_s1.ns_adapter_rstn),
    .config_done(intf_s1.i_conf_done),
    .m_rx_align_done(intf_s1.m_rx_align_done),

    .sl_rx_dcc_dll_lock_req(intf_s1.sl_rx_dcc_dll_lock_req),
    .sl_tx_dcc_dll_lock_req(intf_s1.sl_tx_dcc_dll_lock_req),

    .ms_tx_transfer_en(intf_s1.ms_tx_transfer_en),
    .sl_tx_transfer_en(intf_s1.sl_tx_transfer_en)

);


axi_top aximm_inst(
  .lane_clk_a		 	(lane_clk_a),  
  .lane_clk_b		 	(lane_clk_b),
  .L_clk_wr             (ms_wr_clk),
  .L_rst_wr_n           (i_w_m_wr_rst_n),
  .por_in		 		(por_out),
  .usermode_en		 	(usermode_en), 
  .init_ar_credit       (8'h00),
  .init_aw_credit       (8'h00),
  .init_w_credit        (8'h00),
  .L_user_arid          (w_user_arid   ),
  .L_user_arsize        (w_user_arsize ),
  .L_user_arlen         (w_user_arlen  ),
  .L_user_arburst       (w_user_arburst),
  .L_user_araddr        (w_user_araddr ),
  .L_user_arvalid       (w_user_arvalid),
  .L_user_arready       (w_user_arready),
  .L_user_awid          (w_user_awid   ),
  .L_user_awsize        (w_user_awsize ),
  .L_user_awlen         (w_user_awlen  ),
  .L_user_awburst       (w_user_awburst),
  .L_user_awaddr        (w_user_awaddr ),
  .L_user_awvalid       (w_user_awvalid),
  .L_user_awready       (w_user_awready),
  .L_user_wid           (w_user_wid   ),
  .L_user_wdata         (w_user_wdata ),
  .L_user_wstrb         (w_user_wstrb ),
  .L_user_wlast         (w_user_wlast ),
  .L_user_wvalid        (w_user_wvalid),
  .L_user_wready        (w_user_wready),
  .L_user_rid           (w_user_rid     ),
  .L_user_rdata         (w_user_rdata   ),
  .L_user_rlast         (w_user_rlast   ),
  .L_user_rresp         (w_user_rresp   ),
  .L_user_rvalid        (w_user_rvalid  ),
  .L_user_rready        (w_user_rready  ),
  .L_user_bid           (w_user_bid    ),
  .L_user_bresp         (w_user_bresp  ),
  .L_user_bvalid        (w_user_bvalid ),
  .L_user_bready        (w_user_bready ),
  .tx_ar_debug_status  	(),
  .tx_aw_debug_status  	(),
  .tx_w_debug_status   	(),
  .rx_r_debug_status   	(),
  .rx_b_debug_status   	(),
  .l_gen_mode         	(1'b0),
  .f_gen_mode         	(1'b0),

  .i_delay_x_value	 	(delay_x_value),
  .i_delay_y_value	 	(delay_y_value),
  .i_delay_z_value	 	(delay_z_value),
  
  .F_clk_wr              (sl_wr_clk),
  .F_rst_wr_n            (i_w_s_wr_rst_n),

  // Control signals
  .init_r_credit        (8'h00),
  .init_b_credit        (8'h00),
  .F_user_arid          (w_F_user_arid    ),
  .F_user_arsize        (w_F_user_arsize  ),
  .F_user_arlen         (w_F_user_arlen   ),
  .F_user_arburst       (w_F_user_arburst ),
  .F_user_araddr        (w_F_user_araddr  ),
  .F_user_arvalid       (w_F_user_arvalid ),
  .F_user_arready       (w_F_user_arready),
  .F_user_awid          (w_F_user_awid   ),
  .F_user_awsize        (w_F_user_awsize ),
  .F_user_awlen         (w_F_user_awlen  ),
  .F_user_awburst       (w_F_user_awburst),
  .F_user_awaddr        (w_F_user_awaddr ),
  .F_user_awvalid       (w_F_user_awvalid),
  .F_user_awready       (w_F_user_awready),
  .F_user_wid           (w_F_user_wid   ),
  .F_user_wdata         (w_F_user_wdata ),
  .F_user_wstrb         (w_F_user_wstrb ),
  .F_user_wlast         (w_F_user_wlast ),
  .F_user_wvalid        (w_F_user_wvalid),
  .F_user_wready        (w_F_user_wready),
  .F_user_rid           (w_F_user_rid   ),
  .F_user_rdata         (w_F_user_rdata ),
  .F_user_rlast         (w_F_user_rlast ),
  .F_user_rresp         (w_F_user_rresp ),
  .F_user_rvalid        (w_F_user_rvalid),
  .F_user_rready        (w_F_user_rready),
  .F_user_bid           (w_F_user_bid   ),
  .F_user_bresp         (w_F_user_bresp ),
  .F_user_bvalid        (w_F_user_bvalid),
  .F_user_bready        (w_F_user_bready), 
  .master_sl_tx_transfer_en(m1_sl_tx_transfer_en[1:0]),
  .master_ms_tx_transfer_en(m1_ms_tx_transfer_en[1:0]),
  .slave_ms_tx_transfer_en(s1_ms_tx_transfer_en[1:0]),
  .slave_sl_tx_transfer_en(s1_sl_tx_transfer_en[1:0]),
  
  
  .tx_dout_L_ca2phy     (w_tx_dout_L_ca2phy),//connect
  .tx_dout_F_ca2phy     (w_tx_dout_F_ca2phy),
  .rx_din_L_phy2ca	 	(w_rx_din_L_phy2ca),
  .rx_din_F_phy2ca	 	(w_rx_din_F_phy2ca),//connect
  
  
  .ca_L_align_done	 	(master_align_done),
  .ca_L_align_error     (master_align_err),  
  .ca_F_align_done	 	(slave_align_done),                 
  .ca_F_align_error	 	(slave_align_err)
);

endmodule
