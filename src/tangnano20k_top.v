`default_nettype none

module tangnano20k_top(
                       // Clock and Reset
                       input        sys_clk,
                       input        rst,

                       // UART Tx
                       output       uart_tx,

                       // LED (Active LOW)
                       output [5:0] led,

                       // spi flash interface
                       output       mspi_cs,
                       output       mspi_clk,
                       output       mspi_di,
                       input        mspi_do);

   // Connections
   wire                             n_reset;

   assign n_reset = !rst;

   soc_top
     #(
       .UART_CLOCK_HZ(27_000_000),
       .UART_BAUD(115_200),
       .SPI_FLASH_BASE('h500000)
       )
   soc(
       .clk(sys_clk),
       .n_reset(n_reset),
       .uart_tx_pin(uart_tx),
       .led(led),
       .spi_cs(mspi_cs),
       .spi_clk(mspi_clk),
       .spi_mosi(mspi_di),
       .spi_miso(mspi_do)
       );

endmodule // tangnano20k_top
