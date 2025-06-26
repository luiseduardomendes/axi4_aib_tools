// This module implements a synthesizable FSM for the link_up sequence on the
// slave side. It waits for the master and slave transfer enable signals to be
// fully asserted, indicating that the AIB link is active and operational.

module link_up_fsm #(
    parameter TOTAL_CHNL_NUM = 1
) (
    input  bit clk,
    input  bit rst_n,

    // Control signals
    input  bit start, // A pulse on this input starts the sequence
    output logic done,  // A pulse on this output indicates the sequence is complete

    // Inputs from Slave Interface 1 (intf_s1)
    input bit [TOTAL_CHNL_NUM-1:0] ms_tx_transfer_en,
    input bit [TOTAL_CHNL_NUM-1:0] sl_tx_transfer_en
);

    // FSM State Definitions
    typedef enum logic [1:0] {
        IDLE,
        WAIT_FOR_LINK,
        LINK_UP_DONE
    } fsm_state_t;

    fsm_state_t current_state, next_state;

    // FSM state register
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_state <= IDLE;
        end else begin
            current_state <= next_state;
        end
    end

    // FSM next state logic
    always_comb begin
        // Default values
        next_state = current_state;
        done       = 1'b0;

        case (current_state)
            IDLE: begin
                if (start) begin
                    next_state = WAIT_FOR_LINK;
                end
            end

            WAIT_FOR_LINK: begin
                // Check if all bits of both transfer enable signals are high
                if (&ms_tx_transfer_en && &sl_tx_transfer_en) begin
                    next_state = LINK_UP_DONE;
                end
            end

            LINK_UP_DONE: begin
                // Signal completion for one clock cycle
                done       = 1'b1;
                next_state = IDLE;
            end

            default: begin
                next_state = IDLE;
            end
        endcase
    end

endmodule
