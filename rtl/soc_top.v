`timescale 1ns / 1ns
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

   wire          sfr_start;
   wire          sfr_data_strobe;
   wire          sfr_done;
   wire [31:0]   sfr_data_out;
   wire [23:0]   sfr_address;

   wire          mem_valid;
   wire          mem_instr;
   wire          mem_ready;
   wire [3:0]    mem_wstrb;
   wire [31:0]   mem_addr;
   wire [31:0]   mem_rdata;
   wire [31:0]   mem_wdata;
   wire [31:0]   irq;

   wire [7:0]    uart_tx_data;
   wire          uart_tx_data_ready;

   wire          led_data_valid;
   logic [5:0]   led_reg;

   wire [31:0]   ram_data_out;

   wire [3:0]    ram_wstrb;
   wire          led_wstrb;
   wire          uart_wstrb;

   wire          sfr_valid;
   wire          ram_valid;
   wire          uart_valid;
   wire          led_valid;

   logic         ram_ready;
   logic         uart_ready;
   logic         led_ready;

   // Address decoder
   assign sfr_valid = mem_addr[31:24] == 8'h00;
   assign ram_valid = mem_addr[31:24] == 8'h01;
   assign led_valid = mem_addr[31:24] == 8'hfe;
   assign uart_valid = mem_addr[31:24] == 8'hff;

   assign sfr_start = sfr_valid & mem_valid;
   assign sfr_address = mem_addr[23:0];

   assign uart_wstrb = mem_wstrb[0] & uart_valid;
   assign ram_wstrb = ram_valid ? mem_wstrb : 4'b0000;
   assign led_wstrb = mem_wstrb[0] & led_valid;

   assign mem_ready = sfr_data_strobe || ram_ready || uart_ready || led_ready;

   always @ (posedge clk)
     begin
        ram_ready <= mem_valid && !mem_ready && ram_valid;
        uart_ready <= mem_valid && !mem_ready && uart_valid;
        led_ready <= mem_valid && !mem_ready && led_valid;
     end

   assign mem_rdata = uart_valid ? { 31'b0, uart_tx_data_ready } :
                      sfr_valid ? sfr_data_out :
                      ram_data_out;

   assign irq = 32'h0;

   assign led = led_reg;
   assign uart_tx_data = mem_wdata[7:0];

   always @ (posedge clk, negedge n_reset)
     begin
        if (!n_reset)
          begin
             led_reg <= 6'h0;
          end
        else
          begin
             if (led_wstrb)
               begin
                  led_reg <= ~mem_wdata[5:0];
               end
          end
     end

   ram_memory ram_memory(
                         .clk(clk),
                         .sel(ram_valid),
                         .wen(ram_wstrb),
                         .address(mem_addr[11:0]),
                         .wdata(mem_wdata),
                         .rdata(ram_data_out)
                         );

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
        .irq         (irq        ),
        .trap        (),
        .mem_la_read (),
        .mem_la_write(),
        .mem_la_addr (),
        .mem_la_wdata(),
        .mem_la_wstrb(),
        .pcpi_valid  (),
        .pcpi_insn   (),
        .pcpi_rs1    (),
        .pcpi_rs2    (),
        .pcpi_wr     (),
        .pcpi_rd     (),
        .pcpi_wait   (),
        .pcpi_ready  (),
        .eoi         (),
        .trace_valid (),
        .trace_data  ()
        );

   uart_tx #(
             .UART_CLK_HZ(UART_CLOCK_HZ),
             .BAUD_RATE(UART_BAUD)
             )
   uart_tx (
            .clk(clk),
            .rst_n(n_reset),
            .tx_data(uart_tx_data),
            .tx_data_valid(uart_wstrb),
            .tx_data_ready(uart_tx_data_ready),
            .tx_pin(uart_tx_pin)
            );

  endmodule
