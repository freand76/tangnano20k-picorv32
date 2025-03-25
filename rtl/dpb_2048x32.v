`timescale 1ns / 1ns
`default_nettype none

module dpb_2048x32
  #(
    parameter [2:0] BLKSEL = 3'b000
    )
   (
    input         clka,
    input         clkb,
    input [31:0]  dia,
    input [31:0]  dib,
    input [15:0]  ada, // 3 highest bits goes to blksel
    input [15:0]  adb, // 3 highest bits goes to blksel
    input [3:0]   wrea,
    input [3:0]   wreb,
    input         sela,
    input         selb,
    output [31:0] doa,
    output [31:0] dob
    );

   dpb_2048x8 #(
                .BLKSEL(BLKSEL)
                )
   mem_7_0 (
            .doa(doa[7:0]),
            .dob(dob[7:0]),
            .dia(dia[7:0]),
            .dib(dib[7:0]),
            .ada(ada[15:2]),
            .adb(adb[15:2]),
            .clka(clka),
            .clkb(clkb),
            .sela(sela),
            .selb(selb),
            .wrea(wrea[0]),
            .wreb(wreb[0])
            );

   dpb_2048x8 #(
                .BLKSEL(BLKSEL)
                )
   mem_15_8 (
             .doa(doa[15:8]),
             .dob(dob[15:8]),
             .dia(dia[15:8]),
             .dib(dib[15:8]),
             .ada(ada[15:2]),
             .adb(adb[15:2]),
             .clka(clka),
             .clkb(clkb),
             .sela(sela),
             .selb(selb),
             .wrea(wrea[1]),
             .wreb(wreb[1])
             );

   dpb_2048x8 #(
                .BLKSEL(BLKSEL)
                )
   mem_23_16(
             .doa(doa[23:16]),
             .dob(dob[23:16]),
             .dia(dia[23:16]),
             .dib(dib[23:16]),
             .ada(ada[15:2]),
             .adb(adb[15:2]),
             .clka(clka),
             .clkb(clkb),
             .sela(sela),
             .selb(selb),
             .wrea(wrea[2]),
             .wreb(wreb[2])
             );

   dpb_2048x8 #(
                .BLKSEL(BLKSEL)
                )
   mem_31_24(
             .doa(doa[31:24]),
             .dob(dob[31:24]),
             .dia(dia[31:24]),
             .dib(dib[31:24]),
             .ada(ada[15:2]),
             .adb(adb[15:2]),
             .clka(clka),
             .clkb(clkb),
             .sela(sela),
             .selb(selb),
             .wrea(wrea[3]),
             .wreb(wreb[3])
             );

endmodule
