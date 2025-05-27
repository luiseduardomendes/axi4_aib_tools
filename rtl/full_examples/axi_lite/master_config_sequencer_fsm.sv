// avalon_config_sequencer.sv
// Top-level module that instantiates and connects the FSMs
// to perform the looped triple write sequence.

module avalon_config_sequencer (
    // Clock and Reset
    input logic clk,
    input logic rst_n,

    // Control Signals
    input logic start_main_op,          // Top-level start signal
    output logic main_op_done,          // Top-level done signal

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


    // Instantiate cfg_write_fsm (handles one Avalon-MM write)
    cfg_write_fsm u_cfg_write (
        .clk                    (clk),
        .rst_n                  (rst_n),
        .start_single_write     (cfg_start_single_write),
        .single_write_done_out  (cfg_single_write_done),
        .write_addr_in          (cfg_addr_in),
        .write_be_in            (cfg_be_in),
        .write_data_in          (cfg_data_in),
        .avmm_address_out       (avmm_address),
        .avmm_writedata_out     (avmm_writedata),
        .avmm_byteenable_out    (avmm_byteenable),
        .avmm_write_out         (avmm_write),
        .avmm_read_out          (avmm_read),
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

endmodule
