module master_spi(input clk,input [7:0] ex_input,input MISO,output MOSI,output cs1,output cs2,output cs3,input reset,input cpah_controller,input cpol,output slave_clk,input [1:0]choose,output [7:0] ex_output,output wire [1:0] mode);
reg [7:0] state_reg;
wire [7:0] state_next;
localparam state1=2'b00;
localparam state2=2'b01;
localparam state3=2'b10;
localparam state4=2'b11;
reg [1:0] state;
reg [7:0] ResetValue = 8'b10101010;



//At the positive edge, if the reset is high it resets the register to some value
always @(posedge clk,reset) begin
if(reset )
state_reg=ex_input;
//Otherwise if the module is in states 2 or 3 (check the doc) it sets the value to the shifted value
else if((state==state2 ||state==state3) && MISO !== 1'bz)
state_reg=state_next;
else if (MISO === 1'bz)
state_reg=state_reg;
end

//At the negative edge, if the reset is pulled high it resets the register to some value
always @(negedge clk,reset) begin 
if(reset)
state_reg=ex_input;
//Otherwise if the module is in states 0 or 1 (check the doc) it sets the value to the shifted value
else if((state==state1 || state==state4) && MISO !==1'bz)
state_reg=state_next;
else 
state_reg=state_reg;
end

//On register value change, depending on the cpol and cpah the state is set
//Will probably activate after a reset
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

assign mode = state; //WHY DOES THIS SET STATE_REG TO ZEROS
//Sets up the registers next state (shifting)
assign state_next={MISO,state_reg[7:1]};
assign ex_output = state_reg;
assign cs1= (choose==2'b00)?0:1;
assign cs2= (choose==2'b01)?0:1;
assign cs3= (choose==2'b10)?0:1;

//Assigns the slave clock so that it's the opposite of the master clock.
assign slave_clk=clk;
//Assigns the output for the slaves.
assign MOSI=state_reg[0];

always @(ex_input)
begin
state_reg = ex_input;
end
endmodule

module master_spi_tb;

reg clock, MISO, reset, phase,cpol;
reg [7:0] Input;
reg [1:0] choice;
wire MOSI, CS1, CS2, CS3, sclock;
wire [1:0] mode;
wire [7:0] Output;
localparam period = 100;
reg [7:0] expected_output;
integer i = 0;
integer m = 0;
//reg [7:0] ex_input = 8'b10101010;
always #(period/2) clock = ~clock;

initial begin
clock = 0;
cpol=0;
phase = 0;
choice = 2'b00;
reset = 0;
Input = 8'b11110000;
//MISO = 1;
#500 //MISO = 0;
choice = 1;
#500 reset = 1;
phase = 1;
cpol=1;
#200 reset = 0;
end
//Self-Checking Part
always@(*) //Initializing the expected output
begin
	if(expected_output === 8'bx)
		expected_output = Output;
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
else if ($time > 50 )
expected_output = {expected_output[0],expected_output[7:1]};
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

master_spi Master(clock,Input,MOSI,MOSI,CS1,CS2,CS3,reset,phase,cpol,sclock,choice,Output,mode);

endmodule
