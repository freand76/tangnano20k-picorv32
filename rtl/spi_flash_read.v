`timescale 1ns / 1ns
`default_nettype none

module spi_flash_read
  #(
    parameter FLASH_BASE_ADDRESS = 0
    )
   (
    input             clk,
    input             n_reset,
    input             start,
    input [23:0]      address,
    input [23:0]      word_count,
    output reg        strobe,
    output reg        done,
    output reg [31:0] data_out,
    output reg        spi_cs,
    output reg        spi_clk,
    output reg        spi_mosi,
    input             spi_miso
    );

   reg                                last_spi_clk;

   reg [2:0]                          state;
   reg [15:0]                         bitcnt;
   reg [23:0]                         wcount;

   reg [31:0]                         mosi_shift;
   reg [31:0]                         miso_shift;

   reg                                load_cmd_addr;
   reg                                shifter_active;

   wire [23:0]                        offset_address;

   assign offset_address = FLASH_BASE_ADDRESS + address;

   // SPI MOSI MISO
   always @ (posedge clk, negedge n_reset)
     begin
        if (!n_reset)
          begin
             spi_mosi <= 1'b0;
             mosi_shift <= 32'h00000000;
             miso_shift <= 32'h00000000;
          end
        else
          begin
             spi_mosi <= mosi_shift[31];

             if (load_cmd_addr)
               begin
                  mosi_shift <= { 8'h03, offset_address };
               end
             else
               begin
                  if (shifter_active)
                    begin
                       if (last_spi_clk && !spi_clk)
                         mosi_shift <= { mosi_shift[30:0], 1'b0 };

                       if (!last_spi_clk && spi_clk)
                         miso_shift <= { miso_shift[30:0], spi_miso };
                    end
               end
          end
     end

   // SPI CLK
   always @ (posedge clk, negedge n_reset)
     begin
        if (!n_reset)
          begin
             spi_clk <= 1'b1;
             last_spi_clk <= 1'b0;
          end
        else
          begin
             if (shifter_active)
               begin
                  last_spi_clk <= spi_clk;
                  spi_clk <= ~spi_clk;
               end
          end
     end


   // CTRL

   parameter INIT             = 0;
   parameter CS_LOW           = 1;
   parameter CS_LOW_TO_CLK    = 2;
   parameter SHIFT            = 3;
   parameter SHIFT_AND_STROBE = 4;
   parameter DONE             = 5;

   always @ (posedge clk, negedge n_reset)
     begin
        if (!n_reset)
          begin
             load_cmd_addr <= 0;
             state <= INIT;
             wcount <= 0;
             spi_cs <= 1;
             shifter_active <= 0;
             bitcnt <= 8192;
             data_out <= 0;
             strobe <= 0;
             done <= 0;
          end
        else
          begin
             case(state)
               INIT : // WAIT FOR START
                 begin
                    if (start)
                      begin
                         state <= CS_LOW;
                         load_cmd_addr <= 1;
                      end
                 end
               CS_LOW: // CS LOW
                 begin
                    spi_cs <= 0;
                    load_cmd_addr <= 0;
                    wcount <= word_count;
                    bitcnt <= 20;
                    state <= CS_LOW_TO_CLK;
                 end
               CS_LOW_TO_CLK: // CS LOW ==> SPI_CLK delay
                 begin
                    bitcnt <= bitcnt - 1;
                    if (bitcnt == 0)
                      begin
                         state <= SHIFT;
                         bitcnt <= 130;
                      end
                 end
               SHIFT: // Start shifting
                 begin
                    strobe <= 0;
                    shifter_active <= 1;
                    bitcnt <= bitcnt - 1;
                    if (bitcnt == 0)
                      begin
                         data_out <= {miso_shift[7:0], miso_shift[15:8], miso_shift[23:16], miso_shift[31:24]};
                         state <= SHIFT_AND_STROBE;
                         bitcnt <= 63;
                         wcount <= wcount - 1;
                      end
                 end
               SHIFT_AND_STROBE: // Word Strobe
                 begin
                    strobe <= 1;
                    shifter_active <= 1;
                    bitcnt <= bitcnt - 1;
                    if (wcount == 0)
                      state <= DONE;
                    else
                      state <= SHIFT;
                 end
               DONE: // Done
                 begin
                    spi_cs <= 1;
                    shifter_active <= 0;
                    done <= 1;
                    strobe <= 0;
                    if (start == 0)
                      begin
                         state <= INIT;
                         done <= 0;
                      end
                 end

             endcase // case (state)
          end
     end

endmodule // spi_flash_read
