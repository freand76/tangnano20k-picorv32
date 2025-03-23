`timescale 1ns / 1ns
`default_nettype none

module dpb_2048x8
  #(
    parameter [2:0] BLKSEL = 3'b000
    )
   (
    input        clka,
    input        clkb,
    input [7:0]  dia,
    input [7:0]  dib,
    input [13:0] ada, // 3 highest bits goes to blksel
    input [13:0] adb, // 3 highest bits goes to blksel
    input        wrea,
    input        wreb,
    input        sela,
    input        selb,
    output [7:0] doa,
    output [7:0] dob
    );

   wire [7:0]    dummya;
   wire [7:0]    dummyb;

   DPB mem(
           .DOA({ dummya, doa }),
           .DOB({ dummyb, dob }),
           .DIA({ 8'h0, dia }),
           .DIB({ 8'h0, dib }),
           .ADA({ ada[10:0], 3'h0 }),
           .ADB({ ada[10:0], 3'h0 }),
           .CLKA(clka),
           .CLKB(clkb),
           .OCEA(1'b1),
           .OCEB(1'b1),
           .CEA(sela),
           .CEB(selb),
           .WREA(wrea),
           .WREB(wreb),
           .BLKSELA(ada[13:11]),
           .BLKSELB(ada[13:11]),
           .RESETA(1'b0),
           .RESETB(1'b0)
           );
   defparam mem.READ_MODE0 = 1'b0;
   defparam mem.READ_MODE1 = 1'b0;
   defparam mem.WRITE_MODE0 = 2'b00;
   defparam mem.WRITE_MODE1 = 2'b00;
   defparam mem.BIT_WIDTH_0 = 8;
   defparam mem.BIT_WIDTH_1 = 8;
   defparam mem.BLK_SEL_0 = BLKSEL;
   defparam mem.BLK_SEL_1 = BLKSEL;
   defparam mem.RESET_MODE = "SYNC";

endmodule // dpb_2048x8
