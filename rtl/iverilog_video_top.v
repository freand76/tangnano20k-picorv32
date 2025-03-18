`timescale 1ns / 1ns
`default_nettype none

module iverilog_top;

   logic clk;
   logic n_reset;

   logic video_valid;
   logic [3:0] video_wstrb;
   logic [23:0] video_addr;
   logic [31:0] data_in;
   wire [31:0]  data_out;
   wire [9:0]   tmds_r, tmds_g, tmds_b;

   wire [9:0]   xpos, ypos;
   wire         pixel;

   parameter int IVERILOG_CLOCK = 20_000_000;
   parameter int IVERILOG_CLOCK_HALF_CYCLE = (1_000_000_000 / IVERILOG_CLOCK / 2);

   // VIDEO
   soc_video #(
               .START_X(0),
               .START_Y(470)
               )
   soc_video (
              .clk_cpu(clk),
              .clk_pixel(clk),
              .n_reset(n_reset),
              .sel(video_valid),
              .wren(video_wstrb),
              .address(video_addr),
              .video_data_in(data_in),
              .video_data_out(data_out),
              .tmds_r(tmds_r),
              .tmds_g(tmds_g),
              .tmds_b(tmds_b),
              .dbg_xpos(xpos),
              .dbg_ypos(ypos),
              .dbg_pixel(pixel)
              );

   initial
     begin
        $display("Hello, Video World");
        $monitor("OUT (%d,%d)=%d", xpos, ypos, pixel);
        #2000000
          $finish;
     end

   initial
     begin
        clk = 0;
        video_wstrb = 4'b0000;
        video_addr = 24'h0;
        data_in = 32'h0;
        n_reset = 1;
        #20 n_reset = 0;
        #1000 n_reset = 1;
     end

   always #20 clk = ~clk;

endmodule
