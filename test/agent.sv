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
