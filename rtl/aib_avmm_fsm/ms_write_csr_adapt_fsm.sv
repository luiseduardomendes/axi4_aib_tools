// This module implements a synthesizable Finite-State Machine (FSM) to handle
// the write_csr_adapt sequence. It loops 24 times, writing to a set of
// configuration and status registers (CSRs) for the AIB adapter on the master side.
// It uses the previously defined 'avalon_mm_fsm' to execute the physical bus writes.

module ms_write_csr_adapt_fsm #(
    parameter ACTIVE_CHNLS = 1,
    parameter AVMM_WIDTH = 32,
    parameter BYTE_WIDTH = 4,
    parameter ADDR_WIDTH = 16
) (
    input  bit clk,
    input  bit rst_n,

    // Control signals
    input  bit start, // A pulse on this input starts the sequence
    output logic done,  // A pulse on this output indicates the sequence is complete

    // Avalon MM Interface signals (to be connected to an avalon_mm_fsm instance)
    output logic                      transaction_start,
    output logic                      transaction_is_write,
    output logic [ADDR_WIDTH-1:0]     transaction_addr,
    output logic [AVMM_WIDTH-1:0]     transaction_wdata,
    output logic [BYTE_WIDTH-1:0]     transaction_be,
    input  bit                        transaction_done
);

    // FSM State Definitions
    typedef enum logic [3:0] {
        IDLE,
        LOOP_START,
        WRITE_1_SETUP,
        WRITE_1_WAIT,
        WRITE_2_SETUP,
        WRITE_2_WAIT,
        WRITE_3_SETUP,
        WRITE_3_WAIT,
        WRITE_BCA_SETUP,
        WRITE_BCA_WAIT,
        LOOP_INCREMENT,
        LOOP_CHECK,
        SEQUENCE_DONE
    } fsm_state_t;

    fsm_state_t current_state, next_state;

    // Loop counter
    logic [4:0] i_m1; // Counter for 0 to 23

    // FSM state register
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_state <= IDLE;
        end else begin
            current_state <= next_state;
        end
    end
    
    // Loop counter register
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            i_m1 <= '0;
        end else if (next_state == LOOP_START) begin
            i_m1 <= '0;
        end else if (next_state == LOOP_INCREMENT) begin
            i_m1 <= i_m1 + 1;
        end
    end

    // FSM next state logic and output assignments
    always_comb begin
        // Default values
        next_state           = current_state;
        done                 = 1'b0;
        transaction_start    = 1'b0;
        transaction_is_write = 1'b0;
        transaction_addr     = '0;
        transaction_wdata    = '0;
        transaction_be       = '0;

        case (current_state)
            IDLE: begin
                if (start) begin
                    next_state = LOOP_START;
                end
            end

            LOOP_START: begin
                // Initialize the loop counter and start the first write
                next_state = WRITE_1_SETUP;
            end

            WRITE_1_SETUP: begin
                // Setup the first cfg_write transaction for the current loop iteration
                transaction_start    = 1'b1;
                transaction_is_write = 1'b1;
                transaction_addr     = {i_m1[4:0], 11'h208};
                transaction_wdata    = 32'h0600_0000;
                transaction_be       = 4'hF;
                next_state           = WRITE_1_WAIT;
            end

            WRITE_1_WAIT: begin
                // Wait for the avalon_mm_fsm to complete the transaction
                if (transaction_done) begin
                    next_state = WRITE_2_SETUP;
                end
            end

            WRITE_2_SETUP: begin
                transaction_start    = 1'b1;
                transaction_is_write = 1'b1;
                transaction_addr     = {i_m1[4:0], 11'h210};
                transaction_wdata    = 32'h0000_0006;
                transaction_be       = 4'hF;
                next_state           = WRITE_2_WAIT;
            end

            WRITE_2_WAIT: begin
                if (transaction_done) begin
                    next_state = WRITE_3_SETUP;
                end
            end
            
            WRITE_3_SETUP: begin
                transaction_start    = 1'b1;
                transaction_is_write = 1'b1;
                transaction_addr     = {i_m1[4:0], 11'h218};
                transaction_wdata    = 32'h6060_0000;
                transaction_be       = 4'hF;
                next_state = WRITE_3_WAIT;
                
            end

            WRITE_3_WAIT: begin
                if (transaction_done) begin
                    next_state = WRITE_BCA_SETUP;
                end
            end

            WRITE_BCA_SETUP: begin
                transaction_start    = 1'b1;
                transaction_is_write = 1'b1;
                transaction_addr     = {i_m1[4:0], 11'h33C};
                transaction_wdata    = 32'h4000_0000;
                transaction_be       = 4'hF;
                next_state           = WRITE_BCA_WAIT;
            end

            WRITE_BCA_WAIT: begin
                if (transaction_done) begin
                    next_state = LOOP_CHECK;
                end
            end

            LOOP_CHECK: begin
                // Check if we have completed all 24 iterations
                if (i_m1 == ACTIVE_CHNLS-1) begin
                    next_state = SEQUENCE_DONE;
                end else begin
                    next_state = LOOP_INCREMENT;
                end
            end

            LOOP_INCREMENT: begin
                // Increment counter and restart the write sequence for the next channel
                next_state = WRITE_1_SETUP;
            end

            SEQUENCE_DONE: begin
                // Signal that the entire sequence is finished for one cycle
                done = 1'b1;
                next_state = IDLE;
            end

            default: begin
                next_state = IDLE;
            end
        endcase
    end

endmodule
