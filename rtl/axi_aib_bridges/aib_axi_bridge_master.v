// Description: AIB to AXI Bridge Master
/*
    * Single AXI Channel (No Channel Alignment needed)
    * 1 AXI MM Lite Slave
    * 1 AIB Gen2 PHY
*/

/*
    Macros:
    * NBR_BUMPS: Number of bumps in the AIB
    * NBR_LANES: Number of lanes in the AIB
    * NBR_PHASES: Number of phases in the AIB
    * NBR_CHNLS: Number of channels in the AIB
*/

supply1 HI;  // Global logic '1' (connects to vdd)
supply0 LO;  // Global logic '0' (connects to gnd)

`include "../interfaces/axi_if.v"


module top_aib_axi_bridge_master #(
    parameter ACTIVE_CHNLS = 1,
    parameter NBR_CHNLS = 24,       // Total number of channels 
    parameter NBR_BUMPS = 102,      // Number of BUMPs
    parameter NBR_PHASES = 4,       // Number of phases
    parameter NBR_LANES = 40,       // Number of lanes
    parameter MS_SSR_LEN = 81,      // Data size for leader side band
    parameter SL_SSR_LEN = 73,      // Data size for follower side band
    parameter DWIDTH = 40,
    parameter AXI_CHNL_NUM = 1,     // Number of AXI channels
    parameter ADDRWIDTH = 32,       // Address width
    parameter GEN2_MODE = 1'b1  
) (

    // **********************************************************************
    // ********************* EMIB interface *********************************
    // **********************************************************************
        inout vddc1,  // vddc1 power supply pin (low noise for clock circuits)
        inout vddc2,  // vddc2 power supply pin for IOs circuits
        inout vddtx,  // vddtx power supply pin for high-speed data
        inout vss,    // Ground

        inout   [NBR_BUMPS-1:0] iopad_ch0_aib,   // IO pad channel 00
        inout   [NBR_BUMPS-1:0] iopad_ch1_aib,   // IO pad channel 01
        inout   [NBR_BUMPS-1:0] iopad_ch2_aib,   // IO pad channel 02
        inout   [NBR_BUMPS-1:0] iopad_ch3_aib,   // IO pad channel 03
        inout   [NBR_BUMPS-1:0] iopad_ch4_aib,   // IO pad channel 04
        inout   [NBR_BUMPS-1:0] iopad_ch5_aib,   // IO pad channel 05
        inout   [NBR_BUMPS-1:0] iopad_ch6_aib,   // IO pad channel 06
        inout   [NBR_BUMPS-1:0] iopad_ch7_aib,   // IO pad channel 07
        inout   [NBR_BUMPS-1:0] iopad_ch8_aib,   // IO pad channel 08
        inout   [NBR_BUMPS-1:0] iopad_ch9_aib,   // IO pad channel 09
        inout   [NBR_BUMPS-1:0] iopad_ch10_aib,  // IO pad channel 10
        inout   [NBR_BUMPS-1:0] iopad_ch11_aib,  // IO pad channel 11
        inout   [NBR_BUMPS-1:0] iopad_ch12_aib,  // IO pad channel 12
        inout   [NBR_BUMPS-1:0] iopad_ch13_aib,  // IO pad channel 13
        inout   [NBR_BUMPS-1:0] iopad_ch14_aib,  // IO pad channel 14
        inout   [NBR_BUMPS-1:0] iopad_ch15_aib,  // IO pad channel 15
        inout   [NBR_BUMPS-1:0] iopad_ch16_aib,  // IO pad channel 16
        inout   [NBR_BUMPS-1:0] iopad_ch17_aib,  // IO pad channel 17
        inout   [NBR_BUMPS-1:0] iopad_ch18_aib,  // IO pad channel 18
        inout   [NBR_BUMPS-1:0] iopad_ch19_aib,  // IO pad channel 19
        inout   [NBR_BUMPS-1:0] iopad_ch20_aib,  // IO pad channel 20
        inout   [NBR_BUMPS-1:0] iopad_ch21_aib,  // IO pad channel 21
        inout   [NBR_BUMPS-1:0] iopad_ch22_aib,  // IO pad channel 22
        inout   [NBR_BUMPS-1:0] iopad_ch23_aib,  // IO pad channel 23

        inout  iopad_device_detect,  // Indicates the presence of a valid leader
        inout  iopad_power_on_reset, // Perfoms a power-on-reset in the adapter
    // *************************************************************************
    
    // *************************************************************************
    // ************************ pins aib_phy_top *******************************

        // ************ clock signals**************
            input                   i_osc_clk,    // Free running oscillator clock for leader interface
            input                   avmm_clk,     // Avalon MM clock
            input                   avmm_rst_n,   // Avalon MM reset 
            
            input                   m_wr_clk,     // USER DEFINED
            input                   m_rd_clk,     // USER DEFINED
            input                   m_fwd_clk,      
        // ****************************************
    // *************************************************************************

    // *************************************************************************
    // *************************** pins AXI-MM *********************************
    // *************************************************************************
        // ************ clock signals **************
            input                 clk_wr              ,
            input                 rst_wr_n            ,
            
            input                 clk_rd              ,
            input                 rst_rd_n            ,
        // *****************************************
          
        // ********** Control signals **************
          
            input   [7:0]         init_ar_credit      ,
            input   [7:0]         init_aw_credit      ,
            input   [7:0]         init_w_credit       ,
        // *****************************************
          
        // ************* axi channel ***************
            axi_if.slave          user_axi_if,       
        // *****************************************
          
        // ************* Configuration *************          
            input   [15:0]        delay_x_value       ,
            input   [15:0]        delay_y_value       ,
            input   [15:0]        delay_z_value       
        // *****************************************
    // *************************************************************************
);


    calib_master_fsm #(
        .TOTAL_CHNL_NUM(NBR_CHNLS),
        .ACTIVE_CHNLS(ACTIVE_CHNLS),
        .GEN2_MODE(GEN2_MODE)
    ) u_calib_fsm (
        .clk(avmm_clk),
        .rst_n(avmm_rst_n),

        .sl_tx_transfer_en(intf_m1.sl_tx_transfer_en), // Transfer enable signals from AIB
        .sl_rx_transfer_en(intf_m1.sl_rx_transfer_en), // Transfer enable signals from AIB

        //.sl_tx_transfer_en({24{1'b1}}), // Transfer enable signals from AIB
        //.sl_rx_transfer_en({24{1'b1}}), // Transfer enable signals from AIB

        .calib_done(calib_done),
        .i_conf_done(intf_m1.i_conf_done),
        .ns_adapter_rstn    (intf_m1.ns_adapter_rstn),
        .ns_mac_rdy         (intf_m1.ns_mac_rdy),
        .ms_rx_dcc_dll_lock_req (intf_m1.ms_rx_dcc_dll_lock_req),
        .ms_tx_dcc_dll_lock_req (intf_m1.ms_tx_dcc_dll_lock_req), 
        
        .avmm_address_o(avmm_if_m1.address),
        .avmm_read_o(avmm_if_m1.read),
        .avmm_write_o(avmm_if_m1.write),
        .avmm_writedata_o(avmm_if_m1.writedata),
        .avmm_byteenable_o(avmm_if_m1.byteenable),
        .avmm_readdata_i(avmm_if_m1.readdata),      // Input, not used by current write-only sequencer
        .avmm_readdatavalid_i(avmm_if_m1.readdatavalid), // Input, not used by current write-only sequencer
        .avmm_waitrequest_i(avmm_if_m1.waitrequest)
    );
    
    dut_if_mac #(.DWIDTH (DWIDTH)) intf_m1 (
        .wr_clk(m_wr_clk), 
        .rd_clk(m_rd_clk), 
        .fwd_clk(m_fwd_clk), 
        .osc_clk(i_osc_clk)
    );

    logic [DWIDTH*NBR_CHNLS-1:0] tx_phy0;
    logic [DWIDTH*NBR_CHNLS-1:0] rx_phy0;
    logic [NBR_LANES*NBR_PHASES*2*NBR_CHNLS-1:0] data_in_f;
    logic [NBR_LANES*NBR_PHASES*2*NBR_CHNLS-1:0] data_out_f;
    logic [NBR_LANES*2*NBR_CHNLS-1:0] data_in;
    logic [NBR_LANES*2*NBR_CHNLS-1:0] data_out;

    assign rx_phy0   [79:0] = data_out_f [79:0];
    assign data_in_f [79:0] = tx_phy0    [79:0];
    assign data_in   [79:0] = tx_phy0    [79:0];

    avalon_mm_if #(.AVMM_WIDTH(32), .BYTE_WIDTH(4)) avmm_if_m1  (
     .clk    (avmm_clk)
    );

    assign avmm_if_m1.rst_n = avmm_rst_n;

    // Corrected instantiation of the aib_model_top module
aib_model_top #(
        // Assuming default parameters are acceptable.
        // If not, they can be specified here.
        // .MAX_SCAN_LEN(200),
        // .DATAWIDTH(40),
        // .TOTAL_CHNL_NUM(24)
    ) dut_master1 (
        // AIB IO Pad Connections (Channels 0-23)
        .iopad_ch0_aib (iopad_ch0_aib), 
        .iopad_ch1_aib (iopad_ch1_aib), 
        .iopad_ch2_aib (iopad_ch2_aib), 
        .iopad_ch3_aib (iopad_ch3_aib), 
        .iopad_ch4_aib (iopad_ch4_aib), 
        .iopad_ch5_aib (iopad_ch5_aib), 
        .iopad_ch6_aib (iopad_ch6_aib), 
        .iopad_ch7_aib (iopad_ch7_aib), 
        .iopad_ch8_aib (iopad_ch8_aib), 
        .iopad_ch9_aib (iopad_ch9_aib), 
        .iopad_ch10_aib(iopad_ch10_aib),
        .iopad_ch11_aib(iopad_ch11_aib),
        .iopad_ch12_aib(iopad_ch12_aib),
        .iopad_ch13_aib(iopad_ch13_aib),
        .iopad_ch14_aib(iopad_ch14_aib),
        .iopad_ch15_aib(iopad_ch15_aib),
        .iopad_ch16_aib(iopad_ch16_aib),
        .iopad_ch17_aib(iopad_ch17_aib),
        .iopad_ch18_aib(iopad_ch18_aib),
        .iopad_ch19_aib(iopad_ch19_aib),
        .iopad_ch20_aib(iopad_ch20_aib),
        .iopad_ch21_aib(iopad_ch21_aib),
        .iopad_ch22_aib(iopad_ch22_aib),
        .iopad_ch23_aib(iopad_ch23_aib),
        
        // IO pads, AUX channel
        .iopad_device_detect(iopad_device_detect),
        .iopad_power_on_reset(iopad_power_on_reset),
        
        // Data Interface
        .data_in_f(data_in_f),                      
        .data_out_f(data_out_f),                     
        .data_in(data_in), 
        .data_out(data_out),                         
                
        // Clock Interface
        .m_ns_fwd_clk(intf_m1.m_ns_fwd_clk),
        .m_ns_rcv_clk(intf_m1.m_ns_rcv_clk),                         
        .m_fs_rcv_clk(intf_m1.m_fs_rcv_clk),                         
        .m_fs_fwd_clk(intf_m1.m_fs_fwd_clk),                         
        .m_wr_clk(intf_m1.m_wr_clk),                              
        .m_rd_clk(intf_m1.m_rd_clk),
        .tclk_phy(), // This output was missing in the original instantiation

        // Control and Status Signals
        .ns_adapter_rstn(intf_m1.ns_adapter_rstn),  
        .ns_mac_rdy(intf_m1.ns_mac_rdy),       
        .fs_mac_rdy(intf_m1.fs_mac_rdy),  
        .i_conf_done(intf_m1.i_conf_done),
        .i_osc_clk(intf_m1.osc_clk),   //Only for master mode       
        
        // Handshake and Sideband Signals
        .ms_rx_dcc_dll_lock_req(intf_m1.ms_rx_dcc_dll_lock_req), // Input to AIB
        .ms_tx_dcc_dll_lock_req(intf_m1.ms_tx_dcc_dll_lock_req), // Input to AIB
        .sl_tx_dcc_dll_lock_req({24{1'b1}}), // Input to AIB, tied off
        .sl_rx_dcc_dll_lock_req({24{1'b1}}), // Input to AIB, tied off
        .ms_tx_transfer_en(intf_m1.ms_tx_transfer_en), // Output from AIB
        .ms_rx_transfer_en(intf_m1.ms_rx_transfer_en), // Output from AIB
        .sl_tx_transfer_en(intf_m1.sl_tx_transfer_en), // Output from AIB
        .sl_rx_transfer_en(intf_m1.sl_rx_transfer_en), // Output from AIB
        .m_rx_align_done(intf_m1.m_rx_align_done),   
        .sr_ms_tomac(intf_m1.ms_sideband),          
        .sr_sl_tomac(intf_m1.sl_sideband),           
        
        // Mode Select
        .dual_mode_select(1'b1),
        .m_gen2_mode(GEN2_MODE),

        // AVMM Interface
        .i_cfg_avmm_clk(avmm_if_m1.clk),
        .i_cfg_avmm_rst_n(avmm_if_m1.rst_n),
        .i_cfg_avmm_addr(avmm_if_m1.address),
        .i_cfg_avmm_byte_en(avmm_if_m1.byteenable),
        .i_cfg_avmm_read(avmm_if_m1.read),
        .i_cfg_avmm_write(avmm_if_m1.write),
        .i_cfg_avmm_wdata(avmm_if_m1.writedata),
        .o_cfg_avmm_rdatavld(avmm_if_m1.readdatavalid),
        .o_cfg_avmm_rdata(avmm_if_m1.readdata),
        .o_cfg_avmm_waitreq(avmm_if_m1.waitrequest),

        // Aux Channel
        .m_por_ovrd(1'b0),
        .m_device_detect_ovrd(1'b0),
        .i_m_power_on_reset(1'b0),
        .m_device_detect(intf_m1.m_device_detect), // Output from AIB
        .o_m_power_on_reset(intf_m1.o_m_power_on_reset),

        // JTAG Ports
        .i_jtag_clkdr(1'b0),
        .i_jtag_clksel(1'b0),
        .i_jtag_intest(1'b0),
        .i_jtag_mode(1'b0),
        .i_jtag_rstb(1'b1), // JTAG reset is typically active low
        .i_jtag_rstb_en(1'b0),
        .i_jtag_tdi(1'b0),
        .i_jtag_tx_scanen(1'b0),
        .i_jtag_weakpdn(1'b0),
        .i_jtag_weakpu(1'b0),
        .o_jtag_tdo(), // Unconnected output

        // ATPG Scan Ports
        .i_scan_clk(1'b0),
        .i_scan_clk_500m(1'b0),
        .i_scan_clk_1000m(1'b0),
        .i_scan_en(1'b0),
        .i_scan_mode(1'b0),
        .i_scan_din('0), // Tie all scan inputs to 0
        .i_scan_dout(), // Unconnected output

        // External Control Signals (Tied off)
        .sl_external_cntl_26_0('0),
        .sl_external_cntl_30_28('0),
        .sl_external_cntl_57_32('0),
        .ms_external_cntl_4_0('0),
        .ms_external_cntl_65_8('0)
    );


    axi_mm_master_top  aximm_leader(
        .clk_wr              (clk_wr ),
        .rst_wr_n            (rst_wr_n),
        .tx_online           (intf_m1.sl_tx_transfer_en[0] & intf_m1.ms_tx_transfer_en[0]),
        .rx_online           (intf_m1.sl_rx_transfer_en[0] & intf_m1.ms_rx_transfer_en[0]),
        .init_ar_credit      (init_ar_credit),
        .init_aw_credit      (init_aw_credit),
        .init_w_credit       (init_w_credit ),
        .tx_phy0             (tx_phy0),
        .rx_phy0             (rx_phy0),
        
        .user_arid           (user_axi_if.arid    ),
        .user_arsize         (user_axi_if.arsize  ),
        .user_arlen          (user_axi_if.arlen   ),
        .user_arburst        (user_axi_if.arburst ),
        .user_araddr         (user_axi_if.araddr  ),
        .user_arvalid        (user_axi_if.arvalid ),
        .user_arready        (user_axi_if.arready ),
        
        .user_awid           (user_axi_if.awid   ),
        .user_awsize         (user_axi_if.awsize ),
        .user_awlen          (user_axi_if.awlen  ),
        .user_awburst        (user_axi_if.awburst),
        .user_awaddr         (user_axi_if.awaddr ),
        .user_awvalid        (user_axi_if.awvalid),
        .user_awready        (user_axi_if.awready),
        
        .user_wid            (user_axi_if.wid     ),
        .user_wdata          (user_axi_if.wdata   ),
        .user_wstrb          (user_axi_if.wstrb[15:0]   ),
        .user_wlast          (user_axi_if.wlast   ),
        .user_wvalid         (user_axi_if.wvalid  ),
        .user_wready         (user_axi_if.wready  ),
        
        .user_rid            (user_axi_if.rid     ),
        .user_rdata          (user_axi_if.rdata   ),
        .user_rlast          (user_axi_if.rlast   ),
        .user_rresp          (user_axi_if.rresp   ),
        .user_rvalid         (user_axi_if.rvalid  ),
        .user_rready         (user_axi_if.rready  ),
    
        .user_bid            (user_axi_if.bid     ),
        .user_bresp          (user_axi_if.bresp   ),
        .user_bvalid         (user_axi_if.bvalid  ),
        .user_bready         (user_axi_if.bready  ),

        .m_gen2_mode         (GEN2_MODE),
        .delay_x_value       (delay_x_value),
        .delay_y_value       (delay_y_value),
        .delay_z_value       (delay_z_value)

    );
endmodule