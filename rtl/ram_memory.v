`timescale 1ns / 1ns
`default_nettype none

module ram_memory(
                  input         clk,
                  input         sel,
                  input [3:0]   wen,
                  input [11:0]  address,
                  input [31:0]  wdata,
                  output [31:0] rdata
                  );

   reg [31:0]                   mem [0:512];
   wire [31:0]                  mem_data;

   assign mem_data = mem[address[11:2]];

   assign rdata = (address[1:0] == 2'b00) ? mem_data :
                  (address[1:0] == 2'b01) ? { 8'b0, mem_data[31:8] } :
                  (address[1:0] == 2'b10) ? { 16'b0, mem_data[31:16] } : { 24'b0, mem_data[31:24] };

   always @(*)
     begin
        if (sel & wen == 4'b0000)
          begin
             $display("Read %x from %x (%b)", rdata, address, wen);
          end
     end

   always @(posedge clk)
     begin
        if (sel)
          begin
             if(wen != 4'b0000)
               begin
                  $display("Write %x to %x (%b)", wdata, address, wen);
               end

             case(wen)
               4'b0001 :
                 mem[address[11:2]] <= { mem_data[31:24] , mem_data[23:16], mem_data[15:8], wdata[7:0] };
               4'b0010 :
                 mem[address[11:2]] <= { mem_data[31:24] , mem_data[23:16], wdata[15:8], mem_data[7:0] };
               4'b0100 :
                 mem[address[11:2]] <= { mem_data[31:24] , wdata[23:16], mem_data[15:8], mem_data[7:0] };
               4'b1000 :
                 mem[address[11:2]] <= { wdata[31:24] , mem_data[23:16], mem_data[15:8], mem_data[7:0] };
               4'b0011 :
                 mem[address[11:2]] <= { wdata[31:16] , mem_data[15:0] };
               4'b1100 :
                 mem[address[11:2]] <= { mem_data[31:16] , wdata[15:0] };
               4'b1111 :
                 mem[address[11:2]] <= wdata;
               default:
                 begin
                    // Empty default to keep linter happy
                 end
             endcase // case (wen)
          end // if (sel)
     end

endmodule
