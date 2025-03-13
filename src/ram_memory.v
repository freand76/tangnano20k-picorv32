module ram_memory(
                  input         clk, wen,
                  input [11:0]  address,
                  input [31:0]  wdata,
                  output [31:0] rdata
                  );

   reg [31:0]                   mem [0:512];

   assign rdata = mem[address[11:2]];

   always @(posedge clk)
     begin
        if (wen)
          begin
             mem[address[11:2]] <= wdata;
          end
     end

endmodule
