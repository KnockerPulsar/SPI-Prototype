
module slave1_spi(input clk,input [7:0] ex_input,input css,input SDI,output SDO,input reset,input cpah_controller,input cpol,output [7:0] ex_output,output [1:0] mode);
reg [7:0] state_reg;
wire [7:0] state_next;
localparam state1=2'b00;
localparam state2=2'b01;
localparam state3=2'b10;
localparam state4=2'b11;
reg [1:0] state;
reg out; //Note that below you'll see that I set out = state_reg[1]
	//I did this because state_reg[0] added a third zero after the first correct 2 
//reg cpol;
reg [7:0]ResetValue = 8'b11001100;

//always@(*) begin
//if(out === 1'bx) begin
//out = state_reg[0];
//end
//end


//always@(*) begin
//if(cpol === 1'bx && (clk === 1'b1 || clk === 1'b0)) begin
//cpol = clk;
//end
//end

always @(posedge clk,reset) begin
if(reset)
state_reg=ex_input;
else if(~css &&(state==state2 || state==state3)) begin
//out = state_reg[0];
state_reg = state_next;
end
//else if (css)
//out = 1'bz;
end

always @(negedge clk,reset) begin 
if(reset)
state_reg=ex_input;
else if(~css && (state==state1 || state==state4)) begin
//out = state_reg[0];
state_reg = state_next;
end
//else if (css)
//out=1'bz;
end

always @(state_reg)
begin

if(cpol==0 &&cpah_controller==0)
   state=state1;
else if(cpol==0 &&cpah_controller==1)
    state=state2;
else if(cpol==1 && cpah_controller==1)
   state=state3;
else if(cpol==1 && cpah_controller==0)
   state=state4;
//default: i don't know

end

always @(ex_input)
begin
state_reg = ex_input;
end
assign mode = state;
assign state_next={SDI,state_reg[7:1]};
assign ex_output = state_reg;
assign SDO = (css === 1'b0) ? state_reg[0] : 1'bz;

endmodule


module slave_spi_tb;

reg clock, CS, SDI, reset, phase,cpol;
reg [7:0] Input;
reg [7:0] expected_output;
wire SDO;
wire [7:0] Output;
wire [1:0] mode;
integer i = 0;
integer m = 0;
localparam period = 100;
reg [7:0] ex_input = 8'b11001100;
always #(period/2) clock = ~clock;

initial begin
clock = 0;
CS = 0;
phase = 0;
cpol=0;
reset = 0;
Input = 8'b10110011;
SDI = 0;
//#500 SDI = 1;
#500 reset = 1;
phase = 1;
cpol=1;
#200 reset = 0;
//#1000 CS = 1;
end

//Self-Check Part
always@(*) //Initializing the expected output
begin
	if (expected_output === 8'bx)
		expected_output = Input;
end

always @(Input)
begin
if (reset)
expected_output = Input;
end

always @(Output)
begin 
if (reset)
expected_output = Input;
else if ( $time > 50)
expected_output = { expected_output[0],expected_output[7:1]};
end

always @(posedge clock)
begin
if (mode == 2'b01 || mode == 2'b10)
begin
i = i + 1;
if (expected_output !== Output)
begin
$display ("Incorrect Result for Iteration #%d Expected Output = %b and the Actual Output = %b",i,expected_output,Output);
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

always @(negedge clock)
begin
if (mode == 2'b00 || mode == 2'b11)
begin
i = i + 1;
if (expected_output !== Output)
begin
$display ("Incorrect Result for Iteration #%d Expected Output = %b and the Actual Output = %b",i,expected_output,Output);
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

slave1_spi Slave(clock, Input, CS, SDO, SDO, reset, phase,cpol, Output, mode);

endmodule 
