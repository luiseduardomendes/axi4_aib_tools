//
// File: initial_register_config_fsm.sv
// Description: FSM to perform the initial register setup writes for all channels,
//              as described in the "Setting up registers" section of the flow.
//
module initial_register_config_fsm #(
    parameter TOTAL_CHNL_NUM = 24
)(
    // Clock and Reset
    input  logic clk,
    input  logic rst_n,

    // Control
    input  logic start_config,
    output reg   config_done,
    input  logic is_bca_mode, // BCA mode is equivalent to 4th write in this context

    // AVMM Master Interface
    output logic       avmm_write_o,
    output logic       avmm_read_o,
    output logic[16:0] avmm_address_o,
    output logic[31:0] avmm_writedata_o,
    output logic[3:0]  avmm_byteenable_o,
    input  logic       avmm_waitrequest_i
);
    typedef enum logic [2:0] { IDLE, WRITE_1, WRITE_2, WRITE_3, CHECK_BCA, WRITE_4, NEXT_CH, DONE } state_t;
    state_t state, next_state;

    logic [4:0] channel_cnt;
    logic       start_single_op;
    logic       single_op_done;

    logic [16:0] current_addr;
    logic [31:0] current_wdata;

    avmm_transaction_fsm avmm_op_inst (
        .clk(clk), .rst_n(rst_n),
        .start_op(start_single_op), .op_is_write(1'b1), .op_done(single_op_done),
        .avmm_address_in(current_addr), .avmm_writedata_in(current_wdata), .avmm_byteenable_in(4'hF),
        .avmm_write(avmm_write_o), .avmm_read(avmm_read_o),
        .avmm_address(avmm_address_o), .avmm_writedata(avmm_writedata_o),
        .avmm_byteenable(avmm_byteenable_o), .avmm_waitrequest(avmm_waitrequest_i),
        .avmm_readdata(32'b0), .avmm_readdatavalid(1'b0), .rdata_out()
    );

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin state <= IDLE; channel_cnt <= '0;
        end else begin
            state <= next_state;
            if (next_state == IDLE) channel_cnt <= '0;
            else if ((state == WRITE_3 && !is_bca_mode && single_op_done) || (state == WRITE_4 && is_bca_mode && single_op_done)) begin
                channel_cnt <= channel_cnt + 1;
            end
        end
    end

    always_comb begin
        next_state = state; config_done = 1'b0; start_single_op = 1'b0;
        current_addr = '0; current_wdata = '0;

        case (state)
            IDLE: if (start_config) next_state = WRITE_1;
            WRITE_1: begin start_single_op = 1'b1; current_addr = {2'b0, channel_cnt, 11'h208}; current_wdata = 32'h0600_0000; if (single_op_done) next_state = WRITE_2; end
            WRITE_2: begin start_single_op = 1'b1; current_addr = {2'b0, channel_cnt, 11'h210}; current_wdata = 32'h0000_0006; if (single_op_done) next_state = WRITE_3; end
            WRITE_3: begin start_single_op = 1'b1; current_addr = {2'b0, channel_cnt, 11'h218}; current_wdata = 32'h6060_0000; if (single_op_done) next_state = CHECK_BCA; end
            CHECK_BCA: if (is_bca_mode) next_state = WRITE_4; else next_state = NEXT_CH;
            WRITE_4: begin start_single_op = 1'b1; current_addr = {2'b0, channel_cnt, 11'h33C}; current_wdata = 32'h4000_0000; if (single_op_done) next_state = NEXT_CH; end
            NEXT_CH: if (channel_cnt == TOTAL_CHNL_NUM - 1) next_state = DONE; else next_state = WRITE_1;
            DONE: begin config_done = 1'b1; next_state = IDLE; end
            default: next_state = IDLE;
        endcase
    end
endmodule
