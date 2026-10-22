`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Mohammad Yasir
// Design Name: SPI Core
// Module Name: SPI_MASTER
// Project Name: Parameterized SPI Master/Slave
// Target Devices: FPGA
// Description: SPI Master handling bit serialization, deserialization, and
//              timing alignment for SPI Modes 0, 1, 2, and 3.
//////////////////////////////////////////////////////////////////////////////////

module SPI_MASTER #(
    parameter CPOL = 0,
    parameter CPHA = 0
)(
    input  wire       clk,
    input  wire       reset,
    input  wire       start,
    input  wire [7:0] tx_data,
    input  wire       miso,
    output wire       sclk,
    output reg        mosi,
    output reg        cs_n,
    output reg  [7:0] rx_data,
    output wire       busy,
    output reg        done
);

    localparam IDLE     = 2'b00;
    localparam START    = 2'b01;
    localparam TRANSFER = 2'b10;
    localparam STOP     = 2'b11;

    reg [1:0] state;
    reg [7:0] tx_reg;
    reg [7:0] rx_reg;
    reg [3:0] bit_cnt;

    wire edge1_tick, edge2_tick;
    wire sample_tick, shift_tick;

    CLK_DIVIDER #(.CPOL(CPOL)) clk_div_inst (
        .clk(clk),
        .reset(reset),
        .en(busy),
        .sclk(sclk),
        .edge1_tick(edge1_tick),
        .edge2_tick(edge2_tick)
    );

    assign sample_tick = (CPHA == 0) ? edge1_tick : edge2_tick;
    assign shift_tick  = (CPHA == 0) ? edge2_tick : edge1_tick;

    assign busy = (state != IDLE);

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state   <= IDLE;
            cs_n    <= 1'b1;
            mosi    <= 1'b0;
            rx_data <= 8'd0;
            tx_reg  <= 8'd0;
            rx_reg  <= 8'd0;
            bit_cnt <= 4'd0;
            done    <= 1'b0;
        end else begin
            done <= 1'b0;

            case (state)
                IDLE: begin
                    cs_n    <= 1'b1;
                    mosi    <= 1'b0;
                    bit_cnt <= 4'd0;
                    if (start) begin
                        state  <= START;
                        tx_reg <= tx_data;
                        rx_reg <= 8'd0;
                    end
                end

                START: begin
                    cs_n <= 1'b0;
                    mosi <= tx_reg[7];
                    if (CPHA == 0) begin
                        state <= TRANSFER;
                    end else begin
                        if (edge1_tick)
                            state <= TRANSFER;
                    end
                end

                TRANSFER: begin
                    if (sample_tick) begin
                        rx_reg  <= {rx_reg[6:0], miso};
                        bit_cnt <= bit_cnt + 1'b1;
                    end

                    if (shift_tick) begin
                        if (bit_cnt < 4'd8) begin
                            tx_reg <= {tx_reg[6:0], 1'b0};
                            mosi   <= tx_reg[6];
                        end
                    end

                    if (bit_cnt == 4'd8) begin
                        state <= STOP;
                    end
                end

                STOP: begin
                    cs_n    <= 1'b1;
                    done    <= 1'b1;
                    rx_data <= rx_reg;
                    mosi    <= 1'b0;
                    state   <= IDLE;
                end

                default: state <= IDLE;
            endcase
        end
    end

endmodule