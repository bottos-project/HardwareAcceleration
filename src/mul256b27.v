
// 256bit乘法器，采用并行乘法器实现。10组27bit乘法器，另加10个周期数据进位累加，
// 共21个时钟周期
// The Intel® Arria® 10 variable precision DSP block supports a 64-bit accumulator and a 64-bit adder for fixed-point arithmetic

module mul256b27 (
	clk,
	rstn,
	datax,
	datay,
	update,
	result,
	done
);

parameter SEP_WIDTH = 27;

input clk;
input rstn;
input update;
input [255:0] datax;
input [255:0] datay;
output [511:0] result;

reg  [9:0] i;
reg  update_buf;
reg  [SEP_WIDTH-1:0] datax_sep [9:0];
reg  [SEP_WIDTH-1:0] datay_sep 	    ;
reg  [255:0] datax_shift ;
reg  [59:0]  mulresult_temp [19:0]; //实际使用20组[31:0]，第一组为0，助力进位累加公式。最大进位累加20次，因此累加寄存器位宽加5bit
reg  [512:0] mul256x256r = 0;  //乘法运算结束

//将datay按17bit拆分为16组
reg [3:0]  mul_cnt = 0;
reg [3:0]  acc_cnt = 0;

reg [255:0] modzn = 0;

reg  mul1done;

assign result = mul256x256r[511:0]；
assign done   = mul1done;

// 乘法器为27bit*27bit 的 10*10的矩阵乘法，使用21个时钟周期
always @ (posedge clk)
begin
	update_buf <= update;
	if(~update_buf && update) begin //输入锁存
		mul_cnt <= 1; //begin with 1
		acc_cnt <= 0; //begin with 0
		mul1done <= 0

		// datax 分解为10个部分
		// datax_sep[0 ] <= datax[SEP_WIDTH-1: 0];
		// datax_sep[8 ] <= datax[SEP_WIDTH*9-1: SEP_WIDTH*8];
		// datax_sep[9 ] <= datax[255   :        SEP_WIDTH*9];
		for (i=0;i<9;i=i+1) begin
			datax_sep[i] <= datax[SEP_WIDTH*(i+1)-1: SEP_WIDTH*i];
		end
		datax_sep[9] <= {16'd0,datax[255:SEP_WIDTH*9]};

		// datay 的第1部分，赋值给datay_sep
		{datay_shift,datay_sep} <= datay;

		// mulresult_temp初始值必须设置为0
		for (i=0;i<19;i=i+1) begin
			mulresult_temp[i] <= 0;
		end
	end
	else begin
		if(mul_cnt< 4'd11)
		begin
			mul_cnt <= mul_cnt + 1;
			acc_cnt <= 0;
			//datax通过移位分离为10组，
			{datay_shift,datay_sep} <= datay_shift;
			
			//10个乘法器并行，在执行10次，形成10*10的矩阵乘法
			//乘法过程中：同一位置的运算结果共享同一寄存器，累加。同时前一位置需要进位的数也累加到该寄存器。
			for (i=0;i<10;i=i+1) begin
			//最后一组i = 9；  此时实际为10个乘法为 27bit * 14bit乘法器，因此进位的位宽在最后一组进位运算时，大幅度缩减
				mulresult_temp[mul_cnt + i] <= (datax_sep[i] * datay_sep + mulresult_temp[mul_cnt + i-1][59:27]) + mulresult_temp[mul_cnt + i];
				mulresult_temp[mul_cnt + i-1][59:27] <= 0 ; //高位进位后，清0
			end
		end
		else begin //mul_cnt == 11
			//最后一组进位运算 mulresult_temp[10][] ... mulresult_temp[19][]，还没进行进位处理，这里再依次进位10次
			mul_cnt <= 11;
			if(acc_cnt<4'd9)begin
				//第一次   mulresult_temp[11][] = mulresult_temp[11][] + mulresult_temp[10][53:27]
				//最后一次 mulresult_temp[20][] = mulresult_temp[20][] + mulresult_temp[20][33:17]
				acc_cnt <= acc_cnt + 1;
				mulresult_temp[mul_cnt + acc_cnt ] <= mulresult_temp[mul_cnt + acc_cnt ] + mulresult_temp[mul_cnt + acc_cnt - 1][59:27]；
			end
			else begin // 计算完成 ，进行位拼接
				acc_cnt <= 4'd10;
                mul1done <= 1;
				for (i=0;i<19;i=i+1) begin
					//第19组：i=18, result[512:486]  = mulresult_temp[19][26:0];
					mul256x256r[27*(i+1)-1:27*i]    <= mulresult_temp[i+1][26:0];
				end
			end
		end
	end
end