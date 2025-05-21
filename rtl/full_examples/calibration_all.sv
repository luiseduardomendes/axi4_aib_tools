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

task duts_wakeup ();
    begin
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
    end
endtask

task link_up (); 
    begin
        fork
            wait (intf_s1.ms_tx_transfer_en == {TOTAL_CHNL_NUM{1'b1}});
            wait (intf_s1.sl_tx_transfer_en == {TOTAL_CHNL_NUM{1'b1}});
        join
    end
endtask

integer i_m1, i_s1;

initial begin
begin
    status = "Reset DUT";
    $display("\n////////////////////////////////////////////////////////////////////////////");
    $display("%0t: AIB : Get into Main initial", $time);
    $display("////////////////////////////////////////////////////////////////////////////\n");
    reset_duts ();
    $display("\n////////////////////////////////////////////////////////////////////////////");
    $display("%0t: AIB : Finish reset_duts", $time);
    $display("////////////////////////////////////////////////////////////////////////////\n");

    $display("\n////////////////////////////////////////////////////////////////////////////");
    $display("\n////////////////////////////////////////////////////////////////////////////");
    $display("\n//                                                                       ///");
    $display("%0t: AIB : set to 2xFIFO mode for ms -> sl and sl -> ms 24 channel testing", $time);
    $display("%0t: AIB : Master is 2.0 AIB model in Gen1 mode", $time);
    $display("%0t: AIB : Slave is 1.0 FPGA", $time);
    $display("\n//                                                                       ///");
    $display("%0t: No dbi enabled", $time);
    $display("////////////////////////////////////////////////////////////////////////////\n");


    for (i_m1=0; i_m1<TOTAL_CHNL_NUM; i_m1++) begin
        avmm_if_m1.cfg_write({i_m1,11'h208}, 4'hf, 32'h0600_0000);
        avmm_if_m1.cfg_write({i_m1,11'h210}, 4'hf, 32'h0000_000b);      
        avmm_if_m1.cfg_write({i_m1,11'h218}, 4'hf, 32'h60a1_0000);
    /*
        avmm_if_m1.cfg_write({i_m1,11'h21c}, 4'hf, 32'h0000_0000);
        avmm_if_m1.cfg_write({i_m1,11'h31c}, 4'hf, 32'h0000_0000);
        avmm_if_m1.cfg_write({i_m1,11'h320}, 4'hf, 32'h0000_0000);
        avmm_if_m1.cfg_write({i_m1,11'h324}, 4'hf, 32'h0000_0000);
        avmm_if_m1.cfg_write({i_m1,11'h328}, 4'hf, 32'h0000_0000);
    */
    end

    ms1_tx_fifo_mode = 2'b01;
    sl1_tx_fifo_mode = 2'b01;
    ms1_rx_fifo_mode = 2'b01;
    sl1_rx_fifo_mode = 2'b01;
    ms1_tx_markbit   = 5'b00001;
    sl1_tx_markbit   = 5'b00001;
    ms1_gen1         = 1'b0;
    sl1_gen1         = 1'b1;

    //run_for_n_pkts_ms1 = 40;
    //run_for_n_pkts_sl1 = 40;

    $display("\n////////////////////////////////////////////////////////////////////////////");
    $display("%0t: AIB : Performing duts_wakeup", $time);
    $display("////////////////////////////////////////////////////////////////////////////\n");

    duts_wakeup ();
    status = "Waiting for link up";

    $display("\n////////////////////////////////////////////////////////////////////////////");
    $display("%0t: AIB : Waiting for link up", $time);
    $display("////////////////////////////////////////////////////////////////////////////\n");

    link_up ();
    status = "Starting data transmission"; 

    $display("\n////////////////////////////////////////////////////////////////////////////"); 
    $display("%0t: AIB : Starting data transmission", $time); 
    $display("////////////////////////////////////////////////////////////////////////////\n"); 
    

    status = "Finishing data transmission";
end
end
