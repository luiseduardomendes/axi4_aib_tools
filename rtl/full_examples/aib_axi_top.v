`include "../interfaces/axi_if.v"

module aib_axi_top #(
    parameter NBR_CHNLS = 24,       // Total number of channels 
    parameter NBR_BUMPS = 102,      // Number of BUMPs
    parameter NBR_PHASES = 4,       // Number of phases
    parameter NBR_LANES = 40,       // Number of lanes
    parameter MS_SSR_LEN = 81,      // Data size for leader side band
    parameter SL_SSR_LEN = 73,      // Data size for follower side band
    parameter DWIDTH = 40            // Data width (added since it was used in data_out_f)
) (
    // Power pins
    inout vddc1,
    inout vddc2,
    inout vddtx,
    inout vss,

    // AXI Master Interface
    input                 m_clk_wr,
    input                 m_rst_wr_n,
    input                 m_clk_rd,
    input                 m_rst_rd_n,
    //input                 m_tx_online,
    //input                 m_rx_online,
    input   [7:0]         m_init_ar_credit,
    input   [7:0]         m_init_aw_credit,
    input   [7:0]         m_init_w_credit,

    axi_if.slave          m_user_axi_if,

    output  [31:0]        m_tx_ar_debug_status,
    output  [31:0]        m_tx_aw_debug_status,
    output  [31:0]        m_tx_w_debug_status,
    output  [31:0]        m_rx_r_debug_status,
    output  [31:0]        m_rx_b_debug_status,

    input   [15:0]        m_delay_x_value,
    input   [15:0]        m_delay_y_value,
    input   [15:0]        m_delay_z_value,

    input                 m_avmm_clk,
    input                 m_avmm_rst_n,
    input   [31:0]        m_i_cfg_avmm_addr,
    input   [3:0]         m_i_cfg_avmm_byte_en,
    input                 m_i_cfg_avmm_read,
    input                 m_i_cfg_avmm_write,
    input   [31:0]        m_i_cfg_avmm_wdata,
    output                m_o_cfg_avmm_rdatavld,
    output  [31:0]        m_o_cfg_avmm_rdata,
    output                m_o_cfg_avmm_waitreq,

    input [NBR_CHNLS-1:0] m_ns_fwd_clk,
    input [NBR_CHNLS-1:0] m_ns_rcv_clk,

    input [NBR_CHNLS-1:0] s_ns_fwd_clk,
    input [NBR_CHNLS-1:0] s_ns_rcv_clk,

    input [NBR_CHNLS-1:0] m_ns_mac_rdy,
    input [NBR_CHNLS-1:0] m_fs_mac_rdy,

    input [NBR_CHNLS-1:0] m_ms_rx_dcc_dll_lock_req,
    input [NBR_CHNLS-1:0] m_ms_tx_dcc_dll_lock_req,

    // AXI Slave Interface
    input                 s_clk_wr,
    input                 s_rst_wr_n,
    input                 s_clk_rd,
    input                 s_rst_rd_n,
    
    //input                 s_tx_online,
    //input                 s_rx_online,

    input   [7:0]         s_init_r_credit,
    input   [7:0]         s_init_b_credit,

    axi_if.master         s_user_axi_if,

    output  [31:0]        s_rx_ar_debug_status,
    output  [31:0]        s_rx_aw_debug_status,
    output  [31:0]        s_rx_w_debug_status,
    output  [31:0]        s_tx_r_debug_status,
    output  [31:0]        s_tx_b_debug_status,

    input   [15:0]        s_delay_x_value,
    input   [15:0]        s_delay_y_value,
    input   [15:0]        s_delay_z_value,

    input                 s_avmm_clk,
    input                 s_avmm_rst_n,
    input   [31:0]        s_i_cfg_avmm_addr,
    input   [3:0]         s_i_cfg_avmm_byte_en,
    input                 s_i_cfg_avmm_read,
    input                 s_i_cfg_avmm_write,
    input   [31:0]        s_i_cfg_avmm_wdata,
    output                s_o_cfg_avmm_rdatavld,
    output  [31:0]        s_o_cfg_avmm_rdata,
    output                s_o_cfg_avmm_waitreq,

    // Common AIB signals
    input                   i_osc_clk,
    output                   i_conf_done
    //inout                   iopad_device_detect,
    //inout                   iopad_power_on_reset
);

    // AIB Master signals
    wire [NBR_CHNLS-1:0]  m_fs_rcv_clk;
    wire [NBR_CHNLS-1:0]  m_fs_fwd_clk;
    //wire [NBR_CHNLS-1:0]  m_wr_clk;
    //wire [NBR_CHNLS-1:0]  m_rd_clk;
    wire [NBR_CHNLS-1:0]  m_fwd_clk;
    //wire [NBR_LANES*NBR_PHASES*2*NBR_CHNLS-1:0]  m_data_in_f;
    wire [NBR_LANES*2*NBR_CHNLS-1:0]             m_data_in;
    //wire [NBR_CHNLS*DWIDTH*8-1:0]                 m_data_out_f;
    wire [NBR_CHNLS*DWIDTH*2-1:0]                 m_data_out;
    wire [NBR_CHNLS-1:0]  m_ns_adapter_rstn;

    
    wire iopad_device_detect;
    wire iopad_power_on_reset;
    
    wire [NBR_CHNLS-1:0]  m_sl_tx_dcc_dll_lock_req; // should be calibration init
    wire [NBR_CHNLS-1:0]  m_sl_rx_dcc_dll_lock_req; // should be calibration init
    wire [MS_SSR_LEN*NBR_CHNLS-1:0] m_sr_ms_tomac;
    wire [SL_SSR_LEN*NBR_CHNLS-1:0] m_sr_sl_tomac;
    wire [NBR_CHNLS-1:0]  m_rx_align_done;

    // AIB Slave signals
    wire [NBR_CHNLS-1:0]  s_fs_rcv_clk;
    wire [NBR_CHNLS-1:0]  s_fs_fwd_clk;
    
    wire [NBR_CHNLS-1:0]  s_wr_clk;
    wire [NBR_CHNLS-1:0]  s_rd_clk;
    wire [NBR_CHNLS-1:0]  s_fwd_clk;
    //wire [NBR_LANES*NBR_PHASES*2*NBR_CHNLS-1:0]  s_data_in_f;
    //wire [NBR_LANES*2*NBR_CHNLS-1:0]             s_data_in;
    //wire [NBR_CHNLS*DWIDTH*8-1:0]                 s_data_out_f;
    //wire [NBR_CHNLS*DWIDTH*2-1:0]                 s_data_out;
    wire [NBR_CHNLS-1:0]  s_ns_adapter_rstn;
    wire [NBR_CHNLS-1:0]  s_ns_mac_rdy;
    wire [NBR_CHNLS-1:0]  s_fs_mac_rdy;
    wire [NBR_CHNLS-1:0]  s_ms_rx_dcc_dll_lock_req;
    wire [NBR_CHNLS-1:0]  s_ms_tx_dcc_dll_lock_req;
    wire [NBR_CHNLS-1:0]  s_sl_tx_dcc_dll_lock_req;
    wire [NBR_CHNLS-1:0]  s_sl_rx_dcc_dll_lock_req;
    wire [MS_SSR_LEN*NBR_CHNLS-1:0] s_sr_ms_tomac;
    wire [SL_SSR_LEN*NBR_CHNLS-1:0] s_sr_sl_tomac;
    wire [NBR_CHNLS-1:0]  s_rx_align_done;

    // EMIB connections
    wire [NBR_BUMPS-1:0] m_iopad_ch0_aib;
    wire [NBR_BUMPS-1:0] m_iopad_ch1_aib;
    wire [NBR_BUMPS-1:0] m_iopad_ch2_aib;
    wire [NBR_BUMPS-1:0] m_iopad_ch3_aib;
    wire [NBR_BUMPS-1:0] m_iopad_ch4_aib;
    wire [NBR_BUMPS-1:0] m_iopad_ch5_aib;
    wire [NBR_BUMPS-1:0] m_iopad_ch6_aib;
    wire [NBR_BUMPS-1:0] m_iopad_ch7_aib;
    wire [NBR_BUMPS-1:0] m_iopad_ch8_aib;
    wire [NBR_BUMPS-1:0] m_iopad_ch9_aib;
    wire [NBR_BUMPS-1:0] m_iopad_ch10_aib;
    wire [NBR_BUMPS-1:0] m_iopad_ch11_aib;
    wire [NBR_BUMPS-1:0] m_iopad_ch12_aib;
    wire [NBR_BUMPS-1:0] m_iopad_ch13_aib;
    wire [NBR_BUMPS-1:0] m_iopad_ch14_aib;
    wire [NBR_BUMPS-1:0] m_iopad_ch15_aib;
    wire [NBR_BUMPS-1:0] m_iopad_ch16_aib;
    wire [NBR_BUMPS-1:0] m_iopad_ch17_aib;
    wire [NBR_BUMPS-1:0] m_iopad_ch18_aib;
    wire [NBR_BUMPS-1:0] m_iopad_ch19_aib;
    wire [NBR_BUMPS-1:0] m_iopad_ch20_aib;
    wire [NBR_BUMPS-1:0] m_iopad_ch21_aib;
    wire [NBR_BUMPS-1:0] m_iopad_ch22_aib;
    wire [NBR_BUMPS-1:0] m_iopad_ch23_aib;

    wire [NBR_BUMPS-1:0] s_iopad_ch0_aib;
    wire [NBR_BUMPS-1:0] s_iopad_ch1_aib;
    wire [NBR_BUMPS-1:0] s_iopad_ch2_aib;
    wire [NBR_BUMPS-1:0] s_iopad_ch3_aib;
    wire [NBR_BUMPS-1:0] s_iopad_ch4_aib;
    wire [NBR_BUMPS-1:0] s_iopad_ch5_aib;
    wire [NBR_BUMPS-1:0] s_iopad_ch6_aib;
    wire [NBR_BUMPS-1:0] s_iopad_ch7_aib;
    wire [NBR_BUMPS-1:0] s_iopad_ch8_aib;
    wire [NBR_BUMPS-1:0] s_iopad_ch9_aib;
    wire [NBR_BUMPS-1:0] s_iopad_ch10_aib;
    wire [NBR_BUMPS-1:0] s_iopad_ch11_aib;
    wire [NBR_BUMPS-1:0] s_iopad_ch12_aib;
    wire [NBR_BUMPS-1:0] s_iopad_ch13_aib;
    wire [NBR_BUMPS-1:0] s_iopad_ch14_aib;
    wire [NBR_BUMPS-1:0] s_iopad_ch15_aib;
    wire [NBR_BUMPS-1:0] s_iopad_ch16_aib;
    wire [NBR_BUMPS-1:0] s_iopad_ch17_aib;
    wire [NBR_BUMPS-1:0] s_iopad_ch18_aib;
    wire [NBR_BUMPS-1:0] s_iopad_ch19_aib;
    wire [NBR_BUMPS-1:0] s_iopad_ch20_aib;
    wire [NBR_BUMPS-1:0] s_iopad_ch21_aib;
    wire [NBR_BUMPS-1:0] s_iopad_ch22_aib;
    wire [NBR_BUMPS-1:0] s_iopad_ch23_aib;

    // Instantiate Master Bridge
    top_aib_axi_bridge_master #(
        .NBR_CHNLS(NBR_CHNLS),
        .NBR_BUMPS(NBR_BUMPS),
        .NBR_PHASES(NBR_PHASES),
        .NBR_LANES(NBR_LANES),
        .MS_SSR_LEN(MS_SSR_LEN),
        .SL_SSR_LEN(SL_SSR_LEN)
    ) master_bridge (
        // EMIB interface
        .vddc1(vddc1),
        .vddc2(vddc2),
        .vddtx(vddtx),
        .vss(vss),
        .iopad_ch0_aib(m_iopad_ch0_aib),
        .iopad_ch1_aib(m_iopad_ch1_aib),
        .iopad_ch2_aib(m_iopad_ch2_aib),
        .iopad_ch3_aib(m_iopad_ch3_aib),
        .iopad_ch4_aib(m_iopad_ch4_aib),
        .iopad_ch5_aib(m_iopad_ch5_aib),
        .iopad_ch6_aib(m_iopad_ch6_aib),
        .iopad_ch7_aib(m_iopad_ch7_aib),
        .iopad_ch8_aib(m_iopad_ch8_aib),
        .iopad_ch9_aib(m_iopad_ch9_aib),
        .iopad_ch10_aib(m_iopad_ch10_aib),
        .iopad_ch11_aib(m_iopad_ch11_aib),
        .iopad_ch12_aib(m_iopad_ch12_aib),
        .iopad_ch13_aib(m_iopad_ch13_aib),
        .iopad_ch14_aib(m_iopad_ch14_aib),
        .iopad_ch15_aib(m_iopad_ch15_aib),
        .iopad_ch16_aib(m_iopad_ch16_aib),
        .iopad_ch17_aib(m_iopad_ch17_aib),
        .iopad_ch18_aib(m_iopad_ch18_aib),
        .iopad_ch19_aib(m_iopad_ch19_aib),
        .iopad_ch20_aib(m_iopad_ch20_aib),
        .iopad_ch21_aib(m_iopad_ch21_aib),
        .iopad_ch22_aib(m_iopad_ch22_aib),
        .iopad_ch23_aib(m_iopad_ch23_aib),
        .iopad_device_detect(iopad_device_detect),
        .iopad_power_on_reset(iopad_power_on_reset),

        // AIB PHY interface
        .i_osc_clk(i_osc_clk),
        .m_ns_fwd_clk(m_ns_fwd_clk),
        .m_ns_rcv_clk(m_ns_rcv_clk),
        .m_fs_rcv_clk(m_fs_rcv_clk), // outputs not used
        .m_fs_fwd_clk(m_fs_fwd_clk), // outputs not used 
        .m_wr_clk(m_clk_wr),
        .m_rd_clk(m_clk_rd),
        .m_fwd_clk(m_fwd_clk),

        .ns_adapter_rstn(m_ns_adapter_rstn), //Only for AIB Plus
        .ns_mac_rdy(m_ns_mac_rdy),
        .fs_mac_rdy(m_fs_mac_rdy),
        .i_conf_done(i_conf_done),
        //.ms_rx_dcc_dll_lock_req(1'b1/*m_ms_rx_dcc_dll_lock_req*/),
        //.ms_tx_dcc_dll_lock_req(1'b1/*m_ms_tx_dcc_dll_lock_req*/),
        //.sl_tx_dcc_dll_lock_req(1'b1/*m_sl_tx_dcc_dll_lock_req*/),
        //.sl_rx_dcc_dll_lock_req(1'b1/*m_sl_rx_dcc_dll_lock_req*/),
        //.sr_ms_tomac(m_sr_ms_tomac),
        //.sr_sl_tomac(m_sr_sl_tomac),
        .m_rx_align_done(m_rx_align_done),

        // AXI interface
        .clk_wr(m_clk_wr),
        .rst_wr_n(m_rst_wr_n),
        //.clk_rd(m_clk_rd),
        //.rst_rd_n(m_rst_rd_n),
        //.tx_online(m_tx_online),
        //.rx_online(m_rx_online),
        .init_ar_credit(m_init_ar_credit),
        .init_aw_credit(m_init_aw_credit),
        .init_w_credit(m_init_w_credit),
        .user_axi_if(m_user_axi_if),
        .tx_ar_debug_status(m_tx_ar_debug_status),
        .tx_aw_debug_status(m_tx_aw_debug_status),
        .tx_w_debug_status(m_tx_w_debug_status),
        .rx_r_debug_status(m_rx_r_debug_status),
        .rx_b_debug_status(m_rx_b_debug_status),
        .delay_x_value(m_delay_x_value),
        .delay_y_value(m_delay_y_value),
        .delay_z_value(m_delay_z_value),

        .avmm_clk(m_avmm_clk),
        .avmm_rst_n(m_avmm_rst_n),
        .i_cfg_avmm_addr(m_i_cfg_avmm_addr),
        .i_cfg_avmm_byte_en(m_i_cfg_avmm_byte_en),
        .i_cfg_avmm_read(m_i_cfg_avmm_read),
        .i_cfg_avmm_write(m_i_cfg_avmm_write),
        .i_cfg_avmm_wdata(m_i_cfg_avmm_wdata),
        .o_cfg_avmm_rdatavld(m_o_cfg_avmm_rdatavld),
        .o_cfg_avmm_rdata(m_o_cfg_avmm_rdata),
        .o_cfg_avmm_waitreq(m_o_cfg_avmm_waitreq)
    );

    // Instantiate Slave Bridge
    top_aib_axi_bridge_slave #(
        .NBR_CHNLS(NBR_CHNLS),
        .NBR_BUMPS(NBR_BUMPS),
        .NBR_PHASES(NBR_PHASES),
        .NBR_LANES(NBR_LANES),
        .MS_SSR_LEN(MS_SSR_LEN),
        .SL_SSR_LEN(SL_SSR_LEN)
    ) slave_bridge (
        // EMIB interface
        .vddc1(vddc1),
        .vddc2(vddc2),
        .vddtx(vddtx),
        .vss(vss),
        .iopad_ch0_aib(s_iopad_ch0_aib),
        .iopad_ch1_aib(s_iopad_ch1_aib),
        .iopad_ch2_aib(s_iopad_ch2_aib),
        .iopad_ch3_aib(s_iopad_ch3_aib),
        .iopad_ch4_aib(s_iopad_ch4_aib),
        .iopad_ch5_aib(s_iopad_ch5_aib),
        .iopad_ch6_aib(s_iopad_ch6_aib),
        .iopad_ch7_aib(s_iopad_ch7_aib),
        .iopad_ch8_aib(s_iopad_ch8_aib),
        .iopad_ch9_aib(s_iopad_ch9_aib),
        .iopad_ch10_aib(s_iopad_ch10_aib),
        .iopad_ch11_aib(s_iopad_ch11_aib),
        .iopad_ch12_aib(s_iopad_ch12_aib),
        .iopad_ch13_aib(s_iopad_ch13_aib),
        .iopad_ch14_aib(s_iopad_ch14_aib),
        .iopad_ch15_aib(s_iopad_ch15_aib),
        .iopad_ch16_aib(s_iopad_ch16_aib),
        .iopad_ch17_aib(s_iopad_ch17_aib),
        .iopad_ch18_aib(s_iopad_ch18_aib),
        .iopad_ch19_aib(s_iopad_ch19_aib),
        .iopad_ch20_aib(s_iopad_ch20_aib),
        .iopad_ch21_aib(s_iopad_ch21_aib),
        .iopad_ch22_aib(s_iopad_ch22_aib),
        .iopad_ch23_aib(s_iopad_ch23_aib),
        .iopad_device_detect(iopad_device_detect),
        .iopad_power_on_reset(iopad_power_on_reset),

        // AIB PHY interface
        .i_osc_clk(i_osc_clk),
        .m_ns_fwd_clk(s_fs_fwd_clk),
        .m_ns_rcv_clk(s_fs_rcv_clk),
        .m_fs_rcv_clk(s_ns_rcv_clk),
        .m_fs_fwd_clk(s_ns_fwd_clk),
        .m_wr_clk(s_clk_wr),
        .m_rd_clk(s_clk_rd),
        .m_fwd_clk(s_fwd_clk),

        
        // .data_in_f(s_data_in_f),
        // .data_in(s_data_in),
        // .data_out_f(s_data_out_f),
        // .data_out(s_data_out),
        
        .ns_adapter_rstn(s_ns_adapter_rstn),
        .ns_mac_rdy(s_ns_mac_rdy),
        .fs_mac_rdy(s_fs_mac_rdy),
        .i_conf_done(i_conf_done),
        .ms_rx_dcc_dll_lock_req(1'b1/*s_ms_rx_dcc_dll_lock_req*/),
        .ms_tx_dcc_dll_lock_req(1'b1/*s_ms_tx_dcc_dll_lock_req*/),
        .sl_tx_dcc_dll_lock_req(1'b1/*s_sl_tx_dcc_dll_lock_req*/),
        .sl_rx_dcc_dll_lock_req(1'b1/*s_sl_rx_dcc_dll_lock_req*/),
        .sr_ms_tomac(s_sr_ms_tomac),
        .sr_sl_tomac(s_sr_sl_tomac),
        .m_rx_align_done(s_rx_align_done),

        // AXI interface
        .clk_wr(s_clk_wr),
        .rst_wr_n(s_rst_wr_n),
        //.clk_rd(s_clk_rd),
        .rst_rd_n(s_rst_rd_n),
        //.tx_online(s_tx_online),
        //.rx_online(s_rx_online),
        .init_r_credit(s_init_r_credit),
        .init_b_credit(s_init_b_credit),
        .user_axi_if(s_user_axi_if),
        .rx_ar_debug_status(s_rx_ar_debug_status),
        .rx_aw_debug_status(s_rx_aw_debug_status),
        .rx_w_debug_status(s_rx_w_debug_status),
        .tx_r_debug_status(s_tx_r_debug_status),
        .tx_b_debug_status(s_tx_b_debug_status),
        .delay_x_value(s_delay_x_value),
        .delay_y_value(s_delay_y_value),
        .delay_z_value(s_delay_z_value),

        .avmm_clk(s_avmm_clk),
        .avmm_rst_n(s_avmm_rst_n),
        .i_cfg_avmm_addr(s_i_cfg_avmm_addr),
        .i_cfg_avmm_byte_en(s_i_cfg_avmm_byte_en),
        .i_cfg_avmm_read(s_i_cfg_avmm_read),
        .i_cfg_avmm_write(s_i_cfg_avmm_write),
        .i_cfg_avmm_wdata(s_i_cfg_avmm_wdata),
        .o_cfg_avmm_rdatavld(s_o_cfg_avmm_rdatavld), // TODO: this outputs are not going anywhere
        .o_cfg_avmm_rdata(s_o_cfg_avmm_rdata),
        .o_cfg_avmm_waitreq(s_o_cfg_avmm_waitreq)
        
    );

    // Instantiate EMIB
    emib_m2s2 dut_emib (
        // Master side connections
        .m_ch0_aib(m_iopad_ch0_aib),
        .m_ch1_aib(m_iopad_ch1_aib),
        .m_ch2_aib(m_iopad_ch2_aib),
        .m_ch3_aib(m_iopad_ch3_aib),
        .m_ch4_aib(m_iopad_ch4_aib),
        .m_ch5_aib(m_iopad_ch5_aib),
        .m_ch6_aib(m_iopad_ch6_aib),
        .m_ch7_aib(m_iopad_ch7_aib),
        .m_ch8_aib(m_iopad_ch8_aib),
        .m_ch9_aib(m_iopad_ch9_aib),
        .m_ch10_aib(m_iopad_ch10_aib),
        .m_ch11_aib(m_iopad_ch11_aib),
        .m_ch12_aib(m_iopad_ch12_aib),
        .m_ch13_aib(m_iopad_ch13_aib),
        .m_ch14_aib(m_iopad_ch14_aib),
        .m_ch15_aib(m_iopad_ch15_aib),
        .m_ch16_aib(m_iopad_ch16_aib),
        .m_ch17_aib(m_iopad_ch17_aib),
        .m_ch18_aib(m_iopad_ch18_aib),
        .m_ch19_aib(m_iopad_ch19_aib),
        .m_ch20_aib(m_iopad_ch20_aib),
        .m_ch21_aib(m_iopad_ch21_aib),
        .m_ch22_aib(m_iopad_ch22_aib),
        .m_ch23_aib(m_iopad_ch23_aib),

        // Slave side connections
        .s_ch0_aib(s_iopad_ch0_aib),
        .s_ch1_aib(s_iopad_ch1_aib),
        .s_ch2_aib(s_iopad_ch2_aib),
        .s_ch3_aib(s_iopad_ch3_aib),
        .s_ch4_aib(s_iopad_ch4_aib),
        .s_ch5_aib(s_iopad_ch5_aib),
        .s_ch6_aib(s_iopad_ch6_aib),
        .s_ch7_aib(s_iopad_ch7_aib),
        .s_ch8_aib(s_iopad_ch8_aib),
        .s_ch9_aib(s_iopad_ch9_aib),
        .s_ch10_aib(s_iopad_ch10_aib),
        .s_ch11_aib(s_iopad_ch11_aib),
        .s_ch12_aib(s_iopad_ch12_aib),
        .s_ch13_aib(s_iopad_ch13_aib),
        .s_ch14_aib(s_iopad_ch14_aib),
        .s_ch15_aib(s_iopad_ch15_aib),
        .s_ch16_aib(s_iopad_ch16_aib),
        .s_ch17_aib(s_iopad_ch17_aib),
        .s_ch18_aib(s_iopad_ch18_aib),
        .s_ch19_aib(s_iopad_ch19_aib),
        .s_ch20_aib(s_iopad_ch20_aib),
        .s_ch21_aib(s_iopad_ch21_aib),
        .s_ch22_aib(s_iopad_ch22_aib),
        .s_ch23_aib(s_iopad_ch23_aib)
    );

    // Connect clock and control signals between master and slave
    // assign m_ns_fwd_clk = s_fs_fwd_clk;
    // assign m_ns_rcv_clk = s_fs_rcv_clk;
    // asign s_ns_fwd_clk = m_fs_fwd_clk;
    // assign s_ns_rcv_clk = m_fs_rcv_clk;

    // assign m_fs_mac_rdy = s_ns_mac_rdy;
    // assign s_fs_mac_rdy = m_ns_mac_rdy;

    // Connect data paths between master and slave through EMIB
    // assign m_data_in = s_data_out;
    // assign s_data_in = m_data_out;
    //assign m_data_in_f = s_data_out_f;
    //assign s_data_in_f = m_data_out_f;

    // Connect sideband signals
    // assign m_sr_sl_tomac = s_sr_ms_tomac;
    // assign s_sr_ms_tomac = m_sr_sl_tomac;

    // Connect calibration signals
    // assign m_sl_tx_dcc_dll_lock_req = s_ms_tx_dcc_dll_lock_req;
    // assign m_sl_rx_dcc_dll_lock_req = s_ms_rx_dcc_dll_lock_req;
    // assign s_sl_tx_dcc_dll_lock_req = m_ms_tx_dcc_dll_lock_req;
    // assign s_sl_rx_dcc_dll_lock_req = m_ms_rx_dcc_dll_lock_req;

    // Connect reset signals
    // assign m_ns_adapter_rstn = s_fs_mac_rdy;
    // assign s_ns_adapter_rstn = m_fs_mac_rdy;

    // assign m_sr_ms_tomac = s_sr_sl_tomac;
    // assign s_sr_sl_tomac = m_sr_ms_tomac;

endmodule