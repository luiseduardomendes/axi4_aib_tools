// This module implements a synthesizable FSM for the 'ms_phase_adjust_wrkarnd'
// task. It handles a complex sequence of polling for lock signals and performing
// multiple read-modify-write operations across 24 channels on the master AIB interface.

module ms_phase_adjust_wrkarnd_fsm #(
    parameter CLK_FREQ_MHZ = 100,
    parameter AVMM_WIDTH   = 32,
    parameter BYTE_WIDTH   = 4,
    parameter ADDR_WIDTH   = 16
) (
    input  bit clk,
    input  bit rst_n,

    // Control signals
    input  bit start,
    output logic done,

    // Avalon MM Interface signals (to be connected to an avalon_mm_fsm instance)
    output logic                      transaction_start,
    output logic                      transaction_is_write,
    output logic [ADDR_WIDTH-1:0]     transaction_addr,
    output logic [AVMM_WIDTH-1:0]     transaction_wdata,
    output logic [BYTE_WIDTH-1:0]     transaction_be,
    input  bit                        transaction_done,
    input  bit [AVMM_WIDTH-1:0]       transaction_rdata
);

    // FSM State Definitions
    typedef enum logic [7:0] {
        IDLE,
        // Polling for rx_soc_clk_lock
        POLL_DELAY,
        POLL_LOOP_START,
        POLL_READ_SETUP,
        POLL_READ_WAIT,
        POLL_UPDATE_LOCK_STATUS,
        POLL_LOOP_CHECK,
        POLL_EVALUATE,
        // Step 3 & 4: Adjust rx_soc_clkph_code
        S3_4_LOOP_START,
        S3_4_READ_SETUP, S3_4_READ_WAIT,
        S3_4_WRITE_SETUP, S3_4_WRITE_WAIT,
        S3_4_LOOP_CHECK,
        // Step 5 & 6: Adjust rx_adp_clkph_code
        S5_6_LOOP_START,
        S5_6_READ_SETUP, S5_6_READ_WAIT,
        S5_6_WRITE_SETUP, S5_6_WRITE_WAIT,
        S5_6_LOOP_CHECK,
        // Step 7 & 8: Adjust txpi_ack_code
        S7_8_LOOP_START,
        S7_8_READ1_SETUP, S7_8_READ1_WAIT, // Read from 0x350
        S7_8_READ2_SETUP, S7_8_READ2_WAIT, // Read from 0x34C
        S7_8_WRITE_SETUP, S7_8_WRITE_WAIT,
        S7_8_LOOP_CHECK,
        // Step 9 & 10: Adjust txpi_socclk_code
        S9_10_LOOP_START,
        S9_10_READ_SETUP, S9_10_READ_WAIT,
        S9_10_WRITE_SETUP, S9_10_WRITE_WAIT,
        S9_10_LOOP_CHECK,
        // Step 11: Set rxdll2 overrides
        S11_LOOP_START,
        S11_READ_SETUP, S11_READ_WAIT,
        S11_WRITE_SETUP, S11_WRITE_WAIT,
        S11_LOOP_CHECK,
        // Step 12: Set txdll2 overrides
        S12_LOOP_START,
        S12_READ_SETUP, S12_READ_WAIT,
        S12_WRITE_SETUP, S12_WRITE_WAIT,
        S12_LOOP_CHECK,
        // Step 13: Clear vcalcode_ovrd
        S13_LOOP_START,
        S13_READ_SETUP, S13_READ_WAIT,
        S13_WRITE_SETUP, S13_WRITE_WAIT,
        S13_LOOP_CHECK,
        // Sequence completion
        SEQUENCE_DONE
    } fsm_state_t;
    
    fsm_state_t current_state, next_state;

    // Internal registers
    logic [4:0] i_m1; // Loop counter for 0 to 23
    logic [23:0] rx_soc_clk_lock;
    logic [AVMM_WIDTH-1:0] rdata_reg;
    logic [AVMM_WIDTH-1:0] wdata_reg;

    // Delay counter logic
    localparam DELAY_1000_NS = (CLK_FREQ_MHZ * 1000) / (1000*1000);
    logic [31:0] delay_counter;
    logic counter_load, counter_decr, counter_is_zero;

    // FSM state register
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) current_state <= IDLE;
        else        current_state <= next_state;
    end

    // Internal data registers
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            i_m1 <= '0;
            rx_soc_clk_lock <= '0;
            rdata_reg <= '0;
            wdata_reg <= '0;
        end else begin
            // Loop counter reset/increment
            if (next_state == POLL_LOOP_START || next_state == S3_4_LOOP_START ||
                next_state == S5_6_LOOP_START || next_state == S7_8_LOOP_START ||
                next_state == S9_10_LOOP_START || next_state == S11_LOOP_START ||
                next_state == S12_LOOP_START || next_state == S13_LOOP_START) begin
                i_m1 <= '0;
            end else if (next_state == POLL_LOOP_CHECK || next_state == S3_4_LOOP_CHECK ||
                       next_state == S5_6_LOOP_CHECK || next_state == S7_8_LOOP_CHECK ||
                       next_state == S9_10_LOOP_CHECK || next_state == S11_LOOP_CHECK ||
                       next_state == S12_LOOP_CHECK || next_state == S13_LOOP_CHECK) begin
                i_m1 <= i_m1 + 1;
            end

            // Update lock status vector
            if(current_state == POLL_READ_WAIT && transaction_done) begin
                rx_soc_clk_lock[i_m1] <= transaction_rdata[27];
            end
            
            // Clear lock status at the beginning of a polling cycle
            if(next_state == POLL_LOOP_START) begin
                rx_soc_clk_lock <= '0;
            end

            // Latch data for read-modify-write
            if(transaction_done) begin
                case(current_state)
                    S3_4_READ_WAIT, S5_6_READ_WAIT, S7_8_READ2_WAIT, S9_10_READ_WAIT,
                    S11_READ_WAIT, S12_READ_WAIT, S13_READ_WAIT: begin
                        rdata_reg <= transaction_rdata;
                    end
                    S7_8_READ1_WAIT: begin // Special case for step 7/8
                        wdata_reg <= transaction_rdata;
                    end
                    default: ;
                endcase
            end
        end
    end

    // Delay counter
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)           delay_counter <= '0;
        else if (counter_load) delay_counter <= DELAY_1000_NS;
        else if (counter_decr) delay_counter <= delay_counter - 1;
    end
    assign counter_is_zero = (delay_counter == 0);
    
    // Combinational logic for FSM
    always_comb begin
        next_state = current_state;
        done = 1'b0;
        transaction_start = 1'b0;
        transaction_is_write = 1'b0;
        transaction_addr = '0;
        transaction_wdata = '0;
        transaction_be = 4'hF;
        counter_load = 1'b0;
        counter_decr = 1'b0;

        case (current_state)
            IDLE: if (start) next_state = POLL_DELAY;

            // --- Polling Section ---
            POLL_DELAY: begin
                counter_load = 1'b1;
                next_state = POLL_EVALUATE;
            end
            POLL_EVALUATE: begin
                counter_decr = 1'b1;
                if (counter_is_zero) begin
                    if (rx_soc_clk_lock == 24'hffffff) begin
                        next_state = S3_4_LOOP_START;
                    end else begin
                        next_state = POLL_LOOP_START;
                    end
                end
            end
            POLL_LOOP_START: next_state = POLL_READ_SETUP;
            POLL_READ_SETUP: begin
                transaction_start = 1'b1;
                transaction_addr = {i_m1, 11'h344};
                next_state = POLL_READ_WAIT;
            end
            POLL_READ_WAIT: if (transaction_done) next_state = POLL_LOOP_CHECK;
            POLL_LOOP_CHECK: next_state = (i_m1 == 23) ? POLL_DELAY : POLL_READ_SETUP;

            // --- Step 3-4 Section ---
            S3_4_LOOP_START: next_state = S3_4_READ_SETUP;
            S3_4_READ_SETUP: begin
                transaction_start = 1'b1;
                transaction_addr = {i_m1, 11'h344};
                next_state = S3_4_READ_WAIT;
            end
            S3_4_READ_WAIT: if(transaction_done) next_state = S3_4_WRITE_SETUP;
            S3_4_WRITE_SETUP: begin
                transaction_start = 1'b1;
                transaction_is_write = 1'b1;
                transaction_addr = {i_m1, 11'h344};
                transaction_wdata = rdata_reg;
                transaction_wdata[19:16] = (rdata_reg[11:8] >= 4'd2) ? (rdata_reg[11:8] - 4'd2) : (14 + rdata_reg[11:8]);
                next_state = S3_4_WRITE_WAIT;
            end
            S3_4_WRITE_WAIT: if(transaction_done) next_state = S3_4_LOOP_CHECK;
            S3_4_LOOP_CHECK: next_state = (i_m1 == 23) ? S5_6_LOOP_START : S3_4_READ_SETUP;

            // --- Step 5-6 Section ---
            S5_6_LOOP_START: next_state = S5_6_READ_SETUP;
            S5_6_READ_SETUP: begin
                transaction_start = 1'b1;
                transaction_addr = {i_m1, 11'h344};
                next_state = S5_6_READ_WAIT;
            end
            S5_6_READ_WAIT: if(transaction_done) next_state = S5_6_WRITE_SETUP;
            S5_6_WRITE_SETUP: begin
                transaction_start = 1'b1;
                transaction_is_write = 1'b1;
                transaction_addr = {i_m1, 11'h344};
                transaction_wdata = rdata_reg;
                transaction_wdata[23:20] = rdata_reg[15:12] + 4'd6;
                next_state = S5_6_WRITE_WAIT;
            end
            S5_6_WRITE_WAIT: if(transaction_done) next_state = S5_6_LOOP_CHECK;
            S5_6_LOOP_CHECK: next_state = (i_m1 == 23) ? S7_8_LOOP_START : S5_6_READ_SETUP;

            // --- Step 7-8 Section ---
            S7_8_LOOP_START: next_state = S7_8_READ1_SETUP;
            S7_8_READ1_SETUP: begin
                transaction_start = 1'b1;
                transaction_addr = {i_m1, 11'h350};
                next_state = S7_8_READ1_WAIT;
            end
            S7_8_READ1_WAIT: if(transaction_done) next_state = S7_8_READ2_SETUP;
            S7_8_READ2_SETUP: begin
                transaction_start = 1'b1;
                transaction_addr = {i_m1, 11'h34C};
                next_state = S7_8_READ2_WAIT;
            end
            S7_8_READ2_WAIT: if(transaction_done) next_state = S7_8_WRITE_SETUP;
            S7_8_WRITE_SETUP: begin
                transaction_start = 1'b1;
                transaction_is_write = 1'b1;
                transaction_addr = {i_m1, 11'h34C};
                transaction_wdata = rdata_reg;
                transaction_wdata[11:8] = wdata_reg[23:20] + 4'd8;
                next_state = S7_8_WRITE_WAIT;
            end
            S7_8_WRITE_WAIT: if(transaction_done) next_state = S7_8_LOOP_CHECK;
            S7_8_LOOP_CHECK: next_state = (i_m1 == 23) ? S9_10_LOOP_START : S7_8_READ1_SETUP;

            // --- Step 9-10 Section ---
            S9_10_LOOP_START: next_state = S9_10_READ_SETUP;
            S9_10_READ_SETUP: begin
                transaction_start = 1'b1;
                transaction_addr = {i_m1, 11'h350};
                next_state = S9_10_READ_WAIT;
            end
            S9_10_READ_WAIT: if(transaction_done) next_state = S9_10_WRITE_SETUP;
            S9_10_WRITE_SETUP: begin
                transaction_start = 1'b1;
                transaction_is_write = 1'b1;
                transaction_addr = {i_m1, 11'h350};
                transaction_wdata = rdata_reg;
                transaction_wdata[3:0] = (rdata_reg[19:16] >= 4'd2) ? (rdata_reg[19:16] - 4'd2) : (14 + rdata_reg[19:16]);
                next_state = S9_10_WRITE_WAIT;
            end
            S9_10_WRITE_WAIT: if(transaction_done) next_state = S9_10_LOOP_CHECK;
            S9_10_LOOP_CHECK: next_state = (i_m1 == 23) ? S11_LOOP_START : S9_10_READ_SETUP;

            // --- Step 11 Section ---
            S11_LOOP_START: next_state = S11_READ_SETUP;
            S11_READ_SETUP: begin
                transaction_start = 1'b1;
                transaction_addr = {i_m1, 11'h344};
                next_state = S11_READ_WAIT;
            end
            S11_READ_WAIT: if(transaction_done) next_state = S11_WRITE_SETUP;
            S11_WRITE_SETUP: begin
                transaction_start = 1'b1;
                transaction_is_write = 1'b1;
                transaction_addr = {i_m1, 11'h344};
                transaction_wdata = rdata_reg | 32'hF000_0000;
                next_state = S11_WRITE_WAIT;
            end
            S11_WRITE_WAIT: if(transaction_done) next_state = S11_LOOP_CHECK;
            S11_LOOP_CHECK: next_state = (i_m1 == 23) ? S12_LOOP_START : S11_READ_SETUP;

            // --- Step 12 Section ---
            S12_LOOP_START: next_state = S12_READ_SETUP;
            S12_READ_SETUP: begin
                transaction_start = 1'b1;
                transaction_addr = {i_m1, 11'h350};
                next_state = S12_READ_WAIT;
            end
            S12_READ_WAIT: if(transaction_done) next_state = S12_WRITE_SETUP;
            S12_WRITE_SETUP: begin
                transaction_start = 1'b1;
                transaction_is_write = 1'b1;
                transaction_addr = {i_m1, 11'h350};
                transaction_wdata = rdata_reg | 32'h9C00_0000;
                next_state = S12_WRITE_WAIT;
            end
            S12_WRITE_WAIT: if(transaction_done) next_state = S12_LOOP_CHECK;
            S12_LOOP_CHECK: next_state = (i_m1 == 23) ? S13_LOOP_START : S12_READ_SETUP;
            
            // --- Step 13 Section ---
            S13_LOOP_START: next_state = S13_READ_SETUP;
            S13_READ_SETUP: begin
                transaction_start = 1'b1;
                transaction_addr = {i_m1, 11'h33C};
                next_state = S13_READ_WAIT;
            end
            S13_READ_WAIT: if(transaction_done) next_state = S13_WRITE_SETUP;
            S13_WRITE_SETUP: begin
                transaction_start = 1'b1;
                transaction_is_write = 1'b1;
                transaction_addr = {i_m1, 11'h33C};
                transaction_wdata = rdata_reg & ~32'h4000_0000;
                next_state = S13_WRITE_WAIT;
            end
            S13_WRITE_WAIT: if(transaction_done) next_state = S13_LOOP_CHECK;
            S13_LOOP_CHECK: next_state = (i_m1 == 23) ? SEQUENCE_DONE : S13_READ_SETUP;

            SEQUENCE_DONE: begin
                done = 1'b1;
                next_state = IDLE;
            end

            default: next_state = IDLE;
        endcase
    end

endmodule