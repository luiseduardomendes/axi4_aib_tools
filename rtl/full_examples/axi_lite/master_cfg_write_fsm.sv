// cfg_write_fsm.sv
// This FSM performs a single Avalon-MM write operation, similar to the original cfg_write task.
// It waits for a start signal and asserts a done signal upon completion.

module cfg_write_fsm (
    // Clock and Reset
    input logic clk,
    input logic rst_n,

    // Control Signals
    input logic start_single_write,         // Start signal for a single write operation
    output logic single_write_done_out,     // Pulsed high for one clock when write is done

    // Avalon-MM Write Interface Inputs (from controlling FSM)
    input logic [16:0] write_addr_in,       // Address for the write
    input logic [3:0]  write_be_in,         // Byte enable for the write
    input logic [31:0] write_data_in,       // Data for the write

    // Avalon-MM Interface
    output logic [16:0] avmm_address_out,
    output logic [31:0] avmm_writedata_out,
    output logic [3:0]  avmm_byteenable_out,
    output logic        avmm_write_out,
    output logic        avmm_read_out,      // Tied low for writes
    input  logic        avmm_waitrequest    // Avalon-MM waitrequest signal
);

    // Define BYTE_WIDTH and AVMM_WIDTH based on input ports
    localparam BYTE_WIDTH = 4;
    localparam AVMM_WIDTH = 32;

    // State machine states
    typedef enum logic [2:0] {
        S_IDLE,             // Waiting for start_single_write
        S_SETUP_ASSERT,     // Setup Avalon signals and assert write
        S_WAIT_REQ,         // Wait for waitrequest to de-assert
        S_DEASSERT_WRITE,   // De-assert write signal
        S_DONE_PULSE        // Signal completion for one cycle
    } state_e;

    state_e current_state, next_state;

    // State Register
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_state <= S_IDLE;
        end else begin
            current_state <= next_state;
        end
    end

    // Next State Logic and Outputs
    always_comb begin
        // Default assignments
        next_state = current_state;
        single_write_done_out = 1'b0;

        avmm_write_out = 1'b0; // Default to not writing
        avmm_read_out  = 1'b0; // Always not reading in this FSM

        // Keep current address/data/be on outputs unless actively changing
        // This is important as they are set in S_IDLE before write is asserted
        avmm_address_out    = (current_state == S_IDLE && !start_single_write) ? '0 : write_addr_in;
        avmm_writedata_out  = (current_state == S_IDLE && !start_single_write) ? '0 : write_data_in;
        avmm_byteenable_out = (current_state == S_IDLE && !start_single_write) ? '0 : write_be_in;


        case (current_state)
            S_IDLE: begin
                avmm_write_out = 1'b0;
                single_write_done_out = 1'b0;
                if (start_single_write) begin
                    // Latch inputs for the transaction
                    avmm_address_out    = write_addr_in;
                    avmm_writedata_out  = write_data_in;
                    avmm_byteenable_out = write_be_in;
                    next_state          = S_SETUP_ASSERT;
                end else begin
                    // Explicitly clear outputs if not starting
                    avmm_address_out    = '0;
                    avmm_writedata_out  = '0;
                    avmm_byteenable_out = '0;
                end
            end

            S_SETUP_ASSERT: begin
                // Assert write and present address/data
                avmm_write_out      = 1'b1;
                avmm_read_out       = 1'b0;
                avmm_address_out    = write_addr_in; // Ensure they are driven
                avmm_writedata_out  = write_data_in;
                avmm_byteenable_out = write_be_in;

                // $display for simulation, matches original task
                // Note: $time might not be supported in all synthesis tools, typically for simulation only.
                // Consider removing or conditionalizing for synthesis.
                $display("%0t: cfg_write_fsm: WRITE_MM: address %x wdata = %x be = %x",
                         $time, write_addr_in, write_data_in, write_be_in);
                next_state = S_WAIT_REQ;
            end

            S_WAIT_REQ: begin
                // Hold write asserted and wait for waitrequest to be low
                avmm_write_out      = 1'b1;
                avmm_address_out    = write_addr_in;
                avmm_writedata_out  = write_data_in;
                avmm_byteenable_out = write_be_in;

                if (!avmm_waitrequest) begin
                    next_state = S_DEASSERT_WRITE;
                end
                // Else, stay in S_WAIT_REQ
            end

            S_DEASSERT_WRITE: begin
                // De-assert write (transaction accepted by peripheral)
                avmm_write_out = 1'b0;
                // Keep address/data on bus for one more cycle as per some Avalon specs, or clear them.
                // Here, we'll let them be cleared by S_IDLE or overwritten by next transaction.
                next_state = S_DONE_PULSE;
            end

            S_DONE_PULSE: begin
                single_write_done_out = 1'b1; // Signal completion
                avmm_write_out = 1'b0; // Ensure write is low
                next_state = S_IDLE;
            end

            default: begin
                next_state = S_IDLE;
            end
        endcase
    end

    // Initial block for reset conditions on outputs (optional, good practice)
    // For synthesis, ensure these are compatible with your tool's reset handling.
    // Or handle directly in the always_ff block for registered outputs if preferred.
    // Here, outputs are combinational based on state, so reset of state handles it.

endmodule
