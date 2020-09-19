
module spi_interface
(input clk,
input [7:0] Master_Input,
input reg [7:0] Selected_Slave_Input,
input [1:0] choose,
input cpah, 
input cpol,
input reset,
output [7:0] Master_Output,
output [7:0] Slave_Output,
output [1:0] Master_Mode);

reg [7:0] Slave1_Input, Slave2_Input, Slave3_Input;
wire [7:0]  Slave1_Output, Slave2_Output, Slave3_Output;
wire [1:0]  Slave1_Mode, Slave2_Mode, Slave3_Mode;
wire sel1,sel2,sel3;
reg [7:0] Selected_Slave_Output;
wire MISO_SDO, MOSI_SDI, slave_clk;


always @(reset, choose, Slave1_Output, Slave2_Output, Slave3_Output, Selected_Slave_Input) begin
	if (choose == 2'b00) begin
		Selected_Slave_Output = Slave1_Output;
		Slave1_Input = Selected_Slave_Input;
	end
	else if (choose == 2'b01) begin
		Selected_Slave_Output = Slave2_Output;
		Slave2_Input = Selected_Slave_Input;
	end
	else if (choose == 2'b10) begin
		Selected_Slave_Output = Slave3_Output;
		Slave3_Input = Selected_Slave_Input;
	end
end

assign Slave_Output = Selected_Slave_Output;



master_spi master (clk, Master_Input, MISO_SDO, MOSI_SDI, sel1, sel2, sel3, reset, cpah, cpol, slave_clk, choose, Master_Output, Master_Mode);
slave1_spi slave1(slave_clk, Slave1_Input, sel1, MOSI_SDI, MISO_SDO, reset, cpah, cpah, Slave1_Output, Slave1_Mode);
slave1_spi slave2(slave_clk, Slave2_Input, sel2, MOSI_SDI, MISO_SDO, reset, cpah, cpah, Slave2_Output, Slave2_Mode);
slave1_spi slave3(slave_clk, Slave3_Input, sel3, MOSI_SDI, MISO_SDO, reset, cpah, cpah, Slave3_Output, Slave3_Mode);

endmodule 


module tb_spi_integrated;


reg clk , cpah, cpol, reset;
//wire cpah2;

reg [1:0]choose=2'b11;

localparam period = 100; 

always #(period/2)  clk = ~clk;

//New stuff

reg [7:0] Master_Input;
wire [7:0] Master_Output;
wire [1:0] Master_Mode;
wire [7:0] Selected_Slave_Output;
reg [7:0] Selected_Slave_Input;
reg [7:0] Expected_Slave_Output;
reg [7:0] Expected_Master_Output;
reg Expected_Master_LSB;
reg Expected_Slave_LSB;
integer i = 0;
integer m = 0;

initial begin
//Initializing slaves
#(period/2)
choose = 2'b10;
Selected_Slave_Input = 8'b00001111;

#(period/2)
choose = 2'b01;
Selected_Slave_Input = 8'b11110000;

#(period/2)
choose=2'b00;
Selected_Slave_Input = 8'b01100110;
Master_Input = 8'b10011001;

cpah=0;
cpol=0;
clk=0;

reset=1;
Master_Input = 8'b10011001;
choose=2'b00;
Selected_Slave_Input = 8'b01100110;

#(period) reset = 0;
#(period *8) clk=1;
cpol=1;
reset=1;
Master_Input = 8'b10011001;
choose=2'b01;
Selected_Slave_Input = 8'b11110000;


#(period) reset=0;


#(period *8)

cpah=1;

reset=1;
Master_Input = 8'b10011001;
choose=2'b10;
Selected_Slave_Input = 8'b00001111;
#(period) reset=0;

#(period *8) 
clk=0;
cpol = 0;
cpah=1;
reset=1;
Master_Input = 8'b10011001;
choose=2'b10;
Selected_Slave_Input = 8'b10101100;
#(period) reset=0;

end

//Expected Output resetting, it is assumed that the user will input a value to reset to.
always @ (posedge reset) begin
	Expected_Master_Output = Master_Input;
	Expected_Slave_Output = Selected_Slave_Input;
end

always @ (Master_Output) begin
	if (/*Master_Output !== Master_Input*/ reset == 1'b0) begin
	Expected_Slave_LSB = Expected_Slave_Output[0];
	Expected_Master_LSB = Expected_Master_Output[0];
	Expected_Master_Output = {Expected_Slave_LSB, Expected_Master_Output[7:1]};
	end
end

always @ (Selected_Slave_Output) begin
	if (/*Selected_Slave_Output !== Selected_Slave_Input*/ reset == 1'b0) begin
	Expected_Slave_Output = {Expected_Master_LSB, Expected_Slave_Output[7:1]};
	end
end
		
always @(posedge clk && choose !== 2'bxx)
begin
	if (Master_Mode == 2'b01 || Master_Mode == 2'b10)
	begin
		i = i + 1;
		if ({Expected_Master_Output, Expected_Slave_Output} !==  {Master_Output,Selected_Slave_Output})
		begin
			$display ("Incorrect Result for Iteration #%d Given Output = %b and the Actual Output = %b",i,{Expected_Master_Output, Expected_Slave_Output},{Master_Output,Selected_Slave_Output});
			//$display ($time);
			m = m + 1;
		end
		else
		begin
		$display ("Correct Result for Iteration #%d",i);
		end
		if (m == 0 && i >= 100)
		begin
			$write ("Test output is CORRECT");
			$stop;
		end
		else if (i >= 100)
		begin
			$display ("Test Ended with %d incorrect test cases", m);
			$stop;
		end
	end
end

always @(negedge clk && choose !== 2'bxx)
begin
if (Master_Mode == 2'b00 || Master_Mode == 2'b11)
begin
i = i + 1;
if ({Expected_Master_Output, Expected_Slave_Output} !==  {Master_Output,Selected_Slave_Output})
begin
$display ("Incorrect Result for Iteration #%d Given Output = %b and the Actual Output = %b",i,{Expected_Master_Output, Expected_Slave_Output},{Master_Output,Selected_Slave_Output});
$display ($time);
m = m + 1;
end
else
begin
$display ("Correct Result for Iteration #%d",i);
end
if (m == 0 && i >= 100)
begin
$write ("Test output is CORRECT");
$stop;
end
else if (i >= 100)
begin
$display ("Test Ended with %d incorrect test cases", m);
$stop;
end
end
end


spi_interface UUT(clk, Master_Input,Selected_Slave_Input,choose, cpah, cpol, reset, Master_Output, Selected_Slave_Output,Master_Mode);



endmodule 