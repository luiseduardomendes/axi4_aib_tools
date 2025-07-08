// This module implements a synthesizable Finite-State Machine (FSM) to handle
// Avalon Memory-Mapped (MM) read and write transactions. It replaces the
// task-based approach with a state-driven logic suitable for synthesis.

module avalon_mm_fsm #(
    parameter AVMM_WIDTH = 32,
    parameter BYTE_WIDTH = 4,
    parameter ADDR_WIDTH = 17
) (
    input  bit clk,
    input  bit rst_n,

    // User interface
    input  bit                      start_transaction, // User initiates a transaction
    input  bit                      is_write,          // 1 for write, 0 for read
    input  [ADDR_WIDTH-1:0]         transaction_addr,
    input  [AVMM_WIDTH-1:0]         transaction_wdata,
    input  [BYTE_WIDTH-1:0]         transaction_be,
    output logic [AVMM_WIDTH-1:0]   transaction_rdata,
    output logic                    transaction_done,  // Signals completion of a transaction

    // Avalon MM Interface signals
    output logic [ADDR_WIDTH-1:0]   avm_address,
    output logic                    avm_write,
    output logic                    avm_read,
    output logic [AVMM_WIDTH-1:0]   avm_writedata,
    output logic [BYTE_WIDTH-1:0]   avm_byteenable,
    input  bit [AVMM_WIDTH-1:0]     avm_readdata,
    input  bit                      avm_readdatavalid,
    input  bit                      avm_waitrequest
);

    // FSM State Definitions
    typedef enum logic [2:0] {
        IDLE,
        WRITE_SETUP,
        WRITE_WAIT,
        READ_SETUP,
        READ_WAIT,
        READ_CAPTURE
    } fsm_state_t;

    fsm_state_t current_state, next_state;

    logic [ADDR_WIDTH-1:0] addr_reg;
    logic [AVMM_WIDTH-1:0] wdata_reg;
    logic [BYTE_WIDTH-1:0] be_reg;
    logic                  write_reg;
    logic                  read_reg;

    assign avm_address    = addr_reg;
    assign avm_writedata  = wdata_reg;
    assign avm_byteenable = be_reg;
    assign avm_write      = write_reg;
    assign avm_read       = read_reg;


    // Internal register for read data
    logic [AVMM_WIDTH-1:0] rdata_reg;

    // FSM state register
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_state <= IDLE;
        end else begin
            current_state <= next_state;
        end
    end

    // FSM next state logic and output logic
    always_comb begin
        // Default values for outputs
        next_state        = current_state;
        transaction_done  = 1'b0;
        transaction_rdata = rdata_reg;

        //avm_address       = '0;
        //avm_write         = 1'b0;
        //avm_read          = 1'b0;
        //avm_writedata     = '0;
        //avm_byteenable    = '0;

        case (current_state)
            IDLE: begin
                // Wait for a new transaction to be initiated
                if (start_transaction) begin
                    if (is_write) begin
                        next_state = WRITE_SETUP;
                    end else begin
                        next_state = READ_SETUP;
                    end
                end
            end

            WRITE_SETUP: begin
                // Assert write signals and present address/data
                //avm_write      = 1'b1;
                //avm_read       = 1'b0;
                //avm_address    = transaction_addr;
                //avm_writedata  = transaction_wdata;
                //avm_byteenable = transaction_be;

                // Move to wait state once the slave is ready
                if (!avm_waitrequest) begin
                    next_state = WRITE_WAIT;
                end
            end

            WRITE_WAIT: begin
                 // De-assert write signal after the first cycle of waitrequest being low.
                 // The address and data are held until the transaction is acknowledged.
                //avm_write      = 1'b0;
                next_state     = IDLE;
                transaction_done = 1'b1;
            end

            READ_SETUP: begin
                // Assert read signal and present address
                //avm_write      = 1'b0;
                //avm_read       = 1'b1;
                //avm_address    = transaction_addr;
                //avm_byteenable = transaction_be;

                // Move to wait state once the slave is ready
                if (!avm_waitrequest) begin
                    next_state = READ_WAIT;
                end
            end

            READ_WAIT: begin
                // De-assert read signal. Wait for readdatavalid.
                //avm_read = 1'b0;
                if (avm_readdatavalid) begin
                    next_state = READ_CAPTURE;
                end
            end

            READ_CAPTURE: begin
                // Capture the read data and signal completion.
                // The data is captured internally and will be assigned to the output.
                // This state ensures we only signal 'done' for one cycle.
                transaction_done = 1'b1;
                next_state       = IDLE;
            end

            default: begin
                next_state = IDLE;
            end
        endcase
    end

    // Register to hold read data when it becomes valid
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            addr_reg   <= '0;
            wdata_reg  <= '0;
            be_reg     <= '0;
            write_reg  <= 1'b0;
            read_reg   <= 1'b0;
        end else begin
            case (next_state)
                WRITE_SETUP: begin
                    addr_reg   <= transaction_addr;
                    wdata_reg  <= transaction_wdata;
                    be_reg     <= transaction_be;
                    write_reg  <= 1'b1;
                    read_reg   <= 1'b0;
                end
                READ_SETUP: begin
                    addr_reg   <= transaction_addr;
                    wdata_reg  <= '0;
                    be_reg     <= transaction_be;
                    write_reg  <= 1'b0;
                    read_reg   <= 1'b1;
                end
                default: begin
                    // De-assert read/write in states where they should be low
                    // Typically, you can hold address/data stable until transition done.
                    if (current_state==WRITE_WAIT) begin
                        write_reg <= 1'b0;
                    end
                    if (current_state==READ_WAIT) begin
                        read_reg <= 1'b0;
                    end
                end
            endcase
        end
    end

    always_ff @(posedge clk) begin
        if (current_state == READ_WAIT && avm_readdatavalid) begin
            rdata_reg <= avm_readdata;
        end
    end

endmodule
