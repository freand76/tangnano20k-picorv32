`timescale 1ns / 1ns
`default_nettype none

// update      X 1 0
// update_dly1 X 0 1
// update_dly2 X 0 0 1
// char_x      X 0 0 0
// char_y      X 0 0 0
// char_ram    X X D D
// font_ram    X X X D


module soc_video  #(
                    parameter START_X = 0, // FOR DEBUG PUPROSES
                    parameter START_Y = 0  // FOR DEBUG PUPROSES
                    )
   (
    input         clk_pixel,
    input         clk_cpu,
    input         n_reset,

    input         sel,
    input [3:0]   wren,
    input [23:0]  address,
    input [31:0]  video_data_in,
    output [31:0] video_data_out,

    output [9:0]  tmds_r,
    output [9:0]  tmds_g,
    output [9:0]  tmds_b
    );

   wire [23:0]    rgb_data;
   wire [9:0]     xpos;
   wire [9:0]     ypos;
   wire           line_end;
   wire           frame_end;
   wire           active;
   wire [7:0]     character_ram_out, font_ram_out;
   reg [7:0]      pixel_data;

   assign video_data_out = !address[23] & address[2] ? { 22'b0, ypos } : { 22'b0, xpos };

   reg [5:0]      char_x;
   reg [4:0]      char_y;
   reg [2:0]      font_line;
   reg [7:0]      font_data;

   reg            update, update_dly1, update_dly2;

   wire           frame;
   wire [10:0] char_address = {char_y, char_x};
   wire [10:0] font_address = { character_ram_out, font_line };

   assign frame = (ypos == 0) || (ypos == 479) || (xpos == 2) || (xpos == 641);
   assign rgb_data = frame ? 24'hff0000 : { 8'h0, {8{pixel_data[7]}}, 8'h0 };

   always @ (posedge clk_pixel)
     begin
        update <= 0;
        update_dly1 <= update;
        update_dly2 <= update_dly1;

        if (frame_end)
          begin
             char_x <= 6'h0;
             char_y <= 5'h0;
             font_line <= 3'h0;
             update <= 1;
          end
        else if (line_end)
          begin
             char_x <= 6'h0;
             update <= 1;
             if (ypos[3:0] == 4'b1111)
               begin
                  char_x <= 6'h0;
                  char_y <= char_y + 5'h1;
                  font_line <= 3'h0;
               end
             else if (ypos[0] == 1'b1)
               begin
                  font_line <= font_line + 1;
               end
          end
        else if (active && (xpos[3:0] == 4'b0000))
          begin
             char_x <= char_x + 6'h1;
             update <= 1;
          end

        if (update_dly2)
          begin
             font_data <= font_ram_out;
          end

        if (active && (xpos[3:0] == 4'b0000))
          begin
             pixel_data <= font_data;
          end
        else if (active && (xpos[0] == 1'b0))
          begin
             pixel_data <= { pixel_data[6:0], 1'b0 };
          end
     end

   ram2048x8 #(
               .NAME("Char")
               )
   character_ram(
                 .rclk(clk_pixel),
                 .wclk(clk_cpu),
                 .n_reset(n_reset),
                 .sel(address[23] & address[22] & address[22] & address[20]),
                 .wren(wren),
                 .waddr(address[10:0]),
                 .wdata(video_data_in),
                 .raddr(char_address),
                 .rdata(character_ram_out)
                 );

   ram2048x8  #(
               .NAME("Font")
               )
   font_ram(
            .rclk(clk_pixel),
            .wclk(clk_cpu),
            .n_reset(n_reset),
            .sel(address[23] & address[22] & address[22] & !address[20]),
            .wren(wren),
            .waddr(address[10:0]),
            .wdata(video_data_in),
            .raddr(font_address),
            .rdata(font_ram_out)
            );

   dvi_generator
     #(
       .START_X(START_X),
       .START_Y(START_Y)
       )
   dvi_gen (
            .clk_pixel(clk_pixel),
            .n_reset(n_reset),
            .rgb_data(rgb_data),
            .tmds_r(tmds_r),
            .tmds_g(tmds_g),
            .tmds_b(tmds_b),
            .xpos(xpos),
            .ypos(ypos),
            .line_end(line_end),
            .frame_end(frame_end),
            .active(active)
            );

endmodule // soc_video

module ram2048x8
  #(
    parameter NAME = "Default"
    )
   (
    input        rclk,
    input        wclk,
    input        n_reset,
    input        sel,
    input [3:0]  wren,
    input [10:0] waddr,
    input [31:0] wdata,
    input [10:0] raddr,
    output [7:0] rdata
    );

   wire [10:0]   write_address;
   wire [7:0]    write_data;

   assign write_address = wren == 4'b0010 ? { waddr[10:2], 2'b01 } :
                          wren == 4'b0100 ? { waddr[10:2], 2'b10 } :
                          wren == 4'b1000 ? { waddr[10:2], 2'b11 } : { waddr[10:2], 2'b00 };

   assign write_data = wren == 4'b0010 ? wdata[15:8] :
                       wren == 4'b0100 ? wdata[23:16] :
                       wren == 4'b1000 ? wdata[31:24] : wdata[7:0];

    wire gnd, vcc;
    assign gnd = 1'b0;
    assign vcc = 1'b1;

    wire [7:0] dummy;

    DPB mem(
            .DOA(),
            .DOB({dummy, rdata}),
            .DIA({{8{gnd}}, write_data}),
            .DIB({16{gnd}}),
            .ADA({write_address, gnd, gnd, gnd}),
            .ADB({raddr, gnd, gnd, gnd}),
            .CLKA(wclk),
            .CLKB(rclk),
            .OCEA(vcc),
            .OCEB(vcc),
            .CEA(vcc),
            .CEB(vcc),
            .WREA(sel & (wren[0] | wren[1] | wren[2] | wren[3])),
            .WREB(gnd),
            .BLKSELA(3'b000),
            .BLKSELB(3'b000),
            .RESETA(!n_reset),
            .RESETB(!n_reset)
            );
    defparam mem.READ_MODE0 = 1'b0;
    defparam mem.READ_MODE1 = 1'b0;
    defparam mem.WRITE_MODE0 = 2'b00;
    defparam mem.WRITE_MODE1 = 2'b00;
    defparam mem.BIT_WIDTH_0 = 8;
    defparam mem.BIT_WIDTH_1 = 8;
    defparam mem.BLK_SEL_0 = 3'b000;
    defparam mem.BLK_SEL_1 = 3'b000;
    defparam mem.RESET_MODE = "SYNC";

endmodule
