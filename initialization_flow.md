# Tasks

## Write
```verilog
task cfg_write (
    input [16:0] addr,
    input [BYTE_WIDTH-1:0] be,
    input [AVMM_WIDTH-1:0] wdata);

    begin
        @(posedge clk);
        write       <= 1'b1;
        read        <= 1'b0;
        address     <= addr;
        byteenable  <= be;
        writedata   <= wdata;
        $display("%0t: WRITE_MM: address %x wdata =  %x", $time, addr, wdata);
        @(negedge waitrequest);
        @(posedge clk);
        write       <= 1'b0;
    end
endtask
```

## Read

``` verilog
task cfg_read (
    input  [16:0] addr,
    input  [BYTE_WIDTH-1:0] be,
    output [AVMM_WIDTH-1:0] rdata);

    begin
        @(posedge clk);
        write       <= 1'b0;
        read        <= 1'b1;
        address     <= addr;
        byteenable  <= be;
        @(negedge waitrequest);
        @(posedge clk);
        read        <= 1'b0;
        @(posedge readdatavalid);
        @(negedge clk);
        rdata <= readdata;
        @(posedge clk);
        $display("%0t: READ_MM: address %x rdata =  %x", $time, addr, rdata);

    end
endtask
```

# Initialization Procedure

## Reseting DUTs

```verilog
task reset_duts ();
    begin
        $display("\n////////////////////////////////////////////////////////////////////////////");
        $display("%0t: Into task reset_dut", $time);
        $display("////////////////////////////////////////////////////////////////////////////\n");

        top_tb.err_count = 0;
        avmm_if_m1.rst_n = 1'b0;
        avmm_if_m1.address = '0;
        avmm_if_m1.write = 1'b0;
        avmm_if_m1.read  = 1'b0;
        avmm_if_m1.writedata = '0;
        avmm_if_m1.byteenable = '0;
        avmm_if_s1.rst_n = 1'b0;
        avmm_if_s1.address = '0;
        avmm_if_s1.write = 1'b0;
        avmm_if_s1.read  = 1'b0;
        avmm_if_s1.writedata = '0;
        avmm_if_s1.byteenable = '0;

        intf_s1.i_conf_done     = 1'b0;
        intf_s1.ns_mac_rdy      = '0;
        intf_s1.ns_adapter_rstn = '0;
        intf_s1.sl_rx_dcc_dll_lock_req = '0;
        intf_s1.sl_tx_dcc_dll_lock_req = '0;

        intf_m1.i_conf_done = 1'b0;
        intf_m1.ns_mac_rdy      = '0;
        intf_m1.ns_adapter_rstn = '0;
        intf_m1.ms_rx_dcc_dll_lock_req = '0;
        intf_m1.ms_tx_dcc_dll_lock_req = '0;
        #100ns;

        intf_m1.m_por_ovrd = 1'b1;   
        intf_s1.m_device_detect_ovrd = 1'b0;
        intf_s1.i_m_power_on_reset = 1'b0;

        intf_m1.data_in = {TOTAL_CHNL_NUM{80'b0}};
        intf_s1.data_in = {TOTAL_CHNL_NUM{80'b0}};

        intf_m1.data_in_f = {TOTAL_CHNL_NUM{320'b0}};
        intf_s1.data_in_f = {TOTAL_CHNL_NUM{320'b0}};

        intf_m1.gen1_data_in = {TOTAL_CHNL_NUM{40'b0}};

        intf_m1.gen1_data_in_f = {TOTAL_CHNL_NUM{320'b0}};
        intf_s1.gen1_data_in_f = {TOTAL_CHNL_NUM{80'b0}};

        #100ns;
        intf_s1.i_m_power_on_reset = 1'b1;
        $display("\n////////////////////////////////////////////////////////////////////////////");
        $display("%0t: Follower (Slave) power_on_reset asserted", $time);
        $display("////////////////////////////////////////////////////////////////////////////\n");

        #200ns;
        intf_s1.i_m_power_on_reset = 1'b0;
        $display("\n////////////////////////////////////////////////////////////////////////////");
        $display("%0t: Follower (Slave)  power_on_reset de-asserted", $time);
        $display("////////////////////////////////////////////////////////////////////////////\n");

        #200ns;
        avmm_if_m1.rst_n = 1'b1;
        avmm_if_s1.rst_n = 1'b1;

        #100ns;
        $display("%0t: %m: de-asserting configuration reset and start configuration setup", $time);
    end
endtask
```

## Setting up registers

```verilog
fork
    for (i_m1=0; i_m1<24; i_m1++) begin
        avmm_if_m1.cfg_write({i_m1,11'h208}, 4'hf, 32'h0600_0000);
        avmm_if_m1.cfg_write({i_m1,11'h210}, 4'hf, 32'h0000_0006);      
        avmm_if_m1.cfg_write({i_m1,11'h218}, 4'hf, 32'h6060_0000);
        avmm_if_m1.cfg_write({i_m1,11'h33C}, 4'hf, 32'h4000_0000);
    end
    for (i_s1=0; i_s1<24; i_s1++) begin
        avmm_if_s1.cfg_write({i_s1,11'h208}, 4'hf, 32'h0600_0000);
        avmm_if_s1.cfg_write({i_s1,11'h210}, 4'hf, 32'h0000_0006);
        avmm_if_s1.cfg_write({i_s1,11'h218}, 4'hf, 32'h6060_0000);
        avmm_if_s1.cfg_write({i_s1,11'h33C}, 4'hf, 32'h4000_0000);
    end
join
```

## DUTs Wake Up

```verilog
intf_m1.i_conf_done = 1'b1;
intf_s1.i_conf_done = 1'b1;

intf_m1.ns_mac_rdy = {TOTAL_CHNL_NUM{1'b1}}; 
intf_s1.ns_mac_rdy = {TOTAL_CHNL_NUM{1'b1}}; 

#1000ns;
intf_m1.ns_adapter_rstn = {TOTAL_CHNL_NUM{1'b1}};
intf_s1.ns_adapter_rstn = {TOTAL_CHNL_NUM{1'b1}};
#1000ns;
intf_s1.sl_rx_dcc_dll_lock_req = {TOTAL_CHNL_NUM{1'b1}};
intf_s1.sl_tx_dcc_dll_lock_req = {TOTAL_CHNL_NUM{1'b1}};

intf_m1.ms_rx_dcc_dll_lock_req = {TOTAL_CHNL_NUM{1'b1}};
intf_m1.ms_tx_dcc_dll_lock_req = {TOTAL_CHNL_NUM{1'b1}};
```

## Phase adjust
```verilog
task ms_phase_adjust_wrkarnd ();
    integer i_m1;
    logic [31:0] rdata = 32'h0;
    logic [31:0] wdata = 32'h0;
    logic [23:0] rx_soc_clk_lock = 32'h0;
    begin
        //1. Done during configuration phase, set vcalcode_ovrd bit of calvref register 33c
        //2. Poll the rx_soc_clk_lock bit of rxdll2 (344) register until the bit is set by the hardware
        while (rx_soc_clk_lock !== 24'hff_ffff) begin
            #1000ns;
            for (i_m1=0; i_m1<24; i_m1++) begin
            avmm_if_m1.cfg_read({i_m1, 11'h344}, 4'hf, rdata);
            rx_soc_clk_lock[i_m1] = rdata[27];
            end
            $display("%0t: leader rx_soc_clk_lock polling:  rx_soc_clk_lock =  %x", $time, rx_soc_clk_lock);
        end 
        //3. Read rx_soc_clkph_code[3:0] field of rxdll2 reg
        //4. If the value read in step 3 is less then 2, plus 14, else, minus 2.
        for (i_m1=0; i_m1<24; i_m1++) begin
            avmm_if_m1.cfg_read({i_m1, 11'h344}, 4'hf, rdata);
            rdata[19:16] = (rdata[11:8] >= 2) ? (rdata[11:8]-2) : (14+rdata[11:8]);
            avmm_if_m1.cfg_write({i_m1,11'h344}, 4'hf, rdata);
        end
        //5. Read rx_adp_clkph_code[3:0] field of rxdll2 register
        //6. Write the value read in step 5 plus 6
        for (i_m1=0; i_m1<24; i_m1++) begin
            avmm_if_m1.cfg_read({i_m1, 11'h344}, 4'hf, rdata);
            rdata[23:20] = rdata[15:12] + 6;
            avmm_if_m1.cfg_write({i_m1,11'h344}, 4'hf, rdata);
        end
        //7. Read tx_adp_clkph_code[3;0] field of txdll2 register 350
        //8. Write the value read in step 7 plus 8 into txpi_ack_code [3:0] field of txdll1 register. Only LSB 4 bit.
        for (i_m1=0; i_m1<24; i_m1++) begin
            avmm_if_m1.cfg_read({i_m1, 11'h350}, 4'hf, rdata);
            wdata[11:8] = rdata[23:20]+8;
            avmm_if_m1.cfg_read({i_m1, 11'h34C}, 4'hf, rdata);
            rdata[11:8]=wdata[11:8];
            avmm_if_m1.cfg_write({i_m1,11'h34C}, 4'hf, rdata);
        end
        //9. Read tx_soc_clkph_code[3:0] field of txdll2 register 350
        //10.If the value read in step 9 is less than 2, write the value read in step 9 plus 14 into txpi_socclk_code[3:0]
        //   Otherwise, write the value minus 2 into txpi_socclk_code[3:0] field of txdll2 register.
        for (i_m1=0; i_m1<24; i_m1++) begin
            avmm_if_m1.cfg_read({i_m1, 11'h350}, 4'hf, rdata);
            rdata[3:0]=(rdata[19:16] >= 2) ? (rdata[19:16]-2) : (14+rdata[19:16]);;
            avmm_if_m1.cfg_write({i_m1,11'h350}, 4'hf, rdata);
        end
        //11. Set rxpi_sclk_code_ovrd, rxpi_aclk_code_ovrd, rxsoc_lock_ovrd and rxadp_lock_ovrd bits of rxdll2 register.
        for (i_m1=0; i_m1<24; i_m1++) begin
            avmm_if_m1.cfg_read({i_m1, 11'h344}, 4'hf, rdata);
            rdata[31]=1; //rpi_aclk_code_ovrd
            rdata[30]=1; //rpi_sclk_code_ovrd
            rdata[29]=1; //rxapd_lock_ovrd
            rdata[28]=1; //rxsoc_lock_ovrd
            avmm_if_m1.cfg_write({i_m1, 11'h344}, 4'hf, rdata);
        end
        //12. Set txpi_aclk_code_ovrd and txsoc_lock_ovrd bits of txdll2 register
        for (i_m1=0; i_m1<24; i_m1++) begin
            avmm_if_m1.cfg_read({i_m1, 11'h350}, 4'hf, rdata);
            rdata[31] = 1; // txpi_aclk_code_ovrd
            rdata[27] = 1; // txadp_lock_ovrd
            rdata[28] = 1; // txpi_sclk_code_ovrd
            rdata[26] = 1; // txsoc_lock_ovrd
            avmm_if_m1.cfg_write({i_m1, 11'h350}, 4'hf, rdata);
        end
        //13. Clear vcalcode_ovrd bit of calvref register
        for (i_m1=0; i_m1<24; i_m1++) begin
            avmm_if_m1.cfg_read({i_m1, 11'h33C}, 4'hf, rdata);
            rdata[30] = 0;
            avmm_if_m1.cfg_write({i_m1, 11'h33C}, 4'hf, rdata);
        end
    end
endtask

task sl_phase_adjust_wrkarnd ();
    integer i_s1;
    logic [31:0] rdata = 32'h0;
    logic [31:0] wdata = 32'h0;
    logic [23:0] rx_soc_clk_lock = 32'h0;
    begin
        //1. Done during configuration phase, set vcalcode_ovrd bit of calvref register 33c
        //2. Poll the rx_soc_clk_lock bit of rxdll2 (344) register until the bit is set by the hardware
        while (rx_soc_clk_lock !== 24'hff_ffff) begin
            #1000ns;
            for (i_s1=0; i_s1<24; i_s1++) begin
                avmm_if_s1.cfg_read({i_s1, 11'h344}, 4'hf, rdata);
                rx_soc_clk_lock[i_s1] = rdata[27];
            end
            $display("%0t: leader rx_soc_clk_lock polling:  rx_soc_clk_lock =  %x", $time, rx_soc_clk_lock);
        end 
        //3. Read rx_soc_clkph_code[3:0] field of rxdll2 reg
        //4. If the value read in step 3 is less then 2, plus 14, else, minus 2.
        for (i_s1=0; i_s1<24; i_s1++) begin
            avmm_if_s1.cfg_read({i_s1, 11'h344}, 4'hf, rdata);
            rdata[19:16] = (rdata[11:8] >= 2) ? (rdata[11:8]-2) : (14+rdata[11:8]);
            avmm_if_s1.cfg_write({i_s1,11'h344}, 4'hf, rdata);
        end
        //5. Read rx_adp_clkph_code[3:0] field of rxdll2 register
        //6. Write the value read in step 5 plus 6
        for (i_s1=0; i_s1<24; i_s1++) begin
            avmm_if_s1.cfg_read({i_s1, 11'h344}, 4'hf, rdata);
            rdata[23:20] = rdata[15:12] + 6;
            avmm_if_s1.cfg_write({i_s1,11'h344}, 4'hf, rdata);
        end
        //7. Read tx_adp_clkph_code[3;0] field of txdll2 register 350
        //8. Write the value read in step 7 plus 8 into txpi_ack_code [3:0] field of txdll1 register. Only LSB 4 bit.
        for (i_s1=0; i_s1<24; i_s1++) begin
            avmm_if_s1.cfg_read({i_s1, 11'h350}, 4'hf, rdata);
            wdata[11:8] = rdata[23:20]+8;
            avmm_if_s1.cfg_read({i_s1, 11'h34C}, 4'hf, rdata);
            rdata[11:8]=wdata[11:8];
            avmm_if_s1.cfg_write({i_s1,11'h34C}, 4'hf, rdata);
        end
        //9. Read tx_soc_clkph_code[3:0] field of txdll2 register 350
        //10.If the value read in step 9 is less than 2, write the value read in step 9 plus 14 into txpi_socclk_code[3:0]
        //   Otherwise, write the value minus 2 into txpi_socclk_code[3:0] field of txdll2 register.
        for (i_s1=0; i_s1<24; i_s1++) begin
            avmm_if_s1.cfg_read({i_s1, 11'h350}, 4'hf, rdata);
            rdata[3:0]=(rdata[19:16] >= 2) ? (rdata[19:16]-2) : (14+rdata[19:16]);;
            avmm_if_s1.cfg_write({i_s1,11'h350}, 4'hf, rdata);
        end
        //11. Set rxpi_sclk_code_ovrd, rxpi_aclk_code_ovrd, rxsoc_lock_ovrd and rxadp_lock_ovrd bits of rxdll2 register.
        for (i_s1=0; i_s1<24; i_s1++) begin
            avmm_if_s1.cfg_read({i_s1, 11'h344}, 4'hf, rdata);
            rdata[31]=1; //rpi_aclk_code_ovrd
            rdata[30]=1; //rpi_sclk_code_ovrd
            rdata[29]=1; //rxapd_lock_ovrd
            rdata[28]=1; //rxsoc_lock_ovrd
            avmm_if_s1.cfg_write({i_s1, 11'h344}, 4'hf, rdata);
        end
        //12. Set txpi_aclk_code_ovrd and txsoc_lock_ovrd bits of txdll2 register
        for (i_s1=0; i_s1<24; i_s1++) begin
            avmm_if_s1.cfg_read({i_s1, 11'h350}, 4'hf, rdata);
            rdata[31] = 1; // txpi_aclk_code_ovrd
            rdata[27] = 1; // txadp_lock_ovrd
            rdata[28] = 1; // txpi_sclk_code_ovrd
            rdata[26] = 1; // txsoc_lock_ovrd
            avmm_if_s1.cfg_write({i_s1, 11'h350}, 4'hf, rdata);
        end
        //13. Clear vcalcode_ovrd bit of calvref register
        for (i_s1=0; i_s1<24; i_s1++) begin
            avmm_if_s1.cfg_read({i_s1, 11'h33C}, 4'hf, rdata);
            rdata[30] = 0;
            avmm_if_s1.cfg_write({i_s1, 11'h33C}, 4'hf, rdata);
        end
     end
  endtask
```
## Link Up

```verilog
begin
    fork
        wait (intf_s1.ms_tx_transfer_en == {TOTAL_CHNL_NUM{1'b1}});
        wait (intf_s1.sl_tx_transfer_en == {TOTAL_CHNL_NUM{1'b1}});
    join
end
```

# Architecture

The implementation of a synthesizable FSM module for
- Master Side 
- Slave Side

It will be instantiated inside a top module containing
- Master or Slave AXI
- Master or Slave AIB

Expected hierarchy
- AXI FSM 
- FSM for setting up registers
    - Master Side
    - Slave Side
- FSM for phase adjust
    - Master side
    - Slave side
- Master Side top FSM 
- Slave Side top FSM

# Implementation
## AXI FSM
Implement a FSM that executes read and write in a given register.

## FSM for setting up registers
Uses the previously mentioned AXI FSMs to implement a FSM that executes the setting up phase, separating master from slave

## FSM for phase adjust
Uses the AXI FSMs to perform the phase adjust task by creating another FSM, also separating master and slave

## Top Module for Master and Slave
A top module that integrates all the previously mentioned FSMs, adjusting correctly the signals in the interface that will be shown later.

# Expected interface

## Master Side

```verilog

    calib_master_fsm #(
        .TOTAL_CHNL_NUM(NBR_CHNLS)
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
```

## Slave Side

```verilog

    calib_slave_fsm #(
        .TOTAL_CHNL_NUM(NBR_CHNLS)
    ) u_calib_slave_fsm (
        .clk                (avmm_clk),
        .rst_n              (avmm_rst_n),
        .ms_rx_dcc_dll_lock_req (intf_s1.ms_rx_dcc_dll_lock_req),
        .ms_tx_dcc_dll_lock_req (intf_s1.ms_tx_dcc_dll_lock_req),

        .i_conf_done        (intf_s1.i_conf_done),
        .ns_mac_rdy         (intf_s1.ns_mac_rdy),
        .ns_adapter_rstn    (intf_s1.ns_adapter_rstn),
        .sl_rx_dcc_dll_lock_req (intf_s1.sl_rx_dcc_dll_lock_req),
        .sl_tx_dcc_dll_lock_req (intf_s1.sl_tx_dcc_dll_lock_req),
        .sl_tx_transfer_en  (intf_s1.sl_tx_transfer_en),
        .sl_rx_transfer_en  (intf_s1.sl_rx_transfer_en),

        // Avalon-MM interface connections
        .avmm_address_o     (avmm_if_s1.address),
        .avmm_writedata_o   (avmm_if_s1.writedata),
        .avmm_byteenable_o  (avmm_if_s1.byteenable),
        .avmm_write_o       (avmm_if_s1.write),
        .avmm_read_o        (avmm_if_s1.read),
        .avmm_waitrequest_i (avmm_if_s1.waitrequest),
        .avmm_readdata_i    (avmm_if_s1.readdata),
        .avmm_readdatavalid_i(avmm_if_s1.readdatavalid)
    );

```