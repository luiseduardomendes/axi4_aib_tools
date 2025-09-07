//------------------------------------------------------------------------------
// FSM to perform multiple Avalon-MM writes safely with latched transaction data
//------------------------------------------------------------------------------

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
    input  logic [AVMM_WIDTH-1:0]     transaction_rdata,
    input  bit                        transaction_done
);
    localparam RX_0 = 32'h0600_0000;
    localparam RX_1 = 32'h0000_0006;
    localparam TX_0 = 32'h6060_0000;
    localparam R_AIB_CSR7 = 32'h0000_0000;

    // FSM State Definitions
    typedef enum logic [4:0] {
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

        WRITE_1_CHECK_SETUP,
        WRITE_1_CHECK_WAIT,
        WRITE_2_CHECK_SETUP,
        WRITE_2_CHECK_WAIT,
        WRITE_3_CHECK_SETUP,
        WRITE_3_CHECK_WAIT,
        WRITE_BCA_CHECK_SETUP,
        WRITE_BCA_CHECK_WAIT,

        LOOP_INCREMENT,
        LOOP_CHECK,
        SEQUENCE_DONE
    } fsm_state_t;

    fsm_state_t current_state, next_state;

    // Loop counter
    logic [4:0] i_m1; // Counter for 0 to 23

    // Latched transaction fields
    logic [ADDR_WIDTH-1:0] latched_addr;
    logic [AVMM_WIDTH-1:0] latched_wdata;
    logic [BYTE_WIDTH-1:0] latched_be;
    logic                  latched_is_write;

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

    // Latched transaction data
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            latched_addr      <= '0;
            latched_wdata     <= '0;
            latched_be        <= '0;
            latched_is_write  <= '0;
        end else begin
            case (next_state)
                WRITE_1_SETUP: begin
                    latched_addr      <= {i_m1[4:0], 11'h208};
                    latched_wdata     <= RX_0;
                    latched_be        <= 4'hF;
                    latched_is_write  <= 1'b1;
                end
                WRITE_1_CHECK_SETUP: begin
                    latched_addr      <= {i_m1[4:0], 11'h208};
                    latched_is_write  <= 1'b0;
                end
                WRITE_2_SETUP: begin
                    latched_addr      <= {i_m1[4:0], 11'h210};
                    latched_wdata     <= RX_1;
                    latched_be        <= 4'hF;
                    latched_is_write  <= 1'b1;
                end
                WRITE_2_CHECK_SETUP: begin
                    latched_addr      <= {i_m1[4:0], 11'h210};
                    latched_is_write  <= 1'b0;
                end
                WRITE_3_SETUP: begin
                    latched_addr      <= {i_m1[4:0], 11'h218};
                    latched_wdata     <= TX_0;
                    latched_be        <= 4'hF;
                    latched_is_write  <= 1'b1;
                end
                WRITE_3_CHECK_SETUP: begin
                    latched_addr      <= {i_m1[4:0], 11'h218};
                    latched_is_write  <= 1'b0;
                end
                WRITE_BCA_SETUP: begin
                    latched_addr      <= {i_m1[4:0], 11'h33C};
                    latched_wdata     <= R_AIB_CSR7;
                    latched_be        <= 4'hF;
                    latched_is_write  <= 1'b1;
                end
                WRITE_BCA_CHECK_SETUP: begin
                    latched_addr      <= {i_m1[4:0], 11'h33C};
                    latched_is_write  <= 1'b0;
                end
                default: begin
                    // Retain previous values
                end
            endcase
        end
    end

    // FSM next state logic and outputs
    always_comb begin
        // Default assignments
        next_state             = current_state;
        done                   = 1'b0;
        transaction_start      = 1'b0; // Default is to not start a transaction

        // Outputs from latched registers
        transaction_addr       = latched_addr;
        transaction_wdata      = latched_wdata;
        transaction_be         = latched_be;
        transaction_is_write   = latched_is_write;

        case (current_state)
            IDLE: begin
                if (start) begin
                    next_state = LOOP_START;
                end
            end

            LOOP_START: begin
                // This state sets up the latches for the first write
                next_state = WRITE_1_SETUP;
            end

            // SETUP states are now only for setting next_state
            WRITE_1_SETUP:   next_state = WRITE_1_WAIT;
            WRITE_2_SETUP:   next_state = WRITE_2_WAIT;
            WRITE_3_SETUP:   next_state = WRITE_3_WAIT;
            WRITE_BCA_SETUP: next_state = WRITE_BCA_WAIT;

            WRITE_1_CHECK_SETUP:   next_state = WRITE_1_CHECK_WAIT;
            WRITE_2_CHECK_SETUP:   next_state = WRITE_2_CHECK_WAIT;
            WRITE_3_CHECK_SETUP:   next_state = WRITE_3_CHECK_WAIT;
            WRITE_BCA_CHECK_SETUP: next_state = WRITE_BCA_CHECK_WAIT;

            // WAIT states now start the transaction and wait for completion
            WRITE_1_WAIT: begin
                transaction_start = 1'b1; // Assert start here
                if (transaction_done) begin
                    transaction_start = 1'b0; // De-assert if done in the same cycle
                    next_state = WRITE_1_CHECK_SETUP;
                end
            end

            WRITE_1_CHECK_WAIT: begin
                transaction_start = 1'b1; // Assert start here
                if (transaction_done) begin
                    transaction_start = 1'b0; // De-assert if done in the same cycle
                    if (transaction_rdata == RX_0) begin
                        next_state = WRITE_2_SETUP;
                    end else begin
                        next_state = WRITE_1_SETUP;
                    end
                end
            end

            WRITE_2_WAIT: begin
                transaction_start = 1'b1; // Assert start here
                if (transaction_done) begin
                    transaction_start = 1'b0;
                    next_state = WRITE_2_CHECK_SETUP;
                end
            end

            WRITE_2_CHECK_WAIT: begin
                transaction_start = 1'b1; // Assert start here
                if (transaction_done) begin
                    transaction_start = 1'b0; // De-assert if done in the same cycle
                    if (transaction_rdata == RX_1) begin
                        next_state = WRITE_3_SETUP;
                    end else begin
                        next_state = WRITE_2_SETUP;
                    end
                end
            end

            WRITE_3_WAIT: begin
                transaction_start = 1'b1; // Assert start here
                if (transaction_done) begin
                    transaction_start = 1'b0;
                    next_state = WRITE_3_CHECK_SETUP;
                end
            end

            WRITE_3_CHECK_WAIT: begin
                transaction_start = 1'b1; // Assert start here
                if (transaction_done) begin
                    transaction_start = 1'b0; // De-assert if done in the same cycle
                    if (transaction_rdata == TX_0) begin
                        next_state = WRITE_BCA_SETUP;
                    end else begin
                        next_state = WRITE_3_SETUP;
                    end
                end
            end

            WRITE_BCA_WAIT: begin
                transaction_start = 1'b1; // Assert start here
                if (transaction_done) begin
                    transaction_start = 1'b0;
                    next_state = LOOP_CHECK;
                end
            end

            WRITE_BCA_CHECK_WAIT: begin
                transaction_start = 1'b1; // Assert start here
                if (transaction_done) begin
                    transaction_start = 1'b0; // De-assert if done in the same cycle
                    if (transaction_rdata == RX_0) begin
                        next_state = LOOP_CHECK;
                    end else begin
                        next_state = WRITE_BCA_SETUP;
                    end
                end
            end

            LOOP_CHECK: begin
                if (i_m1 == ACTIVE_CHNLS - 1) begin
                    next_state = SEQUENCE_DONE;
                end else begin
                    next_state = LOOP_INCREMENT;
                end
            end

            LOOP_INCREMENT: begin
                next_state = WRITE_1_SETUP;
            end

            SEQUENCE_DONE: begin
                done = 1'b1;
                next_state = IDLE;
            end

            default: begin
                next_state = IDLE;
            end
        endcase
    end
endmodule
