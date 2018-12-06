   
   //随机数，不需要概率控制
   //64bit随机数产生器，至少需要上百年的时间才能循环完一个周期
   module randgen(
   clk,
   rstn,
   load,
   randout
   )
   
   input    clk;
   input    rstn;
   input    load;
   output  reg [255:0] randout;
   
   
   reg  [63:0] sn1;
   reg  [63:0] sn2;
   reg  [63:0] sn3;
   reg  [63:0] sn4;
   reg  [63:0] sn5;
   
   always @(negedge rstn or posedge clk)
   begin
      if (rstn == 1'b0)
      begin
		sn1   <= 64'hD7393EFFA1F80827;
		sn2   <= 64'hC0C4118A30AA36A9;
		sn3   <= 64'h808D074F8699838A;
		sn4   <= 64'hB7B73E57A7006EE9;
		sn5   <= 64'h9191EDE43886F39C;
      end
      else 
      begin
         sn1[63:0] <= {sn1[0]^sn1[61] ^ sn1[2] ^ sn1[4] ^ sn1[13]^sn1[15] ^ sn1[47],sn1[63:1]};
		 sn2[63:0] <= {sn2[0]^sn2[61] ^ sn2[25] ^ sn2[39] ^ sn1[13]^sn2[45] ^ sn2[60],sn2[63:1]};
		 sn3[63:0] <= {sn3[0]^sn3[61] ^ sn3[11] ^ sn3[19] ^ sn3[22]^sn3[43] ^ sn3[51],sn3[63:1]};
		 sn4[63:0] <= {sn4[0]^sn4[61] ^ sn4[14] ^ sn4[23] ^ sn4[15]^sn4[35] ^ sn4[57],sn4[63:1]};
		 sn5[63]   <= sn5[0] ^ sn5[6] ^ sn5[7] ^ sn5[8] ^ sn5[9] ^ sn5[10]^sn5[27] ^ sn5[59];
		 sn5[62:0] <= sn5[63:1];
      end
	 randout <= {sn1^sn5,sn2^sn5,sn3^sn5,sn4^sn5};
	end 
