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

   assign video_data_out = address[2] ? { 22'b0, ypos } : { 22'b0, xpos };

   always @ (posedge clk_cpu, negedge n_reset)
     begin
        if (!n_reset)
          begin
             rgb_data <= 24'h0;
          end
        else
          begin
             if (wren != 4'b0000)
               begin
                  rgb_data <= video_data_in[23:0];
               end
          end
     end

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
