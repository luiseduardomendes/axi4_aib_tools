// triple_write_fsm.sv
// This FSM controls the execution of three sequential Avalon-MM writes
// using the cfg_write_fsm. It takes i_m1 as an input to form addresses.

module triple_write_fsm (
    // Clock and Reset
    input logic clk,
    input logic rst_n,

    // Control Signals
    input logic start_three_writes,         // Start signal for the sequence of three writes
    output logic three_writes_done_out,     // Pulsed high for one clock when all three writes are done

    // Input i_m1 value
    input logic [4:0] i_m1_val_in,          // Current i_m1 value from the loop controller

    // Interface to cfg_write_fsm
    output logic        start_single_write_to_cfg, // To start cfg_write_fsm
    input  logic        single_write_done_from_cfg,// Done signal from cfg_write_fsm
    output logic [16:0] addr_to_cfg,
    output logic [3:0]  be_to_cfg,
    output logic [31:0] data_to_cfg
);
    localparam AVMM_WIDTH = 32;
    localparam BYTE_WIDTH = 4; // For be_to_cfg

    // State machine states
    typedef enum logic [2:0] {
        T_IDLE,
        T_WRITE1_START,
        T_WRITE1_WAIT,
        T_WRITE2_START,
        T_WRITE2_WAIT,
        T_WRITE3_START,
        T_WRITE3_WAIT,
        T_DONE
    } triple_state_e;

    triple_state_e current_t_state, next_t_state;

    // Registers for address and data (could be combinational if preferred)
    // Using combinational outputs for addr/data/be to cfg_write_fsm

    // State Register
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_t_state <= T_IDLE;
        end else begin
            current_t_state <= next_t_state;
        end
    end

    // Next State Logic and Outputs
    always_comb begin
        // Default assignments
        next_t_state = current_t_state;
        three_writes_done_out = 1'b0;
        start_single_write_to_cfg = 1'b0;

        // Default outputs to cfg_write_fsm (can be 'x if not active)
        addr_to_cfg = '0;
        be_to_cfg   = {BYTE_WIDTH{1'b0}}; // Or specific default like 4'h0
        data_to_cfg = '0;


        case (current_t_state)
            T_IDLE: begin
                if (start_three_writes) begin
                    next_t_state = T_WRITE1_START;
                end
            end

            T_WRITE1_START: begin
                start_single_write_to_cfg = 1'b1;
                addr_to_cfg = {1'b0, i_m1_val_in, 11'h208}; // MSB of addr is 0, then 5 bits i_m1, then 11 bits
                be_to_cfg   = 4'hf;
                data_to_cfg = 32'h0600_0000;
                next_t_state = T_WRITE1_WAIT;
            end

            T_WRITE1_WAIT: begin
                // Outputs to cfg_write_fsm should remain stable or cfg_write_fsm should latch them
                // cfg_write_fsm latches them on its start edge.
                // Here we can stop driving them once start_single_write_to_cfg is low.
                addr_to_cfg = {1'b0, i_m1_val_in, 11'h208}; // Keep driving for clarity or remove if latched
                be_to_cfg   = 4'hf;
                data_to_cfg = 32'h0600_0000;

                if (single_write_done_from_cfg) begin
                    next_t_state = T_WRITE2_START;
                end
                // Else, stay in T_WRITE1_WAIT, start_single_write_to_cfg is now low
            end

            T_WRITE2_START: begin
                start_single_write_to_cfg = 1'b1;
                addr_to_cfg = {1'b0, i_m1_val_in, 11'h210};
                be_to_cfg   = 4'hf;
                data_to_cfg = 32'h0000_000b;
                next_t_state = T_WRITE2_WAIT;
            end

            T_WRITE2_WAIT: begin
                addr_to_cfg = {1'b0, i_m1_val_in, 11'h210};
                be_to_cfg   = 4'hf;
                data_to_cfg = 32'h0000_000b;
                if (single_write_done_from_cfg) begin
                    next_t_state = T_WRITE3_START;
                end
            end

            T_WRITE3_START: begin
                start_single_write_to_cfg = 1'b1;
                addr_to_cfg = {1'b0, i_m1_val_in, 11'h218};
                be_to_cfg   = 4'hf;
                data_to_cfg = 32'h60a1_0000;
                next_t_state = T_WRITE3_WAIT;
            end

            T_WRITE3_WAIT: begin
                addr_to_cfg = {1'b0, i_m1_val_in, 11'h218};
                be_to_cfg   = 4'hf;
                data_to_cfg = 32'h60a1_0000;
                if (single_write_done_from_cfg) begin
                    next_t_state = T_DONE;
                end
            end

            T_DONE: begin
                three_writes_done_out = 1'b1;
                next_t_state = T_IDLE;
            end

            default: begin
                next_t_state = T_IDLE;
            end
        endcase
    end

endmodule
