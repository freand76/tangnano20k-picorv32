`timescale 1ns / 1ns
`default_nettype none

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
    input [31:0]  wdata,
    output [31:0] rdata,

    output [9:0]  tmds_r,
    output [9:0]  tmds_g,
    output [9:0]  tmds_b,

    output [31:0] video_raddr,
    input [31:0]  video_rdata
    );

   // DVI interface
   wire [23:0]    rgb_data;
   wire [9:0]     xpos;
   wire [9:0]     ypos;
   wire           line_end;
   wire           frame_end;
   wire           active;

   // Video Registers
   reg [31:0]     char_offset;
   reg [31:0]     font_offset;
   reg [31:0]     frame_counter;

   // Character Address offset
   reg [10:0]     y_word_offset; // Add word offset 10 for each row (40 byte offset)
   reg [3:0]      x_word_offset; // Add word offset 1 for each 4 chars (4 byte offset)
   reg [3:0]      font_line;
   reg            update_char, update_char_data_ready;
   reg            update_font, update_font_data_ready;
   reg [31:0]     char_data;
   reg [7:0]      font_data;
   reg [7:0]      pixel_data;

   wire [31:0]    char32_raddr, font32_raddr;
   wire           frame;

   assign char32_raddr = char_offset + { 19'h0, y_word_offset, 2'h0 } + { 26'h0, x_word_offset, 2'h0 };
   assign font32_raddr = font_offset + { 21'h0, char_data[7:0], 3'h0 } + { 29'h0, font_line[3], 2'h0 };
   assign video_raddr = update_char ? char32_raddr : font32_raddr;

   assign frame = (ypos == 0) || (ypos == 479) || (xpos == 2) || (xpos == 641);
   assign rgb_data = frame ? 24'hff0000 : { 8'h0, {8{pixel_data[7]}}, 8'h0 };

   // READ VIDEO REGISTER
   assign rdata = address[3:2] == 2'h0 ? char_offset :
                  address[3:2] == 2'h1 ? font_offset : frame_counter;


   // WRITE VIDEO REGISTER
   always @ (posedge clk_cpu)
     begin
        if (!n_reset)
          begin
             char_offset <= 32'h01000400;
             font_offset <= 32'h01000c00;
          end
        else
          begin
             if (sel & (wren != 4'b0000))
               begin
                  case(address[3:2])
                    2'h0 : char_offset <= wdata;
                    2'h1 : font_offset <= wdata;
                    default:
                      begin
                      end
                  endcase // case (address[1:0])
               end
          end
     end // always @ (posedge clk_cpu)

   always @ (posedge clk_pixel)
     begin
        if (!n_reset)
          begin
             frame_counter <= 32'h0;
          end
        else
          begin
             update_char <= 1'b0;
             update_char_data_ready <= update_char;
             update_font <= 0;
             update_font_data_ready <= update_font;

             if (frame_end)
               begin
                  frame_counter <= frame_counter + 32'h1;
                  y_word_offset <= 11'h0;
                  x_word_offset <= 4'h0;
                  update_char <= 1'b1;
                  font_line <= 4'h0;
               end
             else if (line_end)
               begin
                  x_word_offset <= 4'h0;
                  font_line <= font_line + 4'h1;
                  if (ypos[3:0] == 4'b1111)
                    begin
                       y_word_offset <= y_word_offset + 11'd10;
                    end
                  update_char <= 1'b1;
               end
             else if (active && (xpos != 10'h0))
               begin
                  if (xpos[5:0] == 6'h0)
                    begin
                       x_word_offset <= x_word_offset + 4'h1;
                       update_char <= 1'b1;
                    end
               end

             if (update_char_data_ready)
               begin
                  char_data <= video_rdata;
               end
             else if (active && (xpos[3:0] == 4'h4))
               begin
                  char_data <= { 8'h0, char_data[31:8] };
               end

             if ((ypos == 524) && (xpos == 0))
               begin
                  // After FRAME
                  update_font <= 1'b1;
               end
             else if ((ypos < 480) && (xpos == 650))
               begin
                  // After LINE
                  update_font <= 1'b1;
               end
             else if (active && (xpos[3:0] == 4'h8))
               begin
                  // After byte shift
                  update_font <= 1'b1;
               end

             if (update_font_data_ready)
               begin
                  case(font_line[2:1])
                    2'b11 : font_data <= video_rdata[31:24];
                    2'b10 : font_data <= video_rdata[23:16];
                    2'b01 : font_data <= video_rdata[15:8];
                    2'b00 : font_data <= video_rdata[7:0];
                  endcase // case (char_data[1:0])
               end
          end
     end // always @ (posedge clk_pixel)

   always @ (posedge clk_pixel)
     begin

        if (active && (xpos[3:0] == 4'b0001))
          begin
             pixel_data <= font_data;
          end
        else if (active && (xpos[0] == 1'b1))
          begin
             pixel_data <= { pixel_data[6:0], 1'b0 };
          end
     end

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
