

// 256bit乘法器，采用并行乘法器实现。10组27bit乘法器，另加10个周期数据进位累加，共22个时钟周期
// The Intel® Arria® 10 variable precision DSP block supports a 64-bit accumulator and a 64-bit adder for fixed-point arithmetic
// 乘法运算（22clk） + 4次约减求模等效运算（22*2clk + 4clk） + 加法求模 （2clk）
// 使用时间： 72 个时钟周期， 如50Mhz主频，耗时1.4us

module mul256mod#(
    parameter [255:0]  modz =  0xFFFFFFFF_FFFFFFFF_FFFFFFFF_FFFFFFFE_BAAEDCE6_AF48A03B_BFD25E8C_D0364141
)
(
	clk,
	rstn,
	datax,
	datay,
	update,
	result,
	rmode，
	done
);

parameter SEP_WIDTH = 27;

input clk;
input rstn;
input update;
input [255:0] datax;
input [255:0] datay;
output wire [255:0] result;
output wire done;

reg  [9:0] i;
reg  update_buf;
reg  [SEP_WIDTH-1:0] datax_sep [9:0];
reg  [SEP_WIDTH-1:0] datay_sep 	    ;
reg  [255:0] datax_shift ;
reg  [59:0]  mulresult_temp [19:0]; //实际使用20组[31:0]，第一组为0，助力进位累加公式。最大进位累加20次，因此累加寄存器位宽加5bit

wire  [511:0] mul256x256r = 0;  //乘法运算结束
wire  mul1done;


// 模运算
//		datazn <= 0- datay;		dataxa <= datax[511:256]; 		dataxb <= datay[255:0];
// 		datax mod datay = dataxb + dataxa*datazn
// 		datazn <= 0- datay; %129bit
// 		dataxa为高256bit，dataxb为低256bit
// 则有 	（1） r1   = datax mod datay =  dataxb + dataxa * datazn ;  % 256+130bit  涉及乘法器 256bit*129bit ，复用256*256乘法器。
//      	（2）r2  = r1  mod datay   =  r1[255:0] + r1[256+129:256] *  datazn ;  % (130bit*129bit)   130bit + 129bit + 1bit = 260bit;
//     		 (3）r3  = r2  mod datay  =   r2[255:0] + r2[262:256] *  datazn ;      % (4bit*129bit)     256bit + 1bit = 257bit



// 256bit * 256bit ,计算完成将延迟22个clk时钟周期，输出已锁存。
mul256b27  mul256(
	.clk(clk),
	.rstn(rstn),
	.datax(datax),
	.datay(datay),
	.update(update),
	.result(mul256x256r),
	.done(mul1done)
)

always@（posedge clk）
begin
	mode_begin  <=  mul1done;
	modzn  		<= 	0 - modz;
end

// 模运算第一步
// r1   = datax mod datay =  dataxb + dataxa * datazn ;  % 256+130bit  涉及乘法器 256bit*129bit ，复用256*256乘法器。
// step1： 计算乘法 dh1 * modzn    
//		   不做加法，只对乘法进行拆分，	乘法结果为256+129bit 
//         乘法 256bit*129bit ，复用256*256乘法器
wire  [255:0] dh1;  //高256bit
wire  [255:0] dl1;  //低256bit
wire  [511:0]  modmulr ;  // 有效位宽 [255+129-1:0] 
wire  d1_update;
wire   modmul1done;
assign d1_update = mul1done;
assign dh1 = mul256x256r[511:256];
assign dl1 = mul256x256r[255:0];

mul256b27  modmul1(
	.clk(clk),
	.rstn(rstn),
	.datax(dh1),
	.datay(modzn),
	.update(mul1done),
	.result(modmulr),
	.done(modmul1done)
)


// 模运算第二步
// r2  = r1  mod datay   =  r1[255:0] + r1[256+129:256] *  datazn ;  % (130bit*129bit)   130bit + 129bit + 1bit = 260bit;
// step2： 计算乘法 dh2 * modzn  
//		   不做加法，只对乘法进行拆分，	乘法结果为129+129bit = 258 bit
//		   129bit * 129bit 乘法器， 复用256*256乘法器。 暂无必要单独做一个乘法器
wire  [255:0] dh2;  //高256bit
wire  [255:0] dl2;  //低256bit
wire  [511:0]  modmul2r ;     // 有效位宽 [129*2-1:0] 
wire   d2_update;
wire   modmul2done;
assign d2_update = modmul1done;
assign dh2 = modmulr[511:256];// 有效位宽 [255+129-1:0] 
assign dl2 = modmulr[255:0];

mul256b27  modmul2(
	.clk(clk),
	.rstn(rstn),
	.datax(dh2),
	.datay(modzn),
	.update(d2_update),
	.result(modmul2r),
	.done(modmul2done)
)


// 模运算第3步  约减求模， 所有加法求和后，再 约减求模 1次 
// r3  = r2  mod datay  =   r2[255:0] + r2[262:256] *  datazn ;      % (6bit*129bit)     256bit + 1bit = 257bit
// step3： 计算乘法 dh3 * modzn 
//		   不做加法，只对乘法进行拆分，	乘法结果为（258-256） + 129bit = 131 bit 
//		   129bit * 2bit 乘法器， 有必要单独做一个简单乘法器
wire  [1:0] dh3;  //高256bit
wire  [255:0] dl3;  //低256bit
reg   [255:0]  modmul3r ;     // 有效位宽 [129*2-1:0] 
reg   [255:0]  modmul4r ;     // 有效位宽 [129*2-1:0] 
wire   d3_update;
wire   modmul3done;
assign d3_update = modmul2done;
assign dh3 = modmul2r[511:256];// 有效位宽  129*2-256 = 2bit
assign dl3 = modmul2r[255:0];

reg   d3_update1 = 0;
reg   d3_update2 = 0;
reg   d3_update3 = 0;
reg   d3_update4 = 0;

reg  [256:0]  d4a = 0;
reg  [256:0]  d4b  = 0;
reg  [257:0]  d4  = 0;


//  模运算第4步
reg  [255:0] d5;
wire [255:0] d4l;
wire [1:0]   d4h;

assign   d4l = d4[255:0];
assign   d4h = d4[257:256];

always @ (posedge clk)
begin
	d3_update1 <= d3_update;
	if(~d3_update1 && d3_update) begin
		dl4a <=	dl1 + dl2;  // 可能 进位1bit
	end
	else begin
		d3_update2 <= d3_update1;
		//129bit * 2bit
		case (dh3[1:0])
			2'b00 :  modmul3r  <= 0;
			2'b01 :  modmul3r  <= modzn;
			2'b10 :  modmul3r  <= modzn<<1;
			2'b11 :  modmul3r  <= modzn<<1 + modzn;
			default: modmul3r  <= 0;
		endcase

		d3_update3 <= d3_update2;
		dl4b      <= dl3 + modmul3r;  //

		d3_update4 <= d3_update3;
		d4        <= dl4a + dl4b;  // 大2bit

		//再进行模拆分 d4 = d4l + d4h * datazn
		d3_update5 <= d3_update4;
		case (d4h[1:0])
			2'b00 :  modmul4r  <= 0;
			2'b01 :  modmul4r  <= modzn;
			2'b10 :  modmul4r  <= modzn<<1;
			2'b11 :  modmul4r  <= modzn<<1 + modzn;
			default: modmul4r  <= 0;
		endcase
	end
end


// 最后的  加法求模运算  d4 =  d4l + modmul4r
add256mod  addmod
(
	.clk(clk),
	.rstn(rstn),
	.datax(d4l),
	.datay(modmul4r),
	.update(d3_update5),
	.dataz(result),
	.done(done)
);