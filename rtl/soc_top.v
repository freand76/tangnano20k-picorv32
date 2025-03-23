`timescale 1ns / 1ns
`default_nettype none

module soc_top
  #(
    parameter int UART_CLOCK_HZ = 27000000,
    parameter int UART_BAUD = 115200,
    parameter     SPI_FLASH_BASE = 0
    )
   (
    input        clk_cpu,
    input        clk_pixel,
    input        n_reset,

    output       uart_tx_pin,
    output [5:0] led,

    output [9:0] tmds_r,
    output [9:0] tmds_g,
    output [9:0] tmds_b,

    output       spi_cs,
    output       spi_clk,
    output       spi_mosi,
    output       spi_miso
    );

   // SPI Flash Readed
   wire          sfr_start;
   wire          sfr_data_strobe;
   wire          sfr_done;
   wire [31:0]   sfr_data_out;
   wire [23:0]   sfr_address;

   // PICORV32
   wire          mem_valid;
   wire          mem_instr;
   wire          mem_ready;
   wire [3:0]    mem_wstrb;
   wire [31:0]   mem_addr;
   wire [31:0]   mem_rdata;
   wire [31:0]   mem_wdata;
   wire [31:0]   irq;

   // UART
   wire [7:0]    uart_tx_data;
   wire          uart_tx_data_ready;

   // LED
   wire          led_data_valid;
   logic [5:0]   led_reg;

   // VIDEO
   wire [31:0]   video_data_out;

   wire [31:0]   video_raddr;
   wire [31:0]   video_rdata;

   // RAM
   wire [31:0]   ram_data_out;

   // WRITE STROBE
   wire [3:0]    ram_wstrb;
   wire          led_wstrb;
   wire          uart_wstrb;
   wire [3:0]    video_wstrb;

   // ADDRESS DECODER
   wire          sfr_valid;
   wire          ram_valid;
   wire          uart_valid;
   wire          led_valid;
   wire          video_valid;

   // BUS ACKNOWLEDGE
   logic         ram_ready;
   logic         uart_ready;
   logic         led_ready;
   logic         video_ready;

   // ADDRESS DECODER
   assign sfr_valid = mem_addr[31:24] == 8'h00;
   assign ram_valid = mem_addr[31:24] == 8'h01;
   assign video_valid = mem_addr[31:24] == 8'hf0;
   assign led_valid = mem_addr[31:24] == 8'hfe;
   assign uart_valid = mem_addr[31:24] == 8'hff;

   assign mem_rdata = uart_valid ? { 31'b0, uart_tx_data_ready } :
                      sfr_valid ? sfr_data_out :
                      video_valid ? video_data_out :
                      ram_data_out;

   // REQUEST / ACKNOWLEDGE
   assign sfr_start = sfr_valid & mem_valid;
   assign sfr_address = mem_addr[23:0];
   assign mem_ready = sfr_data_strobe || ram_ready || uart_ready || led_ready || video_ready;

   always @ (posedge clk_cpu)
     begin
        ram_ready <= mem_valid && !mem_ready && ram_valid;
        uart_ready <= mem_valid && !mem_ready && uart_valid;
        led_ready <= mem_valid && !mem_ready && led_valid;
        video_ready <= mem_valid && !mem_ready && video_valid;
     end

   // WRITE STROBE
   assign uart_wstrb = mem_wstrb[0] & uart_valid;
   assign ram_wstrb = ram_valid ? mem_wstrb : 4'b0000;
   assign led_wstrb = mem_wstrb[0] & led_valid;
   assign video_wstrb = video_valid ? mem_wstrb : 4'b0000;

   // RAM MEMORY
   ram_memory ram_memory(
                         .clk_cpu(clk_cpu),
                         .clk_pixel(clk_pixel),
                         .sel(ram_valid),
                         .wen(ram_wstrb),
                         .address(mem_addr[15:0]),
                         .wdata(mem_wdata),
                         .rdata(ram_data_out),
                         .video_raddr(video_raddr[15:0]),
                         .video_rdata(video_rdata)
                         );

   // SPI Flash READ
   spi_flash_read
     #(
       .FLASH_BASE_ADDRESS(SPI_FLASH_BASE)
       )
   spi_flash_read (
                   .clk(clk_cpu),
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

   // PICORV32
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

   assign irq = 32'h0;

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
        .clk         (clk_cpu        ),
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

   // LED
   assign led = led_reg;

   always @ (posedge clk_cpu, negedge n_reset)
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

   // UART
   assign uart_tx_data = mem_wdata[7:0];

   uart_tx #(
             .UART_CLK_HZ(UART_CLOCK_HZ),
             .BAUD_RATE(UART_BAUD)
             )
   uart_tx (
            .clk(clk_cpu),
            .rst_n(n_reset),
            .tx_data(uart_tx_data),
            .tx_data_valid(uart_wstrb),
            .tx_data_ready(uart_tx_data_ready),
            .tx_pin(uart_tx_pin)
            );

   // VIDEO
   soc_video soc_video(.clk_cpu(clk_cpu),
                       .clk_pixel(clk_pixel),
                       .n_reset(n_reset),
                       .sel(video_valid),
                       .wren(video_wstrb),
                       .address(mem_addr[23:0]),
                       .wdata(mem_wdata),
                       .rdata(video_data_out),
                       .tmds_r(tmds_r),
                       .tmds_g(tmds_g),
                       .tmds_b(tmds_b),
                       .video_raddr(video_raddr),
                       .video_rdata(video_rdata)
                       );

  endmodule
