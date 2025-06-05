`timescale 1ns/1ps

supply1 HI;  // Global logic '1' (connects to vdd)
supply0 LO;  // Global logic '0' (connects to gnd)

module aib_axi_bridge_tb;

    // Parameters from the design
    parameter CLK_SCALING       = 4;
    parameter WR_CYCLE          = 2*CLK_SCALING; // Period = 8000 ns
    parameter RD_CYCLE          = 2*CLK_SCALING; // Period = 8000 ns
    parameter FWD_CYCLE         = 1*CLK_SCALING; // Period = 4000 ns
    parameter AVMM_CYCLE        = 4;             // Period = 4000 ns
    parameter OSC_CYCLE         = 1*CLK_SCALING; // Period = 4000 ns

    parameter NBR_CHNLS = 24;
    parameter NBR_BUMPS = 102;
    parameter NBR_PHASES = 4;
    parameter NBR_LANES = 40;
    parameter MS_SSR_LEN = 81;
    parameter SL_SSR_LEN = 73;
    parameter DWIDTH = 40;

    // Clock and reset
    reg m_clk_wr;         // Master-side AXI clocks
    reg s_clk_wr;         // Slave-side AXI clocks

    reg m_ns_fwd_clk;

    reg m_rst_wr_n;
    reg s_rst_wr_n;
    
    reg avmm_clk;
    reg avmm_rst_n;

    // Oscillator clock
    reg osc_clk;

    // Configuration signals
    wire i_conf_done;

    // Credit signals
    reg [7:0] m_init_ar_credit, m_init_aw_credit, m_init_w_credit;
    reg [7:0] s_init_r_credit, s_init_b_credit;

    // Delay values
    reg [15:0] m_delay_x_value, m_delay_y_value, m_delay_z_value;
    reg [15:0] s_delay_x_value, s_delay_y_value, s_delay_z_value;

    // `include "agent.sv" // Assuming axi_if is defined here or globally
    // AXI interfaces
    axi_if m_user_axi_if(); // Master user AXI interface (DUT's master port)
    axi_if s_user_axi_if(); // Slave user AXI interface (DUT's slave port)

    // Power supplies
    wire vddc1, vddc2, vddtx, vss;
    assign vddc1 = 1'b1;
    assign vddc2 = 1'b1;
    assign vddtx = 1'b1;
    assign vss   = 1'b0;

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

        .m_ns_fwd_clk(m_ns_fwd_clk),
        .m_ns_rcv_clk(m_ns_fwd_clk),

        // Master AXI Interface
        .m_clk_wr(m_clk_wr),
        .m_rst_wr_n(m_rst_wr_n),

        .m_init_ar_credit(m_init_ar_credit),
        .m_init_aw_credit(m_init_aw_credit),
        .m_init_w_credit(m_init_w_credit),
        
        .m_user_axi_if(m_user_axi_if),
        
        .m_delay_x_value(m_delay_x_value),
        .m_delay_y_value(m_delay_y_value),
        .m_delay_z_value(m_delay_z_value),

        // Slave AXI Interface
        .s_clk_wr(s_clk_wr),
        .s_rst_wr_n(s_rst_wr_n),
        
        .s_init_r_credit(s_init_r_credit),
        .s_init_b_credit(s_init_b_credit),
        
        .s_user_axi_if(s_user_axi_if),
        
        .s_delay_x_value(s_delay_x_value),
        .s_delay_y_value(s_delay_y_value),
        .s_delay_z_value(s_delay_z_value),

        .m_avmm_clk(avmm_clk),
        .m_avmm_rst_n(avmm_rst_n),

        .s_avmm_clk(avmm_clk),
        .s_avmm_rst_n(avmm_rst_n),

        // Common AIB signals
        .i_osc_clk(osc_clk),
        .i_conf_done(i_conf_done)
    );

    // Clock generation using initial forever style
    initial begin
        m_clk_wr = 1'b0; // Initialize
        forever #(WR_CYCLE/2) m_clk_wr = ~m_clk_wr;
    end

    initial begin
        m_ns_fwd_clk = 1'b0; // Initialize
        forever #(FWD_CYCLE/2) m_ns_fwd_clk = ~m_ns_fwd_clk;
    end

    initial begin
        s_clk_wr = 1'b0; // Initialize
        forever #(WR_CYCLE/2) s_clk_wr = ~s_clk_wr;
    end

    initial begin
        avmm_clk = 1'b0; // Initialize
        forever #(AVMM_CYCLE/2) avmm_clk = ~avmm_clk;
    end

    initial begin
        osc_clk = 1'b0; // Initialize
        forever #(OSC_CYCLE/2) osc_clk = ~osc_clk;
    end


    // Reset generation and other signal initialization
    initial begin
        // Note: Clock signals are now initialized in their own 'initial forever' blocks above.
        // Do not initialize them again here.

        // Initial reset states
        m_rst_wr_n   = 1'b0;
        s_rst_wr_n   = 1'b0;
        avmm_rst_n = 1'b0;

        // Initialize credit values
        m_init_ar_credit = 8'h8;
        m_init_aw_credit = 8'h8;
        m_init_w_credit  = 8'h8;
        s_init_r_credit  = 8'h8;
        s_init_b_credit  = 8'h8;

        // Initialize delay values
        m_delay_x_value = 16'h0;
        m_delay_y_value = 16'h0;
        m_delay_z_value = 16'h0;
        s_delay_x_value = 16'h0;
        s_delay_y_value = 16'h0;
        s_delay_z_value = 16'h0;

        // Release reset after some time
        wait (100ns); // Wait for 100 ns before releasing reset
        m_rst_wr_n   = 1'b1;
        s_rst_wr_n   = 1'b1;
        avmm_rst_n = 1'b1;

    end

    // Test sequence
    initial begin
        // Wait for reset to complete on relevant interfaces
        wait(m_rst_wr_n === 1'b1 && s_rst_wr_n === 1'b1);
        $display("[%0t ns] Resets de-asserted.", $time);

        // Initialize AXI interface signals (testbench side)
        initialize_axi_interfaces();
        $display("[%0t ns] AXI interfaces initialized.", $time);

        // Wait a bit more for everything to settle
        #100ns;

        // Run test cases
        test_axi_write_transaction();
        test_axi_read_transaction();

        // Finish simulation
        #100ns;
        $display("[%0t ns] All tests completed successfully!", $time);
        $finish;
    end

    // Initialize AXI interfaces (testbench perspective)
    task initialize_axi_interfaces;
    begin
        // Master AXI interface (m_user_axi_if): TB acts as slave memory to DUT's master port.
        m_user_axi_if.awvalid <= 0;
        m_user_axi_if.wvalid  <= 0;
        m_user_axi_if.bready  <= 1;
        m_user_axi_if.arvalid <= 0;
        m_user_axi_if.rready  <= 1;

        // Slave AXI interface (s_user_axi_if): TB acts as AXI master to DUT's slave port.
        s_user_axi_if.awvalid <= 0;
        s_user_axi_if.awaddr  <= 0;
        s_user_axi_if.awid    <= 0;
        s_user_axi_if.awlen   <= 0;
        s_user_axi_if.awsize  <= 0;
        s_user_axi_if.awburst <= 0;

        s_user_axi_if.wvalid <= 0;
        s_user_axi_if.wdata  <= 0;
        s_user_axi_if.wstrb  <= 0;
        s_user_axi_if.wlast  <= 0;

        s_user_axi_if.bready <= 1;

        s_user_axi_if.arvalid <= 0;
        s_user_axi_if.araddr  <= 0;
        s_user_axi_if.arid    <= 0;
        s_user_axi_if.arlen   <= 0;
        s_user_axi_if.arsize  <= 0;
        s_user_axi_if.arburst <= 0;

        s_user_axi_if.rready <= 1;
    end
    endtask

    // Test single write transaction (TB as master on s_user_axi_if)
    task test_axi_write_transaction;
        reg [31:0] addr = 32'h0000_1000;
        reg [31:0] data = 32'hABCD_1234;
        reg [3:0]  id   = 4'h1;
    begin
        $display("[%0t ns] Starting AXI write transaction test to Addr: 0x%h, Data: 0x%h", $time, addr, data);

        @(posedge s_clk_wr);
        s_user_axi_if.awvalid <= 1;
        s_user_axi_if.awaddr  <= addr;
        s_user_axi_if.awid    <= id;
        s_user_axi_if.awlen   <= 0;
        s_user_axi_if.awsize  <= 3'b010; // 4 Bytes
        s_user_axi_if.awburst <= 2'b01;

        wait (s_user_axi_if.awready === 1'b1 && s_user_axi_if.awvalid === 1'b1);
        @(posedge s_clk_wr);
        s_user_axi_if.awvalid <= 0;

        @(posedge s_clk_wr);
        s_user_axi_if.wvalid <= 1;
        s_user_axi_if.wdata  <= data;
        s_user_axi_if.wstrb  <= 4'hF;
        s_user_axi_if.wlast  <= 1;

        wait (s_user_axi_if.wready === 1'b1 && s_user_axi_if.wvalid === 1'b1);
        @(posedge s_clk_wr);
        s_user_axi_if.wvalid <= 0;
        s_user_axi_if.wlast  <= 0;

        s_user_axi_if.bready <= 1;
        wait (s_user_axi_if.bvalid === 1'b1 && s_user_axi_if.bready === 1'b1);
        @(posedge s_clk_wr);
        if (s_user_axi_if.bresp !== 2'b00) begin
            $error("[%0t ns] AXI write error response: %b, ID: %h", $time, s_user_axi_if.bresp, s_user_axi_if.bid);
        end else if (s_user_axi_if.bid !== id) begin
            $error("[%0t ns] AXI write response ID mismatch. Expected: %h, Got: %h", $time, id, s_user_axi_if.bid);
        end else begin
            $display("[%0t ns] AXI write transaction successful. Addr: 0x%h, Data: 0x%h, ID: %h", $time, addr, data, s_user_axi_if.bid);
        end
        s_user_axi_if.bready <= 0;
    end
    endtask

    // Test single read transaction (TB initiates on s_user_axi_if, acts as memory on m_user_axi_if)
    task test_axi_read_transaction;
        reg [31:0] addr          = 32'h0000_2000;
        reg [31:0] expected_data = 32'hDEAD_BEEF;
        reg [3:0]  id            = 4'h2;
    begin
        $display("[%0t ns] Starting AXI read transaction test for Addr: 0x%h", $time, addr);

        @(posedge s_clk_wr);
        s_user_axi_if.arvalid <= 1;
        s_user_axi_if.araddr  <= addr;
        s_user_axi_if.arid    <= id;
        s_user_axi_if.arlen   <= 0;
        s_user_axi_if.arsize  <= 3'b010; // 4 Bytes
        s_user_axi_if.arburst <= 2'b01;

        wait (s_user_axi_if.arready === 1'b1 && s_user_axi_if.arvalid === 1'b1);
        @(posedge s_clk_wr);
        s_user_axi_if.arvalid <= 0;

        wait (m_user_axi_if.arvalid === 1'b1);
        $display("[%0t ns] Read Address appeared on DUT master interface. ARID: %h", $time, m_user_axi_if.arid);

        @(posedge m_clk_wr);
        m_user_axi_if.arready <= 1;
        @(posedge m_clk_wr);
        m_user_axi_if.arready <= 0;

        @(posedge m_clk_wr);
        m_user_axi_if.rvalid <= 1;
        m_user_axi_if.rdata  <= expected_data;
        m_user_axi_if.rresp  <= 2'b00;
        m_user_axi_if.rid    <= m_user_axi_if.arid;
        m_user_axi_if.rlast  <= 1;

        wait (m_user_axi_if.rready === 1'b1 && m_user_axi_if.rvalid === 1'b1);
        @(posedge m_clk_wr);
        m_user_axi_if.rvalid <= 0;
        m_user_axi_if.rlast  <= 0;

        s_user_axi_if.rready <= 1;
        wait (s_user_axi_if.rvalid === 1'b1 && s_user_axi_if.rready === 1'b1);
        @(posedge s_clk_wr);

        if (s_user_axi_if.rdata !== expected_data) begin
            $error("[%0t ns] Read data mismatch! Expected: 0x%h, Got: 0x%h. Initial ARID: %h, DUT Rsp RID: %h",
                   $time, expected_data, s_user_axi_if.rdata, id, s_user_axi_if.rid);
        end else if (s_user_axi_if.rresp !== 2'b00) begin
            $error("[%0t ns] Read response error on slave interface: %b. Initial ARID: %h, DUT Rsp RID: %h",
                   $time, s_user_axi_if.rresp, id, s_user_axi_if.rid);
        end else if (s_user_axi_if.rid !== id) begin
            $error("[%0t ns] Read response ID mismatch on slave interface. Expected: %h, Got: %h",
                   $time, id, s_user_axi_if.rid);
        end else begin
            $display("[%0t ns] AXI read transaction successful. Addr: 0x%h, Data: 0x%h, ID: %h",
                     $time, addr, s_user_axi_if.rdata, s_user_axi_if.rid);
        end
    end
    endtask

    initial begin
        $dumpfile("waveform.vcd");
        $dumpvars(0, aib_axi_bridge_tb);
    end

endmodule