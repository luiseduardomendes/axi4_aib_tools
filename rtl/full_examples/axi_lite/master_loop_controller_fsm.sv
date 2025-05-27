// loop_controller_fsm.sv
// This FSM implements the for loop, iterating i_m1 from 0 to 23.
// In each iteration, it triggers the triple_write_fsm.

module loop_controller_fsm (
    // Clock and Reset
    input logic clk,
    input logic rst_n,

    // Control Signals
    input logic start_main_sequence,        // Start the entire sequence of operations
    output logic main_sequence_done_out,    // Pulsed high when the entire loop is complete

    // Interface to triple_write_fsm
    output logic start_three_writes_to_triple, // To start triple_write_fsm
    input logic  three_writes_done_from_triple,// Done signal from triple_write_fsm
    output logic [4:0] i_m1_val_to_triple      // Current i_m1 value
);

    // Loop parameters
    localparam LOOP_MAX_COUNT = 24; // Loop for i_m1 from 0 to 23 (i.e., < 24)

    // State machine states
    typedef enum logic [1:0] {
        L_IDLE,
        L_ITER_START,
        L_ITER_WAIT,
        // L_INCREMENT is implicitly handled by transitioning back to L_ITER_START or L_DONE
        L_DONE
    } loop_state_e;

    loop_state_e current_l_state, next_l_state;
    logic [4:0] i_m1_counter; // Counter for i_m1, needs to hold 0 to 23

    // State Register
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_l_state <= L_IDLE;
            i_m1_counter <= 5'd0;
        end else begin
            current_l_state <= next_l_state;
            if (next_l_state == L_IDLE) begin // Reset counter when returning to IDLE
                 i_m1_counter <= 5'd0;
            end else if (current_l_state == L_ITER_WAIT && three_writes_done_from_triple) begin
                if (i_m1_counter < LOOP_MAX_COUNT - 1) begin
                    i_m1_counter <= i_m1_counter + 1;
                end
            end else if (start_main_sequence && current_l_state == L_IDLE) begin // Initialize on first start
                 i_m1_counter <= 5'd0;
            end
        end
    end

    // Next State Logic and Outputs
    always_comb begin
        // Default assignments
        next_l_state = current_l_state;
        main_sequence_done_out = 1'b0;
        start_three_writes_to_triple = 1'b0;
        i_m1_val_to_triple = i_m1_counter; // Output current counter value

        case (current_l_state)
            L_IDLE: begin
                if (start_main_sequence) begin
                    // i_m1_counter is already reset or will be set to 0 by the FF logic
                    next_l_state = L_ITER_START;
                end
            end

            L_ITER_START: begin
                if (i_m1_counter < LOOP_MAX_COUNT) begin
                    start_three_writes_to_triple = 1'b1;
                    i_m1_val_to_triple = i_m1_counter; // Ensure it's driven this cycle
                    next_l_state = L_ITER_WAIT;
                end else begin
                    // Should not happen
                    next_l_state = L_DONE;
                end
            end

            L_ITER_WAIT: begin
                i_m1_val_to_triple = i_m1_counter; // Keep driving current i_m1
                if (three_writes_done_from_triple) begin
                    if (i_m1_counter < LOOP_MAX_COUNT - 1) begin
                        // Counter will be incremented in the always_ff block
                        next_l_state = L_ITER_START; // Start next iteration
                    end else begin
                        // Last iteration was completed
                        next_l_state = L_DONE;
                    end
                end
                // Else, stay in L_ITER_WAIT, start_three_writes_to_triple is now low
            end

            L_DONE: begin
                main_sequence_done_out = 1'b1;
                next_l_state = L_IDLE; // Ready for another main sequence if needed
            end

            default: begin
                next_l_state = L_IDLE;
            end
        endcase
    end

endmodule
