`timescale 1ns / 1ns
`default_nettype none

module iverilog_top;

   logic clk;
   logic n_reset;

   logic video_valid = 1'b0;
   logic [3:0] video_wstrb = 4'h0;
   logic [23:0] video_addr = 24'h0;
   logic [31:0] data_in = 32'h0;
   wire [31:0]  data_out;
   wire [9:0]   tmds_r, tmds_g, tmds_b;

   parameter int IVERILOG_CLOCK = 20_000_000;
   parameter int IVERILOG_CLOCK_HALF_CYCLE = (1_000_000_000 / IVERILOG_CLOCK / 2);

   // VIDEO
   soc_video #(
               .START_X(0),
               .START_Y(510)
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
              .tmds_b(tmds_b)
              );

   task write_video;
      input  [23:0] address;
      input [7:0]  data;
      begin
         logic [3:0] wren;
         case(address[1:0])
              2'b00 : wren = 4'b0001;
              2'b01 : wren = 4'b0010;
              2'b10 : wren = 4'b0100;
              2'b11 : wren = 4'b1000;
         endcase // case (address[1:0])
         data_in = { data, data, data, data};
         video_addr = address;
         video_valid = 1;
         video_wstrb = wren;
         wait(clk == 1'b0);
         wait(clk == 1'b1);
         wait(clk == 1'b0);
         video_valid = 0;
         video_wstrb = 4'b0000;
         video_addr = 24'h0;
    end
   endtask

   int i = 0;

   initial
     begin
        $display("Hello, Video World");
        #2000;
        for (i = 0; i < 256; i = i + 1)
          begin
             write_video(24'hf00000 + i, 8'h00);
          end
        write_video(24'he00000, 8'h11);
        write_video(24'he00001, 8'h22);
        write_video(24'he00002, 8'h33);
        write_video(24'he00003, 8'h44);
        #700000
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
