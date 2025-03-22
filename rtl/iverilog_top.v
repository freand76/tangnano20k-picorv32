`timescale 1ns / 1ns
`default_nettype none

module iverilog_top;

   logic clk;
   logic n_reset;

   logic [7:0] uart_byte;

   wire        spi_cs;
   wire        spi_clk;
   wire        spi_mosi;
   wire        spi_miso;

   wire        uart_tx_pin;
   wire [5:0]  led;
   wire [5:0]  led_monitor;

   parameter int IVERILOG_CLOCK = 20_000_000;
   parameter int IVERILOG_CLOCK_HALF_CYCLE = (1_000_000_000 / IVERILOG_CLOCK / 2);
   parameter int IVERILOG_BAUD = 115200;
   parameter int IVERILOG_HALF_BIT_CYCLE = (1_000_000_000 / IVERILOG_BAUD / 2);
   parameter int IVERILOG_BIT_CYCLE = (IVERILOG_HALF_BIT_CYCLE * 2);

   soc_top
     #(
       .UART_CLOCK_HZ(IVERILOG_CLOCK),
       .UART_BAUD(IVERILOG_BAUD),
       .SPI_FLASH_BASE(0)
       )
   soc(
       .clk_cpu(clk),
       .clk_pixel(),
       .n_reset(n_reset),
       .uart_tx_pin(uart_tx_pin),
       .led(led),
       .spi_cs(spi_cs),
       .spi_clk(spi_clk),
       .spi_mosi(spi_mosi),
       .spi_miso(spi_miso),
       .tmds_r(),
       .tmds_g(),
       .tmds_b()
       );

`ifndef VERILATOR
   W25Q64JVxxIM w25q64(.CSn(spi_cs),
                       .CLK(spi_clk),
                       .DIO(spi_mosi),
                       .DO(spi_miso),
                       .WPn(),
                       .HOLDn(),
                       .RESETn(n_reset));
`endif

   assign led_monitor = ~led;
   initial
     begin
        $display("Hello, World");
        $monitor("LED %x", led_monitor);

        #10000000
          $finish;
     end

   initial
     begin
        clk = 0;
        n_reset = 1;
        #20 n_reset = 0;
        #1000 n_reset = 1;
     end

   always #IVERILOG_CLOCK_HALF_CYCLE clk = ~clk;
   int uart_bit = 0;

   always @ (negedge uart_tx_pin)
     begin
        if (!uart_tx_pin)
          begin
             uart_byte = 8'h00;
             #IVERILOG_HALF_BIT_CYCLE;
               for (uart_bit=0; uart_bit < 8; uart_bit = uart_bit + 1)
                 begin
                    #IVERILOG_BIT_CYCLE
                             uart_byte = { uart_tx_pin, uart_byte[7:1] };
                 end
             #IVERILOG_BIT_CYCLE;
             $display("%0t: UART DATA: %x (%c)", $time, uart_byte, uart_byte);
          end
     end

endmodule
