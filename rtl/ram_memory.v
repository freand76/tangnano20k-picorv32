`timescale 1ns / 1ns
`default_nettype none

module ram_memory(
                  input         clk_cpu,
                  input         clk_pixel,
                  input         sel,
                  input [3:0]   wen,
                  input [15:0]  address,
                  input [31:0]  wdata,
                  output [31:0] rdata,

                  input [15:0]  video_raddr,
                  output [31:0] video_rdata
                  );

   wire [31:0]                  rdata0, rdata1, rdata2, rdata3;
   wire [31:0]                  video_rdata0, video_rdata1, video_rdata2, video_rdata3;

   assign rdata = address[15:13] == 3'h0 ? rdata0 :
                  address[15:13] == 3'h1 ? rdata1 :
                  address[15:13] == 3'h2 ? rdata2 : rdata3;

   assign video_rdata = video_raddr[15:13] == 3'h0 ? video_rdata0 :
                        video_raddr[15:13] == 3'h1 ? video_rdata1 :
                        video_raddr[15:13] == 3'h2 ? video_rdata2 : video_rdata3;

   dpb_2048x32 #(
                 .BLKSEL(3'h0)
                 )
   mem0(
        .doa(rdata0),
        .dob(video_rdata0),
        .dia(wdata),
        .dib(32'h0),
        .ada(address),
        .adb(video_raddr),
        .clka(clk_cpu),
        .clkb(clk_pixel),
        .sela(sel),
        .selb(1'b1),
        .wrea(wen),
        .wreb(4'b0000)
        );

   dpb_2048x32 #(
                 .BLKSEL(3'h1)
                 )
   mem1 (
         .doa(rdata1),
         .dob(video_rdata1),
         .dia(wdata),
         .dib(32'h0),
         .ada(address),
         .adb(video_raddr),
         .clka(clk_cpu),
         .clkb(clk_pixel),
         .sela(sel),
         .selb(1'b1),
         .wrea(wen),
         .wreb(4'b0000)
         );

   dpb_2048x32 #(
                 .BLKSEL(3'h2)
                 )
   mem2 (
         .doa(rdata2),
         .dob(video_rdata2),
         .dia(wdata),
         .dib(32'h0),
         .ada(address),
         .adb(video_raddr),
         .clka(clk_cpu),
         .clkb(clk_pixel),
         .sela(sel),
         .selb(1'b1),
         .wrea(wen),
         .wreb(4'b0000)
         );

   dpb_2048x32 #(
                 .BLKSEL(3'h3)
                 )
   mem3 (
         .doa(rdata3),
         .dob(video_rdata3),
         .dia(wdata),
         .dib(32'h0),
         .ada(address),
         .adb(video_raddr),
         .clka(clk_cpu),
         .clkb(clk_pixel),
         .sela(sel),
         .selb(1'b1),
         .wrea(wen),
         .wreb(4'b0000)
         );

endmodule
