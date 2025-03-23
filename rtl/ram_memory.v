`timescale 1ns / 1ns
`default_nettype none

module ram_memory(
                  input         clk_cpu,
                  input         sel,
                  input [3:0]   wen,
                  input [15:0]  address,
                  input [31:0]  wdata,
                  output [31:0] rdata
                  );

   dpb_2048x8 mem_7_0(
                      .doa(rdata[7:0]),
                      .dob(),
                      .dia(wdata[7:0]),
                      .dib(8'h0),
                      .ada(address[15:2]),
                      .adb(14'h0),
                      .clka(clk_cpu),
                      .clkb(1'b0),
                      .sela(sel),
                      .selb(1'b1),
                      .wrea(wen[0]),
                      .wreb(1'b0)
                      );

   dpb_2048x8 mem_15_8(
                       .doa(rdata[15:8]),
                       .dob(),
                       .dia(wdata[15:8]),
                       .dib(8'h0),
                       .ada(address[15:2]),
                       .adb(14'h0),
                       .clka(clk_cpu),
                       .clkb(1'b0),
                       .sela(sel),
                       .selb(1'b1),
                       .wrea(wen[1]),
                       .wreb(1'b0)
                       );

   dpb_2048x8 mem_23_16(
                        .doa(rdata[23:16]),
                        .dob(),
                        .dia(wdata[23:16]),
                        .dib(8'h0),
                        .ada(address[15:2]),
                        .adb(14'h0),
                        .clka(clk_cpu),
                        .clkb(1'b0),
                        .sela(sel),
                        .selb(1'b1),
                        .wrea(wen[2]),
                        .wreb(1'b0)
                        );

   dpb_2048x8 mem_31_24(
                        .doa(rdata[31:24]),
                        .dob(),
                        .dia(wdata[31:24]),
                        .dib(8'h0),
                        .ada(address[15:2]),
                        .adb(14'h0),
                        .clka(clk_cpu),
                        .clkb(1'b0),
                        .sela(sel),
                        .selb(1'b1),
                        .wrea(wen[3]),
                        .wreb(1'b0)
                        );

endmodule
