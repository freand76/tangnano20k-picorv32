`timescale 1ns / 1ns
`default_nettype none

module soc_video(input clk_pixel,
                 input         clk_cpu,
                 input         n_reset,

                 input         sel,
                 input [3:0]   wren,
                 input [23:0]  address,
                 input [31:0] video_data_in,
                 output [31:0] video_data_out,

                 output [9:0]  tmds_r,
                 output [9:0]  tmds_g,
                 output [9:0]  tmds_b);

   reg [23:0]                  rgb_data;
   wire [9:0]                  xpos;
   wire [9:0]                  ypos;
   wire                        line_end;
   wire                        frame_end;

   assign video_data_out = !address[23] & address[2] ? { 22'b0, ypos } : { 22'b0, xpos };

   wire [7:0] character_data;

   always @ (posedge clk_pixel)
     begin
        rgb_data <= { character_data, character_data, character_data };
     end

   character_ram character_ram(
                               .clk(clk_cpu),
                               .sel(address[23] & address[22] & address[22] & address[20]),
                               .wren(wren),
                               .waddr(address[10:0]),
                               .wdata(video_data_in),
                               .raddr({xpos, 1'b0}),
                               .rdata(character_data)
                               );

   dvi_generator dvi_gen(.clk_pixel(clk_pixel),
                         .n_reset(n_reset),
                         .rgb_data(rgb_data),
                         .tmds_r(tmds_r),
                         .tmds_g(tmds_g),
                         .tmds_b(tmds_b),
                         .xpos(xpos),
                         .ypos(ypos),
                         .line_end(line_end),
                         .frame_end(frame_end));

endmodule // soc_video

module character_ram(
                     input        clk,
                     input        sel,
                     input [3:0]  wren,
                     input [10:0] waddr,
                     input [31:0] wdata,
                     input [10:0] raddr,
                     output [7:0] rdata
                     );

   reg [7:0]                      mem [0:2047];
   wire [7:0]                     mem_data;

   assign rdata = mem[raddr];

   always @(posedge clk)
     begin
        if (sel)
          begin
             if(wren != 4'b0000)
               begin
                  $display("Character RAM write %x to %x (%b)", wdata, waddr, wren);
               end

             case(wren)
               4'b0010 :
                 mem[{waddr[10:2], 2'b01}] <= { wdata[15:8] };
               4'b0100 :
                 mem[{waddr[10:2], 2'b10}] <= { wdata[23:16] };
               4'b1000 :
                 mem[{waddr[10:2], 2'b11}] <= { wdata[31:24] };
               default:
                 mem[{waddr[10:2], 2'b00}] <= { wdata[7:0] };
             endcase // case (wen)
          end // if (sel)
     end

endmodule
