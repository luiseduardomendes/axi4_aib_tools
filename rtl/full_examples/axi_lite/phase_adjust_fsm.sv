module phase_adjust_fsm (
    input  logic clk,
    input  logic rst_n,

    // Avalon-MM Interface
    output logic [16:0] avmm_address_out,
    output logic [31:0] avmm_writedata_out,
    output logic [3:0]  avmm_byteenable_out,
    output logic        avmm_write_out,
    output logic        avmm_read_out,
    input  logic        avmm_waitrequest,

    // Compatibility ports (add as needed for your environment)
    input  logic ref_clk,
    input  logic sample_clk,
    input  logic sys_clk,
    input  logic enable,
    input  logic start_phase_lock,
    input  logic phase_adjust_ovrd_sel,
    input  logic phase_sel_code_ovrd,
    input  logic phase_locked_ovrd,
    output logic sel_avg,
    output logic phase_locked,
    output logic [3:0] phase_sel_code,

    // FSM control
    input  logic start,
    output logic done
);

    // Stub assignments for compatibility outputs
    assign sel_avg        = 1'b0;
    assign phase_locked   = 1'b0;
    assign phase_sel_code = 4'b0;

    // ... your FSM logic here (as before) ...

    typedef enum logic [3:0] {
        IDLE,
        STEP1,
        STEP2,
        STEP3,
        STEP4,
        STEP5,
        STEP6,
        STEP7,
        STEP8,
        STEP9,
        STEP10,
        STEP11,
        STEP12,
        STEP13,
        DONE
    } state_t;

    state_t current_state, next_state;
    logic [31:0] rdata;
    logic [31:0] wdata;
    integer i;
    logic [23:0] rx_soc_clk_lock;

        always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_state <= IDLE;
            done <= 1'b0;
        end else begin
            current_state <= next_state;
            if (next_state == DONE)
                done <= 1'b1;
            else
                done <= 1'b0;
        end
    end

    always_comb begin
        next_state = current_state;
        avmm_address_out = '0;
        avmm_writedata_out = '0;
        avmm_byteenable_out = '0;
        avmm_write_out = 1'b0;
        avmm_read_out = 1'b0;


        case (current_state)
            IDLE: begin
                if (start) begin
                    next_state = STEP1;
                end
            end
            STEP1: begin
                avmm_address_out = {i, 11'h33C};
                avmm_byteenable_out = 4'hf;
                avmm_write_out = 1'b1;
                avmm_writedata_out = 32'h4000_0000;
                next_state = STEP2;
            end
            STEP2: begin
                if (!avmm_waitrequest) begin
                    next_state = STEP3;
                end
            end
            STEP3: begin
                if (rx_soc_clk_lock !== 24'hff_ffff) begin
                    avmm_address_out = {i, 11'h344};
                    avmm_byteenable_out = 4'hf;
                    avmm_read_out = 1'b1;
                    next_state = STEP4;
                end
            end
            STEP4: begin
                rx_soc_clk_lock[i] = rdata[27];
                next_state = STEP5;
            end
            STEP5: begin
                avmm_address_out = {i, 11'h344};
                avmm_byteenable_out = 4'hf;
                avmm_read_out = 1'b1;
                next_state = STEP6;
            end
            STEP6: begin
                avmm_address_out = {i, 11'h344};
                avmm_byteenable_out = 4'hf;
                avmm_write_out = 1'b1;
                avmm_writedata_out[19:16] = (rdata[11:8] >= 2) ? (rdata[11:8]-2) : (14+rdata[11:8]);
                next_state = STEP7;
            end
            STEP7: begin
                if (!avmm_waitrequest) begin
                    next_state = STEP8;
                end
            end
            STEP8: begin
                avmm_address_out = {i, 11'h344};
                avmm_byteenable_out = 4'hf;
                avmm_read_out = 1'b1;
                next_state = STEP9;
            end
            STEP9: begin
                avmm_address_out = {i, 11'h344};
                avmm_byteenable_out = 4'hf;
                avmm_write_out = 1'b1;
                avmm_writedata_out[23:20] = rdata[15:12] + 6;
                next_state = STEP10;
            end
            STEP10: begin
                if (!avmm_waitrequest) begin
                    next_state = STEP11;
                end
            end
            STEP11: begin
                avmm_address_out = {i, 11'h350};
                avmm_byteenable_out = 4'hf;
                avmm_read_out = 1'b1;
                next_state = STEP12;
            end
            STEP12: begin
                avmm_address_out = {i, 11'h34C};
                avmm_byteenable_out = 4'hf;
                avmm_write_out = 1'b1;
                wdata[11:8] = rdata[23:20]+8;
                avmm_writedata_out[11:8] = wdata[11:8];
                next_state = STEP13;
            end
            STEP13: begin
                if (!avmm_waitrequest) begin
                    next_state = DONE;
                end
            end
            DONE: begin
                next_state = IDLE;
            end
            default: next_state = IDLE;
        endcase
    end

endmodule