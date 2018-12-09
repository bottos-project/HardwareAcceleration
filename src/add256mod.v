
// 256bit adder  mod  n
// secp256k1的阶数n，求模 n = 0xFFFFFFFF_FFFFFFFF_FFFFFFFF_FFFFFFFE_BAAEDCE6_AF48A03B_BFD25E8C_D0364141；
// 2 clk delay

module add256mod#(
    parameter [255:0]  modz =  0xFFFFFFFF_FFFFFFFF_FFFFFFFF_FFFFFFFE_BAAEDCE6_AF48A03B_BFD25E8C_D0364141
)
(
	clk,
	rstn,
	datax,
	datay,
	update,
	dataz,
	done
);


input clk;
input [255:0] datax;
input [255:0] datay;
input update;
output reg done;
output [255:0] dataz;

reg  [256:0] adder;
reg  [256:0] adder1;
reg  done1;

//  大1bit求模
always@(posedge clk)
begin
    adder  <= datax + datay;
    adder1 <= adder - modz;
    done1  <= update;
    done   <= done1;
end

assign dataz = adder1[256] ?  adder[255:0]  : adder1[255:0];