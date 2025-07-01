module avmm_multi_write_fsm #(
    parameter ACTIVE_CHNLS = 24,
    parameter SEQ_COUNT = 4,
    parameter ADDR_WIDTH = 16,
    parameter DATA_WIDTH = 32,
    parameter BE_WIDTH   = 4,
    parameter ADDR0 = 0,
    parameter DATA0 = 0,
    parameter ADDR1 = 0,
    parameter DATA1 = 0,
    parameter ADDR2 = 0,
    parameter DATA2 = 0,
    parameter ADDR3 = 0,
    parameter DATA3 = 0
)(
    input  logic clk,
    input  logic rst_n,

    // Control
    input  logic start,
    output logic done,

    // Avalon-MM FSM interface
    output logic                       transaction_start,
    output logic                       transaction_is_write,
    output logic [ADDR_WIDTH-1:0]      transaction_addr,
    output logic [DATA_WIDTH-1:0]      transaction_wdata,
    output logic [BE_WIDTH-1:0]        transaction_be,
    input  logic                       transaction_done
);

    typedef enum logic [2:0] {
        IDLE,
        LOOP_START,
        SEQ_SETUP,
        SEQ_WAIT,
        LOOP_CHECK,
        LOOP_INCREMENT,
        SEQUENCE_DONE
    } fsm_state_t;

    fsm_state_t current_state, next_state;

    // Channel index
    logic [$clog2(ACTIVE_CHNLS)-1:0] chnl_idx;

    // Sequence index
    logic [$clog2(SEQ_COUNT)-1:0] seq_idx;

    // Latched transaction fields
    logic [ADDR_WIDTH-1:0] latched_addr;
    logic [DATA_WIDTH-1:0] latched_data;
    logic [BE_WIDTH-1:0]   latched_be;

    // State register
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            current_state <= IDLE;
        else
            current_state <= next_state;
    end

    // Loop and sequence counters
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            chnl_idx <= '0;
            seq_idx  <= '0;
        end else begin
            if (next_state == LOOP_START) begin
                chnl_idx <= '0;
                seq_idx  <= '0;
            end else if (next_state == LOOP_INCREMENT) begin
                chnl_idx <= chnl_idx + 1;
                seq_idx  <= '0;
            end else if (current_state == SEQ_WAIT && transaction_done) begin
                seq_idx <= seq_idx + 1;
            end
        end
    end

    // Address/Data lookup
    always_comb begin
        case (seq_idx)
            0: begin
                latched_addr  = {chnl_idx, ADDR0[ADDR_WIDTH-1:0]};
                latched_data  = DATA0;
                latched_be    = 4'hF;
            end
            1: begin
                latched_addr  = {chnl_idx, ADDR1[ADDR_WIDTH-1:0]};
                latched_data  = DATA1;
                latched_be    = 4'hF;
            end
            2: begin
                latched_addr  = {chnl_idx, ADDR2[ADDR_WIDTH-1:0]};
                latched_data  = DATA2;
                latched_be    = 4'hF;
            end
            3: begin
                latched_addr  = {chnl_idx, ADDR3[ADDR_WIDTH-1:0]};
                latched_data  = DATA3;
                latched_be    = 4'hF;
            end
            default: begin
                latched_addr  = '0;
                latched_data  = '0;
                latched_be    = 4'h0;
            end
        endcase
    end

    // FSM next-state logic
    always_comb begin
        next_state = current_state;
        done = 1'b0;
        transaction_start = 1'b0;

        transaction_addr     = latched_addr;
        transaction_wdata    = latched_data;
        transaction_be       = latched_be;
        transaction_is_write = 1'b1;

        case (current_state)
            IDLE: if (start) next_state = LOOP_START;

            LOOP_START: next_state = SEQ_SETUP;

            SEQ_SETUP: begin
                transaction_start = 1'b1;
                next_state = SEQ_WAIT;
            end

            SEQ_WAIT: if (transaction_done) begin
                if (seq_idx == SEQ_COUNT-1)
                    next_state = LOOP_CHECK;
                else
                    next_state = SEQ_SETUP;
            end

            LOOP_CHECK:
                if (chnl_idx == ACTIVE_CHNLS-1)
                    next_state = SEQUENCE_DONE;
                else
                    next_state = LOOP_INCREMENT;

            LOOP_INCREMENT: next_state = SEQ_SETUP;

            SEQUENCE_DONE: begin
                done = 1'b1;
                next_state = IDLE;
            end

            default: next_state = IDLE;
        endcase
    end

endmodule
