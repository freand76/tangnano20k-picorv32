`default_nettype none

module soc_top
  #(
    parameter int UART_CLOCK_HZ = 27000000,
    parameter int UART_BAUD = 115200,
    parameter SPI_FLASH_BASE = 0
    )
   (
    input        clk,
    input        n_reset,

    output       uart_tx_pin,
    output [5:0] led,

    output       spi_cs,
    output       spi_clk,
    output       spi_mosi,
    output       spi_miso
);

   wire         sfr_start;
   wire         sfr_data_strobe;
   wire         sfr_done;
   wire [31:0]  sfr_data_out;
   wire [23:0]  sfr_address;

   wire         mem_valid;
   wire         mem_instr;
   wire         mem_ready;
   wire [3:0]   mem_wstrb;
   wire [31:0]  mem_addr;
   wire [31:0]  mem_rdata;
   wire [31:0]  mem_wdata;
   wire [31:0]  irq;

   wire [7:0]   uart_tx_data;
   wire         uart_tx_data_valid;

   wire         led_data_valid;
   logic [5:0]  led_reg;

   assign sfr_start = mem_valid;
   assign sfr_address = mem_addr[23:0];
   assign mem_ready = sfr_data_strobe;
   assign mem_rdata = sfr_data_out;
   assign irq = 32'h0;

   assign led = led_reg;
   assign uart_tx_data = mem_wdata[7:0];

   assign uart_tx_data_valid = mem_wstrb[0] & (mem_addr[31:24] == 8'hff);
   assign led_data_valid = mem_wstrb[0] & (mem_addr[31:24] == 8'hfe);

   assign uart_tx_data = mem_wdata[7:0];

   always @ (posedge clk, negedge n_reset)
     begin
        if (!n_reset)
          begin
             led_reg <= 6'h0;
          end
        else
          begin
             if (led_data_valid)
               begin
                  led_reg <= ~mem_wdata[5:0];
               end
          end
     end

   spi_flash_read
     #(
       .FLASH_BASE_ADDRESS(SPI_FLASH_BASE)
       )
   spi_flash_read (
                   .clk(clk),
                   .n_reset(n_reset),
                   .start(sfr_start),
                   .address(sfr_address),
                   .word_count(24'h1),
                   .strobe(sfr_data_strobe),
                   .done(sfr_done),
                   .data_out(sfr_data_out),
                   .spi_cs(spi_cs),
                   .spi_clk(spi_clk),
                   .spi_mosi(spi_mosi),
                   .spi_miso(spi_miso)
                   );

   parameter [0:0] BARREL_SHIFTER = 1;
   parameter [0:0] ENABLE_MUL = 1;
   parameter [0:0] ENABLE_DIV = 1;
   parameter [0:0] ENABLE_FAST_MUL = 0;
   parameter [0:0] ENABLE_COMPRESSED = 1;
   parameter [0:0] ENABLE_COUNTERS = 1;
   parameter [0:0] ENABLE_IRQ_QREGS = 0;

   parameter integer MEM_WORDS = 256;
   parameter [31:0]  STACKADDR = (4*MEM_WORDS);       // end of memory
   parameter [31:0]  PROGADDR_RESET = 32'h 0000_0000;
   parameter [31:0]  PROGADDR_IRQ = 32'h 0000_0000;

   picorv32
     #(
       .STACKADDR(STACKADDR),
       .PROGADDR_RESET(PROGADDR_RESET),
       .PROGADDR_IRQ(PROGADDR_IRQ),
       .BARREL_SHIFTER(BARREL_SHIFTER),
       .COMPRESSED_ISA(ENABLE_COMPRESSED),
       .ENABLE_COUNTERS(ENABLE_COUNTERS),
       .ENABLE_MUL(ENABLE_MUL),
       .ENABLE_DIV(ENABLE_DIV),
       .ENABLE_FAST_MUL(ENABLE_FAST_MUL),
       .ENABLE_IRQ(1),
       .ENABLE_IRQ_QREGS(ENABLE_IRQ_QREGS)
       )
   cpu (
        .clk         (clk        ),
        .resetn      (n_reset    ),
        .mem_valid   (mem_valid  ),
        .mem_instr   (mem_instr  ),
        .mem_ready   (mem_ready  ),
        .mem_addr    (mem_addr   ),
        .mem_wdata   (mem_wdata  ),
        .mem_wstrb   (mem_wstrb  ),
        .mem_rdata   (mem_rdata  ),
        .irq         (irq        )
        );

   uart_tx #(
             .UART_CLK_HZ(UART_CLOCK_HZ),
             .BAUD_RATE(UART_BAUD)
             )
   uart_tx (
            .clk(clk),
            .rst_n(n_reset),
            .tx_data(uart_tx_data),
            .tx_data_valid(uart_tx_data_valid),
            .tx_pin(uart_tx_pin)
            );

  endmodule
