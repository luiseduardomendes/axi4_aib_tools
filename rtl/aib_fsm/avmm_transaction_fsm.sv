//
// File: avmm_transaction_fsm.sv
// Description: Executes a single Avalon-MM read or write operation. This is the
//              lowest-level building block, replacing the behavioral cfg_write
//              and cfg_read tasks from the initialization flow.
//
module avmm_transaction_fsm #(
    parameter AVMM_WIDTH = 32,
    parameter BYTE_WIDTH = 4
)(
    // Clock and Reset
    input  logic        clk,
    input  logic        rst_n,

    // Control
    input  logic        start_op,
    input  logic        op_is_write, // 1 for write, 0 for read
    output reg          op_done,

    // AVMM Master Interface (Inputs from parent FSM)
    input  logic [16:0] avmm_address_in,
    input  logic [31:0] avmm_writedata_in,
    input  logic [3:0]  avmm_byteenable_in,

    // AVMM Master Interface (Outputs to AIB PHY)
    output reg         avmm_write,
    output reg         avmm_read,
    output reg [16:0]  avmm_address,
    output reg [31:0]  avmm_writedata,
    output reg [3:0]   avmm_byteenable,
    input  logic       avmm_waitrequest,
    input  logic [31:0] avmm_readdata,
    input  logic       avmm_readdatavalid,
    output reg [31:0]  rdata_out
);

    typedef enum logic [1:0] {
        IDLE,
        START_TRANS,
        WAIT_TRANS_ACK,
        WAIT_READ_VALID
    } state_t;

    state_t state, next_state;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) state <= IDLE;
        else        state <= next_state;
    end

    always_ff @(posedge clk) begin
        if (avmm_readdatavalid) begin
            rdata_out <= avmm_readdata;
        end
    end

    always_comb begin
        next_state      = state;
        op_done         = 1'b0;
        avmm_write      = 1'b0;
        avmm_read       = 1'b0;
        avmm_address    = avmm_address_in;
        avmm_writedata  = avmm_writedata_in;
        avmm_byteenable = avmm_byteenable_in;

        case (state)
            IDLE: begin
                if (start_op) begin
                    next_state = START_TRANS;
                end
            end
            START_TRANS: begin
                if (op_is_write) avmm_write = 1'b1;
                else             avmm_read  = 1'b1;
                
                if (!avmm_waitrequest) begin
                    next_state = WAIT_TRANS_ACK;
                end
            end
            WAIT_TRANS_ACK: begin
                if (op_is_write) begin
                    op_done = 1'b1;
                    next_state = IDLE;
                end else begin // Read operation
                    next_state = WAIT_READ_VALID;
                end
            end
            WAIT_READ_VALID: begin
                if (avmm_readdatavalid) begin
                    op_done = 1'b1;
                    next_state = IDLE;
                end
            end
            default: next_state = IDLE;
        endcase
    end
endmodule
