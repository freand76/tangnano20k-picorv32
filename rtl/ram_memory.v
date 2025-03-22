`timescale 1ns / 1ns
`default_nettype none

module ram_memory(
                  input         clk_cpu,
                  input         sel,
                  input [3:0]   wen,
                  input [12:0]  address,
                  input [31:0]  wdata,
                  output [31:0] rdata
                  );

   wire [7:0]                   dummy_31_24, dummy_23_16, dummy_15_8, dummy_7_0;

   DPB mem_7_0(
               .DOA( {dummy_7_0, rdata[7:0]} ),
               .DOB(),
               .DIA( {8'h0, wdata[7:0]} ),
               .DIB(16'h0),
               .ADA({ address[12:2], 3'h0 }),
               .ADB(14'h0),
               .CLKA(clk_cpu),
               .CLKB(1'b0),
               .OCEA(1'b1),
               .OCEB(1'b1),
               .CEA(sel),
               .CEB(1'b1),
               .WREA(wen[0]),
               .WREB(1'b0),
               .BLKSELA(3'b000),
               .BLKSELB(3'b000),
               .RESETA(1'b0),
               .RESETB(1'b0)
               );
   defparam mem_7_0.BIT_WIDTH_0 = 8;
   defparam mem_7_0.BIT_WIDTH_1 = 8;

   DPB mem_15_8(
                .DOA( {dummy_15_8, rdata[15:8]} ),
                .DOB(),
                .DIA( {8'h0, wdata[15:8]} ),
                .DIB(16'h0),
                .ADA({ address[12:2], 3'h0 }),
                .ADB(14'h0),
                .CLKA(clk_cpu),
                .CLKB(1'b0),
                .OCEA(1'b1),
                .OCEB(1'b1),
                .CEA(sel),
                .CEB(1'b1),
                .WREA(wen[1]),
                .WREB(1'b0),
                .BLKSELA(3'b000),
                .BLKSELB(3'b000),
                .RESETA(1'b0),
                .RESETB(1'b0)
                );
   defparam mem_15_8.BIT_WIDTH_0 = 8;
   defparam mem_15_8.BIT_WIDTH_1 = 8;

   DPB mem_23_16(
                 .DOA( {dummy_23_16, rdata[23:16]} ),
                 .DOB(),
                 .DIA( {8'h0, wdata[23:16]} ),
                 .DIB(16'h0),
                 .ADA({ address[12:2], 3'h0 }),
                 .ADB(14'h0),
                 .CLKA(clk_cpu),
                 .CLKB(1'b0),
                 .OCEA(1'b1),
                 .OCEB(1'b1),
                 .CEA(sel),
                 .CEB(1'b1),
                 .WREA(wen[2]),
                 .WREB(1'b0),
                 .BLKSELA(3'b000),
                 .BLKSELB(3'b000),
                 .RESETA(1'b0),
                 .RESETB(1'b0)
                 );
   defparam mem_23_16.BIT_WIDTH_0 = 8;
   defparam mem_23_16.BIT_WIDTH_1 = 8;

   DPB mem_31_24(
                 .DOA( {dummy_31_24, rdata[31:24]} ),
                 .DOB(),
                 .DIA( {8'h0, wdata[31:24]} ),
                 .DIB(16'h0),
                 .ADA({ address[12:2], 3'h0 }),
                 .ADB(14'h0),
                 .CLKA(clk_cpu),
                 .CLKB(1'b0),
                 .OCEA(1'b1),
                 .OCEB(1'b1),
                 .CEA(sel),
                 .CEB(1'b1),
                 .WREA(wen[3]),
                 .WREB(1'b0),
                 .BLKSELA(3'b000),
                 .BLKSELB(3'b000),
                 .RESETA(1'b0),
                 .RESETB(1'b0)
                 );
   defparam mem_31_24.BIT_WIDTH_0 = 8;
   defparam mem_31_24.BIT_WIDTH_1 = 8;

endmodule
