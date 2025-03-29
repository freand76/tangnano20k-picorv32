`timescale 1ns / 1ns
`default_nettype none

module iverilog_top;

   logic clk_cpu;
   logic clk_pixel;
   logic n_reset;

   logic ram_valid = 1'b0;
   logic [3:0] ram_wstrb = 4'h0;
   logic [23:0] ram_addr = 24'h0;
   logic [31:0] ram_wdata = 32'h0;
   wire [31:0]  ram_rdata;
   wire [9:0]   tmds_r, tmds_g, tmds_b;

   wire         video_valid = 0;
   logic [3:0]  video_wstrb = 4'b0000;
   logic [23:0] video_addr = 24'h0;
   logic [31:0] video_data_in = 32'h0;
   wire [31:0]  video_data_out;

   wire [31:0]  video_raddr;
   wire [31:0]  video_rdata;

   parameter int IVERILOG_CLOCK = 20_000_000;
   parameter int IVERILOG_CLOCK_HALF_CYCLE = (1_000_000_000 / IVERILOG_CLOCK / 2);

   wire [9:0]    dbg_xpos, dbg_ypos;
   wire [7:0]    dbg_pixel;

   // VIDEO
   soc_video #(
               .START_X(0),
               .START_Y(460)
               )
   soc_video (
              .clk_cpu(clk_cpu),
              .clk_pixel(clk_pixel),
              .n_reset(n_reset),
              .sel(video_valid),
              .wren(video_wstrb),
              .address(video_addr),
              .wdata(video_data_in),
              .rdata(video_data_out),
              .video_raddr(video_raddr),
              .video_rdata(video_rdata),
              .tmds_r(tmds_r),
              .tmds_g(tmds_g),
              .tmds_b(tmds_b),
              .dbg_xpos(dbg_xpos),
              .dbg_ypos(dbg_ypos),
              .dbg_pixel(dbg_pixel)
              );

   // RAM MEMORY
   ram_memory ram_memory(
                         .clk_cpu(clk_cpu),
                         .clk_pixel(clk_pixel),
                         .sel(ram_valid),
                         .wen(ram_wstrb),
                         .address(ram_addr[15:0]),
                         .wdata(ram_wdata),
                         .rdata(ram_rdata),
                         .video_raddr(video_raddr[15:0]),
                         .video_rdata(video_rdata)
                         );

   task write_ram;
      input  [23:0] address;
      input [31:0]  data;
      begin
         ram_valid = 1;
         ram_wstrb = 4'b1111;
         ram_addr = address;
         ram_wdata = data;
         wait(clk_cpu == 1'b0);
         wait(clk_cpu == 1'b1);
         wait(clk_cpu == 1'b0);
         ram_valid = 0;
         ram_wstrb = 4'b0000;
         ram_addr = 24'h0;
      end
   endtask

   logic [23:0]      i;

   wire              char_start = (dbg_xpos[3:0] == 4'h2);

   initial
     begin
        $display("Hello, Video World");
        for (i = 0; i < 2048; i = i + 1)
          begin
             write_ram(24'h000400 + i, 32'h00);
             write_ram(24'h000800 + i, 32'h00);
          end
        write_ram(24'h000800, 32'h03020100);
        write_ram(24'h000804, 32'h07060504);

        write_ram(24'h000400, 32'h14131211);
        write_ram(24'h000404, 32'h18171615);
        write_ram(24'h000408, 32'h24232221);
        write_ram(24'h00040c, 32'h28272625);
        write_ram(24'h000410, 32'h34333231);
        write_ram(24'h000414, 32'h38373635);
        write_ram(24'h000418, 32'h44434241);
        write_ram(24'h00041c, 32'h48474645);
        write_ram(24'h000420, 32'h54535251);
        write_ram(24'h000424, 32'h58575655);
        write_ram(24'h000428, 32'h64636261);
        write_ram(24'h00042c, 32'h68676665);
        write_ram(24'h000430, 32'h74737271);
        write_ram(24'h000434, 32'h78777675);
        write_ram(24'h000438, 32'h84838281);
        write_ram(24'h00043c, 32'h88878685);

        $display("FRAME write done");
        $monitor("X: %3d Y: %3d PIXEL_DATA %b %b (%x,%x)", dbg_xpos, dbg_ypos, dbg_pixel, char_start, video_raddr, video_rdata);
        wait(dbg_ypos == 1);
        wait(dbg_xpos == 90);
        $finish;
     end

   initial
     begin
        clk_cpu = 0;
        clk_pixel = 0;
        video_wstrb = 4'b0000;
        video_addr = 24'h0;
        video_data_in = 32'h0;
        n_reset = 1;
        #20 n_reset = 0;
        #1000 n_reset = 1;
     end

   always #20 clk_cpu = ~clk_cpu;
   always #22 clk_pixel = ~clk_pixel;

endmodule
