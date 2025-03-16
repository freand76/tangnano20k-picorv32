`default_nettype none

module tangnano20k_top(
                       // Clock and Reset
                       input             sys_clk,
                       input             rst,

                       // UART Tx
                       output            uart_tx,

                       // LED (Active LOW)
                       output [5:0]      led,

                       // DVI
                       output wire       tmds_clk_n,
                       output wire       tmds_clk_p,
                       output wire [2:0] tmds_d_n,
                       output wire [2:0] tmds_d_p,

                       // spi flash interface
                       output       mspi_cs,
                       output       mspi_clk,
                       output       mspi_di,
                       input        mspi_do);

   // Reset Handler
   logic [15:0]                     start_wait_cnt;
   logic                            n_reset;

   // Clock
   wire                             clk_pixel_x5;
   wire                             clk_pixel;
   wire                             clk_soc;
   wire                             pll_lock;

   // DVI
   wire [2:0]                       tmds;
   wire [9:0]                       tmds_r, tmds_g, tmds_b;

   // pixel_clock_x5 is 126MHz
   // pixel_clock    is 25.2MHz
   PLL126 dvi_pll(.clkin_27mhz(sys_clk),
                  .clkout_126mhz(clk_pixel_x5),
                  .lock(pll_lock));

   CLKDIV #(.DIV_MODE("5")) clk_div (.CLKOUT(clk_pixel),
                                     .HCLKIN(clk_pixel_x5),
                                     .RESETN(pll_lock)
                                     );

   assign clk_soc = clk_pixel;

   always @ (posedge sys_clk)
     begin
        if (rst & !pll_lock)
          begin
             start_wait_cnt <= 0;
             n_reset <= 0;
          end
        else
          if (start_wait_cnt < 8192)
            begin
               start_wait_cnt <= start_wait_cnt + 1'b1;
            end
          else
            n_reset <= 1;
     end

   soc_top
     #(
     .UART_CLOCK_HZ(25_200_000),
     .UART_BAUD(115_200),
     .SPI_FLASH_BASE('h500000)
       )
   soc(
     .clk_cpu(clk_soc),
     .clk_pixel(clk_pixel),
     .n_reset(n_reset),
     .uart_tx_pin(uart_tx),
     .led(led),
     .tmds_r(tmds_r),
     .tmds_g(tmds_g),
     .tmds_b(tmds_b),
     .spi_cs(mspi_cs),
     .spi_clk(mspi_clk),
     .spi_mosi(mspi_di),
     .spi_miso(mspi_do)
     );

   OSER10 gwSer0(.Q(tmds[2]),
                 .D0(tmds_r[0]),
                 .D1(tmds_r[1]),
                 .D2(tmds_r[2]),
                 .D3(tmds_r[3]),
                 .D4(tmds_r[4]),
                 .D5(tmds_r[5]),
                 .D6(tmds_r[6]),
                 .D7(tmds_r[7]),
                 .D8(tmds_r[8]),
                 .D9(tmds_r[9]),
                 .PCLK(clk_pixel ),
                 .FCLK(clk_pixel_x5 ),
                 .RESET(rst ) );

   OSER10 gwSer1(.Q(tmds[1]),
                 .D0(tmds_g[0]),
                 .D1(tmds_g[1]),
                 .D2(tmds_g[2]),
                 .D3(tmds_g[3]),
                 .D4(tmds_g[4]),
                 .D5(tmds_g[5]),
                 .D6(tmds_g[6]),
                 .D7(tmds_g[7]),
                 .D8(tmds_g[8]),
                 .D9(tmds_g[9]),
                 .PCLK(clk_pixel ),
                 .FCLK(clk_pixel_x5 ),
                 .RESET(rst ) );

   OSER10 gwSer2(.Q(tmds[0]),
                 .D0(tmds_b[0]),
                 .D1(tmds_b[1]),
                 .D2(tmds_b[2]),
                 .D3(tmds_b[3]),
                 .D4(tmds_b[4]),
                 .D5(tmds_b[5]),
                 .D6(tmds_b[6]),
                 .D7(tmds_b[7]),
                 .D8(tmds_b[8]),
                 .D9(tmds_b[9]),
                 .PCLK(clk_pixel),
                 .FCLK(clk_pixel_x5),
                 .RESET(rst));

   TLVDS_OBUF tmds_bufds [3:0] (.I({clk_pixel, tmds}),
                                .O({tmds_clk_p, tmds_d_p}),
                                .OB({tmds_clk_n, tmds_d_n}));

endmodule // tangnano20k_top
