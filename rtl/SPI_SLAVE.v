`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Mohammad Yasir
// Design Name: SPI Core
// Module Name: SPI_SLAVE
// Project Name: Parameterized SPI Master/Slave
// Target Devices: FPGA
// Description: SPI Slave core with synchronizers aligned for CPOL = 0 and CPOL = 1.
//////////////////////////////////////////////////////////////////////////////////

module SPI_SLAVE #(
    parameter CPOL = 0,
    parameter CPHA = 0
)(
    input  wire       clk,
    input  wire       reset,
    input  wire       sclk,
    input  wire       cs_n,
    input  wire       mosi,
    output reg        miso,
    input  wire [7:0] tx_data,
    output reg  [7:0] rx_data,
    output reg        done
);

    reg [2:0] sclk_sync;
    reg [2:0] cs_n_sync;
    reg [2:0] mosi_sync;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            sclk_sync <= (CPOL != 0) ? 3'b111 : 3'b000;
            cs_n_sync <= 3'b111;
            mosi_sync <= 3'b000;
        end else begin
            sclk_sync <= {sclk_sync[1:0], sclk};
            cs_n_sync <= {cs_n_sync[1:0], cs_n};
            mosi_sync <= {mosi_sync[1:0], mosi};
        end
    end

    wire sclk_clean = sclk_sync[2];
    wire cs_n_clean = cs_n_sync[2];
    wire mosi_clean = mosi_sync[2];

    reg sclk_prev, cs_n_prev;
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            sclk_prev <= (CPOL != 0) ? 1'b1 : 1'b0;
            cs_n_prev <= 1'b1;
        end else begin
            sclk_prev <= sclk_clean;
            cs_n_prev <= cs_n_clean;
        end
    end

    wire sclk_rising  = (sclk_clean == 1'b1) && (sclk_prev == 1'b0);
    wire sclk_falling = (sclk_clean == 1'b0) && (sclk_prev == 1'b1);
    wire cs_rising    = (cs_n_clean == 1'b1) && (cs_n_prev == 1'b0);
    wire cs_falling   = (cs_n_clean == 1'b0) && (cs_n_prev == 1'b1);

    wire sample_edge = (CPOL ^ CPHA) ? sclk_falling : sclk_rising;
    wire shift_edge  = (CPOL ^ CPHA) ? sclk_rising  : sclk_falling;

    reg [7:0] tx_reg;
    reg [7:0] rx_reg;
    reg [3:0] bit_cnt;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            rx_data <= 8'd0;
            rx_reg  <= 8'd0;
            tx_reg  <= 8'd0;
            miso    <= 1'b0;
            bit_cnt <= 4'd0;
            done    <= 1'b0;
        end else begin
            done <= 1'b0;

            if (cs_n_clean) begin
                miso    <= 1'b0;
                bit_cnt <= 4'd0;
                rx_reg  <= 8'd0;
                tx_reg  <= tx_data;
            end else begin
                if (cs_falling) begin
                    tx_reg <= tx_data;
                    if (CPHA == 0)
                        miso <= tx_data[7];
                end

                if (sample_edge) begin
                    rx_reg <= {rx_reg[6:0], mosi_clean};
                end

                if (shift_edge) begin
                    if (CPHA == 1) begin
                        miso   <= tx_reg[7];
                        tx_reg <= {tx_reg[6:0], 1'b0};
                    end else begin
                        tx_reg <= {tx_reg[6:0], 1'b0};
                        miso   <= tx_reg[6];
                    end
                    bit_cnt <= bit_cnt + 1'b1;
                end
            end

            if (cs_rising) begin
                rx_data <= rx_reg;
                done    <= 1'b1;
            end
        end
    end

endmodule