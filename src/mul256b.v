//
/*


256bit乘法器，采用并行乘法器实现。16组17bit乘法器，另加16个周期数据累加，共35个时钟周期
*/
//
module mul256b
(
    clk,
    rstn,
	update,
    datax,
    datay,
    result
)
parameter SEP_WIDTH = 17;

input clk;
input rstn;
input update;
input [255:0] datax;
input [255:0] datay;
output [511:0] result;

reg  [9:0] i;
reg  update_buf;
reg  [16:0] datay_sep [15:0];
reg  [16:0] datax_sep 	    ;
reg  [255:0]datax_shift ;
reg  [37:0] mulresult_temp [31:0]; //实际使用32组[31:0]，第一组为0，助力进位累加公式

//将datay按17bit拆分为16组
reg [16:0] mul_cnt = 0;
reg [16:0] acc_cnt = 0;
always @ (posedge clk)
begin
	update_buf <= update;
	if(~update_buf && update) begin //输入锁存
		mul_cnt <= 1; //begin with 1
		acc_cnt <= 0; //begin with 0
		{datax_shift,datax_sep} <= datax;

		// datay_sep[0 ] <= datay[SEP_WIDTH-1: 0];
		// datay_sep[1 ] <= datay[SEP_WIDTH*2-1: SEP_WIDTH];
		// datay_sep[14] <= datay[SEP_WIDTH*15-1: SEP_WIDTH*14];

		for (i=0;i<15;i=i+1) begin
			datay_sep[i] <= datay[SEP_WIDTH*(i+1)-1: SEP_WIDTH*i];
		end
datay_sep[15] <= {16'd0,datay[255]};

		for (i=0;i<32;i=i+1) begin
			mulresult_temp[i] <= 0;
		end
	end
	else begin
		if(mul_cnt< 17'd17)
		begin
			mul_cnt <= mul_cnt + 1;
			acc_cnt <= 0;
			//datax通过移位分离为16组,乘法结果相当于存在ram中
			{datax_shift,datax_sep} <= datax_shift;
			for (i=0;i<16;i=i+1) begin
				//第1 次mul_cnt=1 ，mulresult_temp[1:16][], 乘积 + 0  + mulresult_temp[0][33:17];
				//第2 次mul_cnt=2 ，mulresult_temp[2:17][], 乘积 + mulresult_temp[1:16][] + mulresult_temp[0:15][33:17]
				//第16次mul_cnt=16，mulresult_temp[16:31][], mulresult_temp[30]这一次乘积后加0后的值
				//mulresult_temp[mul_cnt + i] <= datay_sep[i] * datax_sep + mulresult_temp[mul_cnt + i]  + mulresult_temp[mul_cnt + i-1][33:17]
				mulresult_temp[mul_cnt + i] <= (datay_sep[i] * datax_sep + mulresult_temp[mul_cnt + i-1][33:17]) + mulresult_temp[mul_cnt + i];
			end
		end
		else begin //mul_cnt == 17
			//最后一组mulresult_temp[16:31][]，还没进行进位处理，这里再依次进位15次
			mul_cnt <= 17;
			if(acc_cnt<15)begin
				//第一次   mulresult_temp[17][] = mulresult_temp[17][] + mulresult_temp[16][33:17]
				//最后一次 mulresult_temp[31][] = mulresult_temp[31][] + mulresult_temp[30][33:17]
				acc_cnt <= acc_cnt + 1;
				mulresult_temp[mul_cnt + acc_cnt ] <= mulresult_temp[mul_cnt + acc_cnt ] + mulresult_temp[mul_cnt + acc_cnt - 1][33:17]；
			end
			else begin // 计算完成
				for (i=0;i<32;i=i+1) begin
					//第1 组： result[16 :0  ]  = mulresult_temp[1][16:0];
					//第2 组： result[33 :17 ]  = mulresult_temp[2][16:0];
					//第30组： result[509:493]  = mulresult_temp[31][16:0];
					result[17*(i+1)-1:17*i]    <= mulresult_temp[i+1][16:0];
				end
					//还有一个高17bit，因最后的运算为1bit*1bit，所以这个值为2bit
					result[511:510]  <= mulresult_temp[i+1][18:17];
			end
		end
	end
end
 