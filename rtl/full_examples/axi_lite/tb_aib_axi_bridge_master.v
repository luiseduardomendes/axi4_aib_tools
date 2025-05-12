`timescale 1ns/1ps
`include "../../interfaces/axi_if.v"

module tb_top_aib_axi_bridge_master();

    // Parameters from DUT
    parameter NBR_CHNLS = 24;
    parameter NBR_BUMPS = 102;
    parameter NBR_PHASES = 4;
    parameter NBR_LANES = 40;
    parameter MS_SSR_LEN = 81;
    parameter SL_SSR_LEN = 73;
    parameter DWIDTH = 40;

    // Clock and reset signals
    reg clk_wr;
    reg rst_wr_n;
    reg i_osc_clk;
    reg avmm_clk;
    reg avmm_rst_n;
    
    // AIB PHY signals
    wire [NBR_BUMPS-1:0] iopad_ch0_aib;
    // ... (other channels would be declared similarly)
    wire iopad_device_detect;
    wire iopad_power_on_reset;
    
    // Clock signals
    reg [NBR_CHNLS-1:0] m_ns_fwd_clk;
    reg [NBR_CHNLS-1:0] m_ns_rcv_clk;
    wire [NBR_CHNLS-1:0] m_fs_rcv_clk;
    wire [NBR_CHNLS-1:0] m_fs_fwd_clk;
    reg m_wr_clk;
    reg m_rd_clk;
    wire m_fwd_clk;
    
    // Data signals
    reg [NBR_LANES*2*NBR_CHNLS-1:0] data_in;
    wire [NBR_CHNLS*DWIDTH*2-1:0] data_out;
    
    // Interface signals
    reg [NBR_CHNLS-1:0] ns_adapter_rstn;
    reg [NBR_CHNLS-1:0] ns_mac_rdy;
    wire [NBR_CHNLS-1:0] fs_mac_rdy;
    reg i_conf_done;
    reg [NBR_CHNLS-1:0] ms_rx_dcc_dll_lock_req;
    reg [NBR_CHNLS-1:0] ms_tx_dcc_dll_lock_req;
    wire [MS_SSR_LEN*NBR_CHNLS-1:0] sr_ms_tomac;
    wire [SL_SSR_LEN*NBR_CHNLS-1:0] sr_sl_tomac;
    wire [NBR_CHNLS-1:0] m_rx_align_done;
    
    // AXI signals
    reg [7:0] init_ar_credit;
    reg [7:0] init_aw_credit;
    reg [7:0] init_w_credit;
    
    wire [31:0] tx_ar_debug_status;
    wire [31:0] tx_aw_debug_status;
    wire [31:0] tx_w_debug_status;
    wire [31:0] rx_r_debug_status;
    wire [31:0] rx_b_debug_status;
    
    reg [15:0] delay_x_value;
    reg [15:0] delay_y_value;
    reg [15:0] delay_z_value;
    
    // Avalon MM Interface
    reg [31:0] i_cfg_avmm_addr;
    reg [3:0] i_cfg_avmm_byte_en;
    reg i_cfg_avmm_read;
    reg i_cfg_avmm_write;
    reg [31:0] i_cfg_avmm_wdata;
    wire o_cfg_avmm_rdatavld;
    wire [31:0] o_cfg_avmm_rdata;
    wire o_cfg_avmm_waitreq;
    
    // AXI Interface
    axi_if user_axi_if();
    
    // AIB to AXI Bridge Master DUT
    top_aib_axi_bridge_master #(
        .NBR_CHNLS(NBR_CHNLS),
        .NBR_BUMPS(NBR_BUMPS),
        .NBR_PHASES(NBR_PHASES),
        .NBR_LANES(NBR_LANES),
        .MS_SSR_LEN(MS_SSR_LEN),
        .SL_SSR_LEN(SL_SSR_LEN),
        .DWIDTH(DWIDTH)
    ) dut (
        // EMIB interface
        //.vddc1(1'b1),
        //.vddc2(1'b1),
        //.vddtx(1'b1),
        //.vss(1'b0),
        .iopad_ch0_aib(iopad_ch0_aib),
        // ... (other channels would be connected similarly)
        .iopad_device_detect(iopad_device_detect),
        .iopad_power_on_reset(iopad_power_on_reset),
        
        // AIB PHY signals
        .i_osc_clk(i_osc_clk),
        .avmm_clk(avmm_clk),
        .avmm_rst_n(avmm_rst_n),
        .m_ns_fwd_clk(m_ns_fwd_clk),
        .m_ns_rcv_clk(m_ns_rcv_clk),
        .m_fs_rcv_clk(m_fs_rcv_clk),
        .m_fs_fwd_clk(m_fs_fwd_clk),
        .m_wr_clk(m_wr_clk),
        .m_rd_clk(m_rd_clk),
        .m_fwd_clk(m_fwd_clk),
        .data_in(data_in),
        .data_out(data_out),
        .ns_adapter_rstn(ns_adapter_rstn),
        .ns_mac_rdy(ns_mac_rdy),
        .fs_mac_rdy(fs_mac_rdy),
        .i_conf_done(i_conf_done),
        .ms_rx_dcc_dll_lock_req(ms_rx_dcc_dll_lock_req),
        .ms_tx_dcc_dll_lock_req(ms_tx_dcc_dll_lock_req),
        .sr_ms_tomac(sr_ms_tomac),
        .sr_sl_tomac(sr_sl_tomac),
        .m_rx_align_done(m_rx_align_done),
        
        // AXI signals
        .clk_wr(clk_wr),
        .rst_wr_n(rst_wr_n),
        .init_ar_credit(init_ar_credit),
        .init_aw_credit(init_aw_credit),
        .init_w_credit(init_w_credit),
        .user_axi_if(user_axi_if),
        .tx_ar_debug_status(tx_ar_debug_status),
        .tx_aw_debug_status(tx_aw_debug_status),
        .tx_w_debug_status(tx_w_debug_status),
        .rx_r_debug_status(rx_r_debug_status),
        .rx_b_debug_status(rx_b_debug_status),
        .delay_x_value(delay_x_value),
        .delay_y_value(delay_y_value),
        .delay_z_value(delay_z_value),
        
        // Avalon MM Interface
        .i_cfg_avmm_addr(i_cfg_avmm_addr),
        .i_cfg_avmm_byte_en(i_cfg_avmm_byte_en),
        .i_cfg_avmm_read(i_cfg_avmm_read),
        .i_cfg_avmm_write(i_cfg_avmm_write),
        .i_cfg_avmm_wdata(i_cfg_avmm_wdata),
        .o_cfg_avmm_rdatavld(o_cfg_avmm_rdatavld),
        .o_cfg_avmm_rdata(o_cfg_avmm_rdata),
        .o_cfg_avmm_waitreq(o_cfg_avmm_waitreq)
    );
    
    // Clock generation
    initial begin
        clk_wr = 0;
        forever #5 clk_wr = ~clk_wr; // 100MHz
    end
    
    initial begin
        avmm_clk = 0;
        forever #4 avmm_clk = ~avmm_clk; // 125MHz
    end
    
    initial begin
        i_osc_clk = 0;
        forever #2 i_osc_clk = ~i_osc_clk; // 250MHz
    end
    
    initial begin
        m_wr_clk = 0;
        forever #3.33 m_wr_clk = ~m_wr_clk; // ~150MHz
    end
    
    initial begin
        m_rd_clk = 0;
        forever #3.33 m_rd_clk = ~m_rd_clk; // ~150MHz
    end
    
    // Reset generation
    initial begin
        rst_wr_n = 0;
        avmm_rst_n = 0;
        #100;
        rst_wr_n = 1;
        avmm_rst_n = 1;
    end
    
    // Test sequence
    initial begin
        // Initialize all inputs
        init_ar_credit = 8'hFF;
        init_aw_credit = 8'hFF;
        init_w_credit = 8'hFF;
        
        ns_adapter_rstn = {NBR_CHNLS{1'b0}};
        ns_mac_rdy = {NBR_CHNLS{1'b0}};
        i_conf_done = 0;
        ms_rx_dcc_dll_lock_req = {NBR_CHNLS{1'b0}};
        ms_tx_dcc_dll_lock_req = {NBR_CHNLS{1'b0}};
        data_in = {NBR_LANES*2*NBR_CHNLS{1'b0}};
        
        delay_x_value = 16'h0000;
        delay_y_value = 16'h0000;
        delay_z_value = 16'h0000;
        
        i_cfg_avmm_addr = 32'h0;
        i_cfg_avmm_byte_en = 4'h0;
        i_cfg_avmm_read = 0;
        i_cfg_avmm_write = 0;
        i_cfg_avmm_wdata = 32'h0;
        
        // Initialize AXI interface
        user_axi_if.araddr = 32'h0;
        user_axi_if.arvalid = 0;
        user_axi_if.awaddr = 32'h0;
        user_axi_if.awvalid = 0;
        user_axi_if.wdata = 32'h0;
        user_axi_if.wstrb = 8'h0;
        user_axi_if.wvalid = 0;
        user_axi_if.rready = 0;
        user_axi_if.bready = 0;
        
        // Wait for reset to complete
        #150;
        
        // Bring up AIB interface
        ns_adapter_rstn = {NBR_CHNLS{1'b1}};
        ns_mac_rdy = {NBR_CHNLS{1'b1}};
        i_conf_done = 1;
        ms_rx_dcc_dll_lock_req = {NBR_CHNLS{1'b1}};
        ms_tx_dcc_dll_lock_req = {NBR_CHNLS{1'b1}};
        
        // Wait for AIB to initialize
        #200;
        
        // Test 1: Simple AXI write transaction
        $display("Starting Test 1: AXI Write Transaction");
        axi_write_test(32'hA000_0000, 32'hDEAD_BEEF, 8'hFF);
        
        // Test 2: Simple AXI read transaction
        $display("Starting Test 2: AXI Read Transaction");
        axi_read_test(32'hA000_0000);
        
        // Test 3: Avalon MM configuration write
        $display("Starting Test 3: Avalon MM Write");
        avmm_write_test(32'h100, 32'h1234_5678);
        
        // Test 4: Avalon MM configuration read
        $display("Starting Test 4: Avalon MM Read");
        avmm_read_test(32'h100);
        
        // Wait and finish
        #1000;
        $display("All tests completed");
        $finish;
    end
    
    // Task for AXI write transaction
    task axi_write_test;
        input [31:0] addr;
        input [31:0] data;
        input [7:0] strb;
        
        begin
            // AW channel
            @(posedge clk_wr);
            user_axi_if.awaddr <= addr;
            user_axi_if.awvalid <= 1'b1;
            
            // Wait for AW ready
            while (!user_axi_if.awready) @(posedge clk_wr);
            @(posedge clk_wr);
            user_axi_if.awvalid <= 1'b0;
            
            // W channel
            user_axi_if.wdata <= data;
            user_axi_if.wstrb <= strb;
            user_axi_if.wvalid <= 1'b1;
            
            // Wait for W ready
            while (!user_axi_if.wready) @(posedge clk_wr);
            @(posedge clk_wr);
            user_axi_if.wvalid <= 1'b0;
            
            // B channel (response)
            user_axi_if.bready <= 1'b1;
            while (!user_axi_if.bvalid) @(posedge clk_wr);
            @(posedge clk_wr);
            user_axi_if.bready <= 1'b0;
            
            $display("AXI Write Complete - Addr: 0x%h, Data: 0x%h, Response: %b", 
                     addr, data, user_axi_if.bresp);
        end
    endtask
    
    // Task for AXI read transaction
    task axi_read_test;
        input [31:0] addr;
        
        begin
            // AR channel
            @(posedge clk_wr);
            user_axi_if.araddr <= addr;
            user_axi_if.arvalid <= 1'b1;
            
            // Wait for AR ready
            while (!user_axi_if.arready) @(posedge clk_wr);
            @(posedge clk_wr);
            user_axi_if.arvalid <= 1'b0;
            
            // R channel (response)
            user_axi_if.rready <= 1'b1;
            while (!user_axi_if.rvalid) @(posedge clk_wr);
            @(posedge clk_wr);
            user_axi_if.rready <= 1'b0;
            
            $display("AXI Read Complete - Addr: 0x%h, Data: 0x%h, Response: %b", 
                     addr, user_axi_if.rdata, user_axi_if.rresp);
        end
    endtask
    
    // Task for Avalon MM write
    task avmm_write_test;
        input [31:0] addr;
        input [31:0] data;
        
        begin
            @(posedge avmm_clk);
            i_cfg_avmm_addr <= addr;
            i_cfg_avmm_byte_en <= 4'hF;
            i_cfg_avmm_write <= 1'b1;
            i_cfg_avmm_wdata <= data;
            
            // Wait for not waitrequest
            while (o_cfg_avmm_waitreq) @(posedge avmm_clk);
            @(posedge avmm_clk);
            i_cfg_avmm_write <= 1'b0;
            
            $display("AVMM Write Complete - Addr: 0x%h, Data: 0x%h", addr, data);
        end
    endtask
    
    // Task for Avalon MM read
    task avmm_read_test;
        input [31:0] addr;
        
        begin
            @(posedge avmm_clk);
            i_cfg_avmm_addr <= addr;
            i_cfg_avmm_byte_en <= 4'hF;
            i_cfg_avmm_read <= 1'b1;
            
            // Wait for not waitrequest
            while (o_cfg_avmm_waitreq) @(posedge avmm_clk);
            @(posedge avmm_clk);
            i_cfg_avmm_read <= 1'b0;
            
            // Wait for read data valid
            while (!o_cfg_avmm_rdatavld) @(posedge avmm_clk);
            
            $display("AVMM Read Complete - Addr: 0x%h, Data: 0x%h", addr, o_cfg_avmm_rdata);
        end
    endtask
    
    // Monitoring
    always @(posedge clk_wr) begin
        if (user_axi_if.awvalid && user_axi_if.awready) begin
            $display("[%0t] AXI AW - Addr: 0x%h", $time, user_axi_if.awaddr);
        end
        
        if (user_axi_if.wvalid && user_axi_if.wready) begin
            $display("[%0t] AXI W - Data: 0x%h, Strb: 0x%h", $time, user_axi_if.wdata, user_axi_if.wstrb);
        end
        
        if (user_axi_if.bvalid && user_axi_if.bready) begin
            $display("[%0t] AXI B - Resp: %b", $time, user_axi_if.bresp);
        end
        
        if (user_axi_if.arvalid && user_axi_if.arready) begin
            $display("[%0t] AXI AR - Addr: 0x%h", $time, user_axi_if.araddr);
        end
        
        if (user_axi_if.rvalid && user_axi_if.rready) begin
            $display("[%0t] AXI R - Data: 0x%h, Resp: %b", $time, user_axi_if.rdata, user_axi_if.rresp);
        end
    end
    
    // Waveform dumping
    initial begin
        $dumpfile("tb_top_aib_axi_bridge_master.vcd");
        $dumpvars(0, tb_top_aib_axi_bridge_master);
    end

endmodule