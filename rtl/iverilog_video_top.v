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
              .tmds_b(tmds_b)
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

   initial
     begin
        $display("Hello, Video World");
        #2000;
        for (i = 0; i < 2048; i = i + 1)
          begin
             write_ram(24'h000400 + i, 32'h00);
             write_ram(24'h000800 + i, 32'h00);
          end
        write_ram(24'h000400, 32'h03020100);
        write_ram(24'h000404, 32'h07060504);

        write_ram(24'h000800, 32'h11121314);
        write_ram(24'h000804, 32'h15161718);
        write_ram(24'h000808, 32'h21222324);
        write_ram(24'h00080c, 32'h25262728);
        write_ram(24'h000810, 32'h31323334);
        write_ram(24'h000814, 32'h35363738);
        write_ram(24'h000818, 32'h41424344);
        write_ram(24'h00081c, 32'h45464748);
        write_ram(24'h000820, 32'h51525354);
        write_ram(24'h000824, 32'h55565758);
        write_ram(24'h000828, 32'h61626364);
        write_ram(24'h00082c, 32'h65666768);
        write_ram(24'h000830, 32'h71727374);
        write_ram(24'h000834, 32'h75767778);
        write_ram(24'h000838, 32'h81828384);
        write_ram(24'h00083c, 32'h85868788);

        $display("FRAME write done");
        //$monitor("READ %x:%x", video_raddr, video_rdata);
       forever
          #10000000
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
