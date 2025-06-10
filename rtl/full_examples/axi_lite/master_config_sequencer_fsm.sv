// avalon_config_sequencer.sv
// Top-level module that instantiates and connects the FSMs
// to perform the looped triple write sequence and phase adjustment.

module avalon_config_sequencer (
    // Clock and Reset
    input logic clk,
    input logic rst_n,

    // Control Signals
    input logic start_main_op,          // Top-level start signal for main configuration
    output logic main_op_done,          // Top-level done signal for main configuration
    input logic start_phase_adj,        // Top-level start signal for phase adjustment
    output logic phase_adj_done,        // Top-level done signal for phase adjustment

    // Avalon-MM Interface (to the peripheral)
    output logic [16:0] avmm_address,
    output logic [31:0] avmm_writedata,
    output logic [3:0]  avmm_byteenable,
    output logic        avmm_write,
    output logic        avmm_read,
    input  logic        avmm_waitrequest
);

    // Internal wires for connecting FSMs
    logic cfg_start_single_write;
    logic cfg_single_write_done;
    logic [16:0] cfg_addr_in;
    logic [3:0]  cfg_be_in;
    logic [31:0] cfg_data_in;

    logic triple_start_three_writes;
    logic triple_three_writes_done;
    logic [4:0] triple_i_m1_val;

    // Signals for phase adjust FSM
    logic phase_adjust_done_internal;
    logic [16:0] phase_addr;
    logic [31:0] phase_data;
    logic [3:0]  phase_be;
    logic        phase_write;
    logic        phase_read;

    // Signals for main config FSM
    logic [16:0] main_addr;
    logic [31:0] main_data;
    logic [3:0]  main_be;
    logic        main_write;
    logic        main_read;

    // FSM to arbitrate between main config and phase adjust
    typedef enum logic [1:0] {
        SEL_IDLE,
        SEL_MAIN,
        SEL_PHASE
    } sel_state_t;
    sel_state_t sel_state, sel_next;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            sel_state <= SEL_IDLE;
        else
            sel_state <= sel_next;
    end

    always_comb begin
        sel_next = sel_state;
        case (sel_state)
            SEL_IDLE: begin
                if (start_phase_adj)
                    sel_next = SEL_PHASE;
                else if (start_main_op)
                    sel_next = SEL_MAIN;
            end
            SEL_MAIN: begin
                if (main_op_done)
                    sel_next = SEL_IDLE;
            end
            SEL_PHASE: begin
                if (phase_adjust_done_internal)
                    sel_next = SEL_IDLE;
            end
        endcase
    end

    // Instantiate cfg_write_fsm (handles one Avalon-MM write)
    cfg_write_fsm u_cfg_write (
        .clk                    (clk),
        .rst_n                  (rst_n),
        .start_single_write     (cfg_start_single_write),
        .single_write_done_out  (cfg_single_write_done),
        .write_addr_in          (cfg_addr_in),
        .write_be_in            (cfg_be_in),
        .write_data_in          (cfg_data_in),
        .avmm_address_out       (main_addr),
        .avmm_writedata_out     (main_data),
        .avmm_byteenable_out    (main_be),
        .avmm_write_out         (main_write),
        .avmm_read_out          (main_read),
        .avmm_waitrequest       (avmm_waitrequest)
    );

    // Instantiate triple_write_fsm (handles three sequential writes)
    triple_write_fsm u_triple_write (
        .clk                        (clk),
        .rst_n                      (rst_n),
        .start_three_writes         (triple_start_three_writes),
        .three_writes_done_out      (triple_three_writes_done),
        .i_m1_val_in                (triple_i_m1_val),
        .start_single_write_to_cfg  (cfg_start_single_write),
        .single_write_done_from_cfg (cfg_single_write_done),
        .addr_to_cfg                (cfg_addr_in),
        .be_to_cfg                  (cfg_be_in),
        .data_to_cfg                (cfg_data_in)
    );

    // Instantiate loop_controller_fsm (handles the for loop)
    loop_controller_fsm u_loop_controller (
        .clk                            (clk),
        .rst_n                          (rst_n),
        .start_main_sequence            (start_main_op), // Connect top-level start
        .main_sequence_done_out         (main_op_done),  // Connect top-level done
        .start_three_writes_to_triple   (triple_start_three_writes),
        .three_writes_done_from_triple  (triple_three_writes_done),
        .i_m1_val_to_triple             (triple_i_m1_val)
    );

    // Instantiate phase adjust FSM
    phase_adjust_fsm u_phase_adjust_fsm (
        .clk                (clk),
        .rst_n              (rst_n),
        .start              (start_phase_adj),
        .done               (phase_adjust_done_internal),
        .avmm_address_out   (phase_addr),
        .avmm_writedata_out (phase_data),
        .avmm_byteenable_out(phase_be),
        .avmm_write_out     (phase_write),
        .avmm_read_out      (phase_read),
        .avmm_waitrequest   (avmm_waitrequest)
    );

    // Avalon-MM arbitration
    always_comb begin
        case (sel_state)
            SEL_PHASE: begin
                avmm_address    = phase_addr;
                avmm_writedata  = phase_data;
                avmm_byteenable = phase_be;
                avmm_write      = phase_write;
                avmm_read       = phase_read;
            end
            SEL_MAIN: begin
                avmm_address    = main_addr;
                avmm_writedata  = main_data;
                avmm_byteenable = main_be;
                avmm_write      = main_write;
                avmm_read       = main_read;
            end
            default: begin
                avmm_address    = '0;
                avmm_writedata  = '0;
                avmm_byteenable = '0;
                avmm_write      = 1'b0;
                avmm_read       = 1'b0;
            end
        endcase
    end

    assign phase_adj_done = phase_adjust_done_internal;

endmodule
