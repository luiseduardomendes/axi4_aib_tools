`timescale 1ns/1ps

module aib_axi_bridge_tb;

    // Parameters from the design
    parameter NBR_CHNLS = 24;
    parameter NBR_BUMPS = 102;
    parameter NBR_PHASES = 4;
    parameter NBR_LANES = 40;
    parameter MS_SSR_LEN = 81;
    parameter SL_SSR_LEN = 73;
    parameter DWIDTH = 8;

    // Clock and reset
    reg m_clk_wr, m_clk_rd;
    reg s_clk_wr, s_clk_rd;
    reg m_rst_wr_n, m_rst_rd_n;
    reg s_rst_wr_n, s_rst_rd_n;
    
    // Oscillator clock
    reg i_osc_clk;
    
    // Configuration signals
    reg i_conf_done;
    wire iopad_device_detect;
    wire iopad_power_on_reset;
    
    // Online signals
    reg m_tx_online, m_rx_online;
    reg s_tx_online, s_rx_online;
    
    // Credit signals
    reg [7:0] m_init_ar_credit, m_init_aw_credit, m_init_w_credit;
    reg [7:0] s_init_r_credit, s_init_b_credit;
    
    // Delay values
    reg [15:0] m_delay_x_value, m_delay_y_value, m_delay_z_value;
    reg [15:0] s_delay_x_value, s_delay_y_value, s_delay_z_value;
    
    // Debug outputs
    wire [31:0] m_tx_ar_debug_status, m_tx_aw_debug_status, m_tx_w_debug_status;
    wire [31:0] m_rx_r_debug_status, m_rx_b_debug_status;
    wire [31:0] s_tx_ar_debug_status, s_tx_aw_debug_status, s_tx_w_debug_status;
    wire [31:0] s_rx_r_debug_status, s_rx_b_debug_status;
    
    // AXI interfaces
    axi_if m_user_axi_if();
    axi_if s_user_axi_if();
    
    // Power supplies (not really used in simulation)
    wire vddc1, vddc2, vddtx, vss;
    assign vddc1 = 1'b1;
    assign vddc2 = 1'b1;
    assign vddtx = 1'b1; // 0.4V for gen2
    assign vss = 1'b0;
    
    // Instantiate the DUT
    aib_axi_top #(
        .NBR_CHNLS(NBR_CHNLS),
        .NBR_BUMPS(NBR_BUMPS),
        .NBR_PHASES(NBR_PHASES),
        .NBR_LANES(NBR_LANES),
        .MS_SSR_LEN(MS_SSR_LEN),
        .SL_SSR_LEN(SL_SSR_LEN),
        .DWIDTH(DWIDTH)
    ) dut (
        // Power pins
        .vddc1(vddc1),
        .vddc2(vddc2),
        .vddtx(vddtx),
        .vss(vss),
        
        // Master AXI Interface
        .m_clk_wr(m_clk_wr),
        .m_rst_wr_n(m_rst_wr_n),
        .m_clk_rd(m_clk_rd),
        .m_rst_rd_n(m_rst_rd_n),
        .m_tx_online(m_tx_online),
        .m_rx_online(m_rx_online),
        .m_init_ar_credit(m_init_ar_credit),
        .m_init_aw_credit(m_init_aw_credit),
        .m_init_w_credit(m_init_w_credit),
        .m_user_axi_if(m_user_axi_if),
        //.m_tx_ar_debug_status(m_tx_ar_debug_status),
        //.m_tx_aw_debug_status(m_tx_aw_debug_status),
        //.m_tx_w_debug_status(m_tx_w_debug_status),
        //.m_rx_r_debug_status(m_rx_r_debug_status),
        //.m_rx_b_debug_status(m_rx_b_debug_status),
        .m_delay_x_value(m_delay_x_value),
        .m_delay_y_value(m_delay_y_value),
        .m_delay_z_value(m_delay_z_value),
        
        // Slave AXI Interface
        .s_clk_wr(s_clk_wr),
        .s_rst_wr_n(s_rst_wr_n),
        .s_clk_rd(s_clk_rd),
        .s_rst_rd_n(s_rst_rd_n),
        .s_tx_online(s_tx_online),
        .s_rx_online(s_rx_online),
        .s_init_r_credit(s_init_r_credit),
        .s_init_b_credit(s_init_b_credit),
        .s_user_axi_if(s_user_axi_if),
        //.s_tx_ar_debug_status(s_tx_ar_debug_status),
        //.s_tx_aw_debug_status(s_tx_aw_debug_status),
        //.s_tx_w_debug_status(s_tx_w_debug_status),
        //.s_rx_r_debug_status(s_rx_r_debug_status),
        //.s_rx_b_debug_status(s_rx_b_debug_status),
        .s_delay_x_value(s_delay_x_value),
        .s_delay_y_value(s_delay_y_value),
        .s_delay_z_value(s_delay_z_value),
        
        // Common AIB signals
        .i_osc_clk(i_osc_clk),
        .i_conf_done(i_conf_done),
        .iopad_device_detect(iopad_device_detect),
        .iopad_power_on_reset(iopad_power_on_reset)
    );
    
    // Clock generation
    initial begin
        m_clk_wr = 0;
        forever #5 m_clk_wr = ~m_clk_wr; // 100MHz
    end
    
    initial begin
        m_clk_rd = 0;
        forever #5 m_clk_rd = ~m_clk_rd; // 100MHz
    end
    
    initial begin
        s_clk_wr = 0;
        forever #5 s_clk_wr = ~s_clk_wr; // 100MHz
    end
    
    initial begin
        s_clk_rd = 0;
        forever #5 s_clk_rd = ~s_clk_rd; // 100MHz
    end
    
    initial begin
        i_osc_clk = 0;
        forever #2 i_osc_clk = ~i_osc_clk; // 250MHz
    end
    
    // Reset generation
    initial begin
        // Initial reset
        m_rst_wr_n = 0;
        m_rst_rd_n = 0;
        s_rst_wr_n = 0;
        s_rst_rd_n = 0;
        
        // Configuration signals
        i_conf_done = 0;
        m_tx_online = 0;
        m_rx_online = 0;
        s_tx_online = 0;
        s_rx_online = 0;
        
        // Credit initialization
        m_init_ar_credit = 8'h8;
        m_init_aw_credit = 8'h8;
        m_init_w_credit = 8'h8;
        s_init_r_credit = 8'h8;
        s_init_b_credit = 8'h8;
        
        // Delay values
        m_delay_x_value = 16'h0;
        m_delay_y_value = 16'h0;
        m_delay_z_value = 16'h0;
        s_delay_x_value = 16'h0;
        s_delay_y_value = 16'h0;
        s_delay_z_value = 16'h0;
        
        // Release reset after 100ns
        #100;
        m_rst_wr_n = 1;
        m_rst_rd_n = 1;
        s_rst_wr_n = 1;
        s_rst_rd_n = 1;
        
        // Set configuration done and online signals
        #20;
        i_conf_done = 1;
        m_tx_online = 1;
        m_rx_online = 1;
        s_tx_online = 1;
        s_rx_online = 1;
    end
    
    // Test sequence
    initial begin
        // Wait for reset to complete
        wait(m_rst_wr_n === 1'b1 && s_rst_wr_n === 1'b1);
        
        // Initialize AXI interface
        initialize_axi_interfaces();
        
        // Wait a bit more for everything to settle
        #100;
        
        // Run test cases
        test_axi_write_transaction();
        test_axi_read_transaction();
        
        // Finish simulation
        #100;
        $display("All tests completed successfully!");
        $finish;
    end
    
    // Initialize AXI interfaces
    task initialize_axi_interfaces;
        begin
            // Master AXI interface
            m_user_axi_if.awvalid = 0;
            m_user_axi_if.awaddr = 0;
            m_user_axi_if.awid = 0;
            m_user_axi_if.awlen = 0;
            m_user_axi_if.awsize = 0;
            m_user_axi_if.awburst = 0;
            
            m_user_axi_if.wvalid = 0;
            m_user_axi_if.wdata = 0;
            m_user_axi_if.wstrb = 0;
            m_user_axi_if.wlast = 0;
            
            m_user_axi_if.bready = 1;
            
            m_user_axi_if.arvalid = 0;
            m_user_axi_if.araddr = 0;
            m_user_axi_if.arid = 0;
            m_user_axi_if.arlen = 0;
            m_user_axi_if.arsize = 0;
            m_user_axi_if.arburst = 0;
            
            m_user_axi_if.rready = 1;
            
            // Slave AXI interface (responses)
            s_user_axi_if.awready = 1;
            s_user_axi_if.wready = 1;
            s_user_axi_if.bvalid = 0;
            s_user_axi_if.bresp = 0;
            s_user_axi_if.bid = 0;
            
            s_user_axi_if.arready = 1;
            s_user_axi_if.rvalid = 0;
            s_user_axi_if.rdata = 0;
            s_user_axi_if.rresp = 0;
            s_user_axi_if.rid = 0;
            s_user_axi_if.rlast = 0;
        end
    endtask
    // Test single write transaction for AXI Lite
    task test_axi_write_transaction;
    reg [31:0] addr = 32'h0000_1000;
    reg [31:0] data = 32'h1234_5678;
    begin
        $display("Starting AXI Lite write transaction test...");
        
        // AW channel
        @(posedge m_clk_wr);
        m_user_axi_if.awvalid = 1;
        m_user_axi_if.awaddr = addr;
        
        // W channel
        m_user_axi_if.wvalid = 1;
        m_user_axi_if.wdata = data;
        m_user_axi_if.wstrb = 8'hFF; // All bytes valid
        
        // Wait for handshakes
        fork
            begin
                wait(m_user_axi_if.awready);
                @(posedge m_clk_wr);
                m_user_axi_if.awvalid = 0;
            end
            begin
                wait(m_user_axi_if.wready);
                @(posedge m_clk_wr);
                m_user_axi_if.wvalid = 0;
            end
        join
        
        // Generate B response from slave
        @(posedge s_clk_wr);
        s_user_axi_if.bvalid = 1;
        s_user_axi_if.bresp = 2'b00; // OKAY
        
        wait(m_user_axi_if.bready);
        @(posedge s_clk_wr);
        s_user_axi_if.bvalid = 0;
        
        $display("AXI Lite write transaction completed. Addr: 0x%h, Data: 0x%h", addr, data);
    end
    endtask

    // Test single read transaction for AXI Lite
    task test_axi_read_transaction;
    reg [31:0] addr = 32'h0000_2000;
    reg [31:0] expected_data = 32'h9ABC_DEF0;
    begin
        $display("Starting AXI Lite read transaction test...");
        
        // AR channel
        @(posedge m_clk_rd);
        m_user_axi_if.arvalid = 1;
        m_user_axi_if.araddr = addr;
        
        // Wait for handshake
        wait(m_user_axi_if.arready);
        @(posedge m_clk_rd);
        m_user_axi_if.arvalid = 0;
        
        // Generate R response from slave
        @(posedge s_clk_rd);
        s_user_axi_if.rvalid = 1;
        s_user_axi_if.rdata = expected_data;
        s_user_axi_if.rresp = 2'b00; // OKAY
        
        wait(m_user_axi_if.rready);
        @(posedge s_clk_rd);
        s_user_axi_if.rvalid = 0;
        
        // Check received data
        if (m_user_axi_if.rdata !== expected_data) begin
            $error("Read data mismatch! Expected: 0x%h, Received: 0x%h", 
                expected_data, m_user_axi_if.rdata);
        end else begin
            $display("AXI Lite read transaction completed. Addr: 0x%h, Data: 0x%h", 
                    addr, expected_data);
        end
    end
    endtask
    
    // Monitor for any errors
    always @(posedge m_clk_wr) begin
        if (m_user_axi_if.bvalid && m_user_axi_if.bready && m_user_axi_if.bresp != 2'b00) begin
            $error("Write response error detected: %b", m_user_axi_if.bresp);
        end
    end
    
    always @(posedge m_clk_rd) begin
        if (m_user_axi_if.rvalid && m_user_axi_if.rready && m_user_axi_if.rresp != 2'b00) begin
            $error("Read response error detected: %b", m_user_axi_if.rresp);
        end
    end
    
endmodule