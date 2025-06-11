`timescale 1ns / 1ps

module calib_master_fsm #(
    parameter TOTAL_CHNL_NUM = 24,
    parameter WAKEUP_DELAY_CYCLES = 100 // Delay for wakeup sequence
) (
    // Clock and Reset
    input                               clk,
    input                               rst_n,

    // AIB Interface from Slave
    input      [TOTAL_CHNL_NUM-1:0]     sl_tx_transfer_en,
    input      [TOTAL_CHNL_NUM-1:0]     sl_rx_transfer_en,

    // Outputs to control the AIB master
    output logic                        calib_done,
    output logic                        i_conf_done,
    output logic [TOTAL_CHNL_NUM-1:0]   ns_adapter_rstn,
    output logic [TOTAL_CHNL_NUM-1:0]   ns_mac_rdy,
    output logic [TOTAL_CHNL_NUM-1:0]   ms_rx_dcc_dll_lock_req,
    output logic [TOTAL_CHNL_NUM-1:0]   ms_tx_dcc_dll_lock_req,

    // Avalon-MM Interface for register access
    output logic [16:0]                 avmm_address_o,
    output logic                        avmm_read_o,
    output logic                        avmm_write_o,
    output logic [31:0]                 avmm_writedata_o,
    output logic [3:0]                  avmm_byteenable_o,
    input      [31:0]                   avmm_readdata_i,
    input                               avmm_readdatavalid_i,
    input                               avmm_waitrequest_i
);

    // FSM State definition
    typedef enum logic [7:0] {
        FSM_IDLE,
        FSM_SETUP_REGS_WR_208,
        FSM_SETUP_REGS_WR_210,
        FSM_SETUP_REGS_WR_218,
        FSM_SETUP_REGS_WR_33C,
        FSM_WAKE_UP,
        FSM_WAKE_UP_WAIT,
        FSM_PA_POLL_LOCK_RD,
        FSM_PA_POLL_LOCK_CHECK,
        FSM_PA_STEP4_RD,
        FSM_PA_STEP4_WR,
        FSM_PA_STEP6_RD,
        FSM_PA_STEP6_WR,
        FSM_PA_STEP8_RD_350,
        FSM_PA_STEP8_RD_34C,
        FSM_PA_STEP8_WR_34C,
        FSM_PA_STEP10_RD,
        FSM_PA_STEP10_WR,
        FSM_PA_STEP11_RD,
        FSM_PA_STEP11_WR,
        FSM_PA_STEP12_RD,
        FSM_PA_STEP12_WR,
        FSM_PA_STEP13_RD,
        FSM_PA_STEP13_WR,
        FSM_LINK_UP,
        FSM_DONE
    } fsm_state_t;

    fsm_state_t current_state, next_state;

    // Internal registers
    logic [5:0] channel_idx;
    logic [31:0] temp_rdata;
    logic [31:0] temp_wdata;
    logic [TOTAL_CHNL_NUM-1:0] rx_soc_clk_lock_mask;
    logic [31:0] delay_counter;

    // Sub-states for AVMM transactions
    logic avmm_op_done;
    logic avmm_wr_req, avmm_rd_req;

    // AVMM transaction FSM
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            avmm_write_o <= 1'b0;
            avmm_read_o <= 1'b0;
            avmm_op_done <= 1'b0;
        end else begin
            avmm_op_done <= 1'b0;
            avmm_write_o <= 1'b0;
            avmm_read_o  <= 1'b0;

            if (avmm_wr_req) begin
                avmm_write_o <= 1'b1;
                if (!avmm_waitrequest_i) begin
                    avmm_op_done <= 1'b1;
                    avmm_write_o <= 1'b0;
                end
            end else if (avmm_rd_req) begin
                avmm_read_o <= 1'b1;
                if (!avmm_waitrequest_i) begin
                    if (avmm_readdatavalid_i) begin
                        avmm_op_done <= 1'b1;
                        avmm_read_o <= 1'b0;
                    end
                end
            end
        end
    end

    // Main FSM
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_state <= FSM_IDLE;
            channel_idx <= '0;
            rx_soc_clk_lock_mask <= '0;
            calib_done <= 1'b0;
            i_conf_done <= 1'b0;
            ns_adapter_rstn <= '0;
            ns_mac_rdy <= '0;
            ms_rx_dcc_dll_lock_req <= '0;
            ms_tx_dcc_dll_lock_req <= '0;
            delay_counter <= '0;
        end else begin
            current_state <= next_state;

            // Update counters and registers based on state
            case(current_state)
                FSM_PA_POLL_LOCK_RD: begin
                    if (avmm_op_done) begin
                        rx_soc_clk_lock_mask[channel_idx] <= avmm_readdata_i[27];
                    end
                end
                FSM_PA_STEP8_RD_350: begin
                    if (avmm_op_done) temp_rdata <= avmm_readdata_i;
                end
                FSM_WAKE_UP_WAIT: begin
                    delay_counter <= delay_counter + 1;
                end
            endcase

            if (next_state != current_state) begin
                if (next_state == FSM_SETUP_REGS_WR_208) channel_idx <= 0;
                if ( (current_state == FSM_SETUP_REGS_WR_33C) && (channel_idx == TOTAL_CHNL_NUM-1) ) begin
                    // Done with setup regs
                end else if (current_state == FSM_SETUP_REGS_WR_33C || current_state == FSM_PA_POLL_LOCK_CHECK ||
                             (current_state >= FSM_PA_STEP4_WR && current_state <= FSM_PA_STEP13_WR && current_state[0] == 1)) begin
                     if (channel_idx == TOTAL_CHNL_NUM-1) channel_idx <= 0;
                     else channel_idx <= channel_idx + 1;
                end
                
                if(next_state == FSM_WAKE_UP_WAIT) delay_counter <= 0;

                // Set outputs based on next state
                if(next_state == FSM_WAKE_UP) begin
                    i_conf_done <= 1'b1;
                    ns_mac_rdy <= {TOTAL_CHNL_NUM{1'b1}};
                end
                if(next_state == FSM_PA_POLL_LOCK_RD) begin
                    ns_adapter_rstn <= {TOTAL_CHNL_NUM{1'b1}};
                    ms_rx_dcc_dll_lock_req <= {TOTAL_CHNL_NUM{1'b1}};
                    ms_tx_dcc_dll_lock_req <= {TOTAL_CHNL_NUM{1'b1}};
                end
                 if(next_state == FSM_DONE) begin
                    calib_done <= 1'b1;
                end
            end
        end
    end

    // FSM transitions and combinational logic
    always_comb begin
        next_state = current_state;
        avmm_address_o = '0;
        avmm_writedata_o = '0;
        avmm_byteenable_o = 4'hF;
        avmm_wr_req = 1'b0;
        avmm_rd_req = 1'b0;
        temp_wdata = '0;
        
        case (current_state)
            FSM_IDLE: next_state = FSM_SETUP_REGS_WR_208;

            // Setup Registers
            FSM_SETUP_REGS_WR_208: begin
                avmm_address_o = {channel_idx[4:0], 11'h208};
                avmm_writedata_o = 32'h0600_0000;
                avmm_wr_req = 1'b1;
                if (avmm_op_done) next_state = FSM_SETUP_REGS_WR_210;
            end
            FSM_SETUP_REGS_WR_210: begin
                avmm_address_o = {channel_idx[4:0], 11'h210};
                avmm_writedata_o = 32'h0000_0006;
                avmm_wr_req = 1'b1;
                if (avmm_op_done) next_state = FSM_SETUP_REGS_WR_218;
            end
            FSM_SETUP_REGS_WR_218: begin
                avmm_address_o = {channel_idx[4:0], 11'h218};
                avmm_writedata_o = 32'h6060_0000;
                avmm_wr_req = 1'b1;
                if (avmm_op_done) next_state = FSM_SETUP_REGS_WR_33C;
            end
            FSM_SETUP_REGS_WR_33C: begin
                avmm_address_o = {channel_idx[4:0], 11'h33C};
                avmm_writedata_o = 32'h4000_0000;
                avmm_wr_req = 1'b1;
                if (avmm_op_done) begin
                    if (channel_idx == TOTAL_CHNL_NUM-1) next_state = FSM_WAKE_UP;
                    else next_state = FSM_SETUP_REGS_WR_208;
                end
            end

            // Wake up DUTs
            FSM_WAKE_UP: next_state = FSM_WAKE_UP_WAIT;
            FSM_WAKE_UP_WAIT: begin
                if (delay_counter == WAKEUP_DELAY_CYCLES * 2) next_state = FSM_PA_POLL_LOCK_RD;
            end

            // Phase Adjust
            FSM_PA_POLL_LOCK_RD: begin
                avmm_address_o = {channel_idx[4:0], 11'h344};
                avmm_rd_req = 1'b1;
                if (avmm_op_done) next_state = FSM_PA_POLL_LOCK_CHECK;
            end
            FSM_PA_POLL_LOCK_CHECK: begin
                if (rx_soc_clk_lock_mask[channel_idx] == 1'b1) begin
                     if (channel_idx == TOTAL_CHNL_NUM-1) begin
                        if (&rx_soc_clk_lock_mask) next_state = FSM_PA_STEP4_RD;
                        else next_state = FSM_PA_POLL_LOCK_RD; // Start polling again
                     end else begin
                        next_state = FSM_PA_POLL_LOCK_RD; // Next channel
                     end
                end else begin
                    next_state = FSM_PA_POLL_LOCK_RD; // Poll again
                end
            end

            // Phase Adjust steps...
            // Step 4
            FSM_PA_STEP4_RD: begin
                avmm_address_o = {channel_idx[4:0], 11'h344};
                avmm_rd_req = 1'b1;
                if (avmm_op_done) next_state = FSM_PA_STEP4_WR;
            end
            FSM_PA_STEP4_WR: begin
                temp_wdata = avmm_readdata_i;
                temp_wdata[19:16] = (avmm_readdata_i[11:8] >= 2) ? (avmm_readdata_i[11:8]-2) : (14+avmm_readdata_i[11:8]);
                avmm_address_o = {channel_idx[4:0], 11'h344};
                avmm_writedata_o = temp_wdata;
                avmm_wr_req = 1'b1;
                if (avmm_op_done) begin
                    if (channel_idx == TOTAL_CHNL_NUM-1) next_state = FSM_PA_STEP6_RD;
                    else next_state = FSM_PA_STEP4_RD;
                end
            end
            // Step 6: Read rx_adp_clkph_code and write value + 6
            FSM_PA_STEP6_RD: begin
                avmm_address_o = {channel_idx[4:0], 11'h344};
                avmm_rd_req = 1'b1;
                if (avmm_op_done) next_state = FSM_PA_STEP6_WR;
            end
            FSM_PA_STEP6_WR: begin
                temp_wdata = avmm_readdata_i;
                temp_wdata[23:20] = avmm_readdata_i[15:12] + 6;
                avmm_address_o = {channel_idx[4:0], 11'h344};
                avmm_writedata_o = temp_wdata;
                avmm_wr_req = 1'b1;
                if (avmm_op_done) begin
                    if (channel_idx == TOTAL_CHNL_NUM-1) next_state = FSM_PA_STEP8_RD_350;
                    else next_state = FSM_PA_STEP6_RD;
                end
            end

            // Step 8: Read tx_adp_clkph_code from txdll2 (350), then txdll1 (34C), then write value+8 to txpi_ack_code
            FSM_PA_STEP8_RD_350: begin
                avmm_address_o = {channel_idx[4:0], 11'h350};
                avmm_rd_req = 1'b1;
                if (avmm_op_done) next_state = FSM_PA_STEP8_RD_34C;
            end
            FSM_PA_STEP8_RD_34C: begin
                temp_rdata = avmm_readdata_i; // Save tx_adp_clkph_code
                avmm_address_o = {channel_idx[4:0], 11'h34C};
                avmm_rd_req = 1'b1;
                if (avmm_op_done) next_state = FSM_PA_STEP8_WR_34C;
            end
            FSM_PA_STEP8_WR_34C: begin
                temp_wdata = avmm_readdata_i;
                temp_wdata[11:8] = temp_rdata[23:20] + 8;
                avmm_address_o = {channel_idx[4:0], 11'h34C};
                avmm_writedata_o = temp_wdata;
                avmm_wr_req = 1'b1;
                if (avmm_op_done) begin
                    if (channel_idx == TOTAL_CHNL_NUM-1) next_state = FSM_PA_STEP10_RD;
                    else next_state = FSM_PA_STEP8_RD_350;
                end
            end

            // Step 10: Read tx_soc_clkph_code from txdll2 (350), then write to txpi_socclk_code[3:0]
            FSM_PA_STEP10_RD: begin
                avmm_address_o = {channel_idx[4:0], 11'h350};
                avmm_rd_req = 1'b1;
                if (avmm_op_done) next_state = FSM_PA_STEP10_WR;
            end
            FSM_PA_STEP10_WR: begin
                temp_wdata = avmm_readdata_i;
                temp_wdata[3:0] = (avmm_readdata_i[19:16] >= 2) ? (avmm_readdata_i[19:16]-2) : (14+avmm_readdata_i[19:16]);
                avmm_address_o = {channel_idx[4:0], 11'h350};
                avmm_writedata_o = temp_wdata;
                avmm_wr_req = 1'b1;
                if (avmm_op_done) begin
                    if (channel_idx == TOTAL_CHNL_NUM-1) next_state = FSM_PA_STEP11_RD;
                    else next_state = FSM_PA_STEP10_RD;
                end
            end

            // Step 11: Set rxpi_sclk_code_ovrd, rxpi_aclk_code_ovrd, rxsoc_lock_ovrd, rxadp_lock_ovrd in rxdll2 (344)
            FSM_PA_STEP11_RD: begin
                avmm_address_o = {channel_idx[4:0], 11'h344};
                avmm_rd_req = 1'b1;
                if (avmm_op_done) next_state = FSM_PA_STEP11_WR;
            end
            FSM_PA_STEP11_WR: begin
                temp_wdata = avmm_readdata_i;
                temp_wdata[31] = 1; // rxpi_aclk_code_ovrd
                temp_wdata[30] = 1; // rxpi_sclk_code_ovrd
                temp_wdata[29] = 1; // rxadp_lock_ovrd
                temp_wdata[28] = 1; // rxsoc_lock_ovrd
                avmm_address_o = {channel_idx[4:0], 11'h344};
                avmm_writedata_o = temp_wdata;
                avmm_wr_req = 1'b1;
                if (avmm_op_done) begin
                    if (channel_idx == TOTAL_CHNL_NUM-1) next_state = FSM_PA_STEP12_RD;
                    else next_state = FSM_PA_STEP11_RD;
                end
            end

            // Step 12: Set txpi_aclk_code_ovrd, txpi_sclk_code_ovrd, txadp_lock_ovrd, txsoc_lock_ovrd in txdll2 (350)
            FSM_PA_STEP12_RD: begin
                avmm_address_o = {channel_idx[4:0], 11'h350};
                avmm_rd_req = 1'b1;
                if (avmm_op_done) next_state = FSM_PA_STEP12_WR;
            end
            FSM_PA_STEP12_WR: begin
                temp_wdata = avmm_readdata_i;
                temp_wdata[31] = 1; // txpi_aclk_code_ovrd
                temp_wdata[28] = 1; // txpi_sclk_code_ovrd
                temp_wdata[27] = 1; // txadp_lock_ovrd
                temp_wdata[26] = 1; // txsoc_lock_ovrd
                avmm_address_o = {channel_idx[4:0], 11'h350};
                avmm_writedata_o = temp_wdata;
                avmm_wr_req = 1'b1;
                if (avmm_op_done) begin
                    if (channel_idx == TOTAL_CHNL_NUM-1) next_state = FSM_PA_STEP13_RD;
                    else next_state = FSM_PA_STEP12_RD;
                end
            end

            // Step 13: Clear vcalcode_ovrd bit of calvref register (33C)
            FSM_PA_STEP13_RD: begin
                avmm_address_o = {channel_idx[4:0], 11'h33C};
                avmm_rd_req = 1'b1;
                if (avmm_op_done) next_state = FSM_PA_STEP13_WR;
            end
            FSM_PA_STEP13_WR: begin
                temp_wdata = avmm_readdata_i;
                temp_wdata[30] = 1'b0; // Clear vcalcode_ovrd
                avmm_address_o = {channel_idx[4:0], 11'h33C};
                avmm_writedata_o = temp_wdata;
                avmm_wr_req = 1'b1;
                if (avmm_op_done) begin
                    if (channel_idx == TOTAL_CHNL_NUM-1) next_state = FSM_LINK_UP;
                    else next_state = FSM_PA_STEP13_RD;
                end
            end

            FSM_LINK_UP: begin
                if (&sl_tx_transfer_en && &sl_rx_transfer_en) begin
                    next_state = FSM_DONE;
                end
            end
            FSM_DONE: begin
                // Stay here
            end
            default: next_state = FSM_IDLE;
        endcase
    end
endmodule