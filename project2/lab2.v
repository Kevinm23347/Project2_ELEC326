`timescale 1ns/1ns

/*
 * Module: alarm_clock
 * Description: The top module of this lab 
 */
module alarm_clock (
	input CLK,
	input [7:0] SW,
	input [3:0] BTN,
	output [7:0] LED,
	output [6:0] SEG,
	output DP,
	output [7:0] AN
); 
	
	wire [15:0] display_num;
	wire [6:0] display_seg;
	
	wire [5:0] clock_seconds;
	wire [5:0] clock_minutes;
	wire [3:0] clock_hours;
	
	wire [3:0] clock_minutes_ones_digit;
	wire [3:0] clock_minutes_tens_digit;
	
	wire [3:0] clock_hours_ones_digit;
	wire [3:0] clock_hours_tens_digit;
	
	
	wire display_clk_en;
	wire seconds_clk_en;
	
	wire blink_clk_en;
	wire blink_en;
	reg blink;
	
	// alarms
	wire alarm0_triggered, alarm1_triggered;
	wire [5:0] alarm0_minutes;
	wire [3:0] alarm0_hours;
	wire [5:0] alarm1_minutes;
	wire [3:0] alarm1_hours;
	
	// Debounce
	wire [1:0] BTN_down;
		
	// base 10 formatting
	assign display_num[15:12] = clock_hours_tens_digit;
	assign display_num[11:8]  = clock_hours_ones_digit;
	assign display_num[7:4]   = clock_minutes_tens_digit;
	assign display_num[3:0]   = clock_minutes_ones_digit;
	
	assign LED = {alarm1_triggered & blink, alarm0_triggered & blink, clock_seconds};
	assign DP = (~blink_en | blink) ? AN[2] : 1'b1;
	
	display_clkdiv Idisplay_clkdiv (
		.clk_pi(CLK),
		.clk_en_po(display_clk_en));
	
	seconds_clkdiv Iseconds_clkdiv (
		.clk_pi(CLK),
		.clk_en_po(seconds_clk_en));
		
	display_clkdiv #(.SIZE(23)) Iblink_clkdiv (
		.clk_pi(CLK),
		.clk_en_po(blink_clk_en));
		
	assign SEG = (~blink_en | blink) ? display_seg : 7'b1111111;
		
	clock_fsm Iclock_fsm (
		.clk_pi(CLK),
		.clk_en_pi(seconds_clk_en),
		.seconds_po(clock_seconds),
		.minutes_po(clock_minutes),
		.hours_po(clock_hours),
		.increment_minute_pi(BTN_down[0] & ~BTN[2] && ~BTN[3]),
		.increment_hour_pi(BTN_down[1] & ~BTN[2] && ~BTN[3]),
		.blink_en_po(blink_en));
		
	alarm_fsm Ialarm0_fsm (
		.clk_pi(CLK),
		.alarm_en_pi(SW[0]),
		.clock_minutes_pi(clock_minutes),
		.clock_hours_pi(clock_hours),
		
		.minutes_po(alarm0_minutes),
		.hours_po(alarm0_hours),
		
		.increment_minute_pi(BTN_down[0] & BTN[2]),
		.increment_hour_pi(BTN_down[1] & BTN[2]),
		
		.alarm_triggered_po(alarm0_triggered)); 
		
	alarm_fsm Ialarm1_fsm (
		.clk_pi(CLK),
		.alarm_en_pi(SW[1]),
		.clock_minutes_pi(clock_minutes),
		.clock_hours_pi(clock_hours),
		
		.minutes_po(alarm1_minutes),
		.hours_po(alarm1_hours),
		
		.increment_minute_pi(BTN_down[0] & BTN[3]),
		.increment_hour_pi(BTN_down[1] & BTN[3]),
		
		.alarm_triggered_po(alarm1_triggered)); 
		
	sevenSegDisplay IsevenSegDisplay (
		.clk_pi(CLK),
		.clk_en_pi(display_clk_en),
		.num_pi(display_num),
		.seg_po(display_seg),
		.an_po(AN));

	binary_to_BCD Iminutes_BCD (
		.num_pi(BTN[3] ? alarm1_minutes : (BTN[2] ? alarm0_minutes : clock_minutes)),
		.ones_digit_po(clock_minutes_ones_digit),
		.tens_digit_po(clock_minutes_tens_digit));
		
	binary_to_BCD Ihours_BCD (
		.num_pi(BTN[3] ? alarm1_hours : (BTN[2] ? alarm0_hours : clock_hours)),
		.ones_digit_po(clock_hours_ones_digit),
		.tens_digit_po(clock_hours_tens_digit));

	button_debouncer Ibtn0_debouncer (
		.clk(CLK),
		.pushbutton(BTN[0]),
		.pushbutton_down(BTN_down[0]));
		
	button_debouncer Ibtn1_debouncer (
		.clk(CLK),
		.pushbutton(BTN[1]),
		.pushbutton_down(BTN_down[1]));

	initial begin
		blink <= 0;
	end
	
   always @(posedge CLK) begin
	   if(blink_clk_en)
		  blink <= ~blink;
	end

endmodule // alarm_clock


/*
 * Module: clock_fsm 
 * 
 * Description: State machine for a basic 12 hour clock. Initially blinks, until the time is changed by the user.
 * 
 * Outputs current second, minute, and hour values for a 12 hour clock
 *
 * The input clk_en_pi will be 1'b1 for one cycle of the input clk_pi every second.
 */
module clock_fsm(
	input clk_pi,
	input clk_en_pi,
	
	input increment_minute_pi,
	input increment_hour_pi,
	
	output reg [5:0] seconds_po,
	output reg [5:0] minutes_po,
	output reg [3:0] hours_po,
	
	output reg blink_en_po);
	

	initial begin
		seconds_po <= 0;
		minutes_po <= 0;
		hours_po <= 4'd12;
		blink_en_po <= 1;
	end
	
	always @(posedge clk_pi) begin
		if(increment_minute_pi || increment_hour_pi)
			blink_en_po <= 0;
		
		// STEP 2 - implement the clock state machine	
		
		assign blink_en_po = 1;
	
		// END STEP 2
	end
endmodule // clock_fsm


/*
 * Module: alarm_fsm
 *
 * Description: State machine for an alarm for a 12-hour clock. 
 * Outputs the minute and hour values the alarm is currently set for. Defaults to 12:00
 * 
 * With the inputs clock_minutes_pi and clock_hours_pi, it checks to see if the alarm has been triggered
 * If alarm_en_pi is true and the alarm triggers, drives alarm_triggered_po to 1 (driven back to 0 if alarm_en_pi goes to 0).
 */
 module alarm_fsm(
	input clk_pi,
	input alarm_en_pi,
	
	// Used when triggering alarm
	input [5:0] clock_minutes_pi,
	input [3:0] clock_hours_pi,
	
	output reg [5:0] minutes_po,
	output reg [3:0] hours_po,
	
	input increment_minute_pi,
	input increment_hour_pi,
	
	output reg alarm_triggered_po);
 
	initial begin
		minutes_po <= 0;
		hours_po <= 4'd12;
		alarm_triggered_po <= 0;
	end
 
	 // STEP 1 - implement the alarm state machine
	
	always @(posedge clk_pi)
	begin
	if (increment_minute_pi == 1)
	begin 
		minutes_po = (1 + minutes_po) % 6'd60;
	end
	if (increment_hour_pi == 1)
	begin
		hours_po = ((hours_po) % 4'd12) + 1;
	end
	if (alarm_en_pi == 1 & clock_minutes_pi == minutes_po & clock_hours_pi == hours_po)
	begin
		alarm_triggered_po = 1;
	end
	if (alarm_en_pi == 0)
	begin
    		alarm_triggered_po = 0;
	end
	end  
	// END STEP 1
 
 
 endmodule

/* 
 * Module: segmentFormatter
 * 
 * Description: Combinational logic for the seven segment bits of a digit of the seven segment display
 *
 * 0 - LSB of disp_po
 * 6 - MSB of disp_po
 *      --(0)   
 * (5)|      |(1)
 *      --(6)
 * (4)|      |(2)
 *      --(3) 
 * 
 * disp_po is active low 
 */
module segmentFormatter(
	input [3:0] num_pi,
	output reg [6:0] disp_po
);
	always @(*) begin
		case(num_pi)
			4'h0: disp_po = 7'b1000000;
			4'h1: disp_po = 7'b1111001;
			4'h2: disp_po = 7'b0100100;
			4'h3: disp_po = 7'b0110000;
			4'h4: disp_po = 7'b0011001;
			4'h5: disp_po = 7'b0010010;
			4'h6: disp_po = 7'b0000010;
			4'h7: disp_po = 7'b1111000;
			4'h8: disp_po = 7'b0000000;
			4'h9: disp_po = 7'b0010000;
			4'hA: disp_po = 7'b0001000;
			4'hB: disp_po = 7'b0000011;
			4'hC: disp_po = 7'b1000110;
			4'hD: disp_po = 7'b0100001;
			4'hE: disp_po = 7'b0000110;
			4'hF: disp_po = 7'b1111111;
		endcase
	end
endmodule // segmentFormatter

/*
 * Module: sevenSegDisplay
 * Description: Formats an input 16 bit number for the four digit seven-segment display
 */
module sevenSegDisplay(
	input clk_pi,
	input clk_en_pi,
	input[15:0] num_pi,
	output reg [6:0] seg_po,
	output reg [7:0] an_po
);
	
	wire [6:0] disp0, disp1, disp2, disp3, disp4, disp5, disp6, disp7;
		
	segmentFormatter IsegmentFormat0 ( .num_pi(num_pi[3:0]),   .disp_po(disp0));
	segmentFormatter IsegmentFormat1 ( .num_pi(num_pi[7:4]),   .disp_po(disp1));
	segmentFormatter IsegmentFormat2 ( .num_pi(num_pi[11:8]),  .disp_po(disp2));
    segmentFormatter IsegmentFormat3 ( .num_pi(num_pi[15:12]), .disp_po(disp3));
    segmentFormatter IsegmentFormat4 ( .num_pi(4'hF), .disp_po(disp4));
    segmentFormatter IsegmentFormat5 ( .num_pi(4'hF), .disp_po(disp5));
    segmentFormatter IsegmentFormat6 ( .num_pi(4'hF), .disp_po(disp6));
    segmentFormatter IsegmentFormat7 ( .num_pi(4'hF), .disp_po(disp7));
                            	
	initial begin
		seg_po <= 7'h7F;
		an_po <= 8'b11111111;
	end
	
	always @(posedge clk_pi) begin
		if(clk_en_pi) begin
			case(an_po) 
				8'b11111110: begin
					seg_po <= disp1;
					an_po  <= 8'b11111101;
				end
				8'b11111101: begin
					seg_po <= disp2;
					an_po  <= 8'b11111011;
				end
				8'b11111011: begin
					seg_po <= disp3;
					an_po  <= 8'b11110111;
				end
                8'b11110111: begin
                    seg_po <= disp4;
                    an_po  <= 8'b11101111;
                end
                8'b11101111: begin
                    seg_po <= disp5;
                    an_po  <= 8'b11011111;
                end
                8'b11011111: begin
                    seg_po <= disp6;
                    an_po  <= 8'b10111111;
                end
                8'b10111111: begin
                    seg_po <= disp7;
                    an_po  <= 8'b01111111;
                end
				default: begin
					seg_po <= disp0;
					an_po <= 8'b11111110;
				end
			endcase
		end // clk_en
	end // always @(posedge clk_pi)
endmodule // sevenSegDisplay


/*
 * Module: display_clkdiv
 * Description: Generates a clk_en signal that can be used to effectively divide the clock used elsewhere
 *              The seven segment display is not particularly visible with the full 50Mhz clock
 *
 * Parameterized to experiment with different clock frequencies for the display
 */
module display_clkdiv (
	input clk_pi,
	output clk_en_po
);
	
	parameter SIZE = 10;
	
	reg [SIZE-1:0] counter;
		
	initial begin
		counter <= 0;
	end
	
	always @(posedge clk_pi) begin
		counter = counter + 1;
	end
	
	assign clk_en_po = (counter == {SIZE{1'b0}}); 
	
endmodule // display_clkdiv

/*
 * Module: seconds_clkdiv
 * Description: Generates a clk_en signal that triggers once per second
 */
module seconds_clkdiv (
	input clk_pi,
	output clk_en_po
);
	reg [31:0] counter;

	initial begin
		counter <= 32'h0;
	end
	
	always @(posedge clk_pi) begin
	// What is the significance of this number?  Is your clock is too fast or too slow?
		if(counter == 32'h5F5E110)  
			counter <= 32'h0;
		else
			counter <= counter + 1;
	end
	
	assign clk_en_po = (counter == 32'h0); 
	
endmodule // seconds_clock

/*
 * Module: binary_to_BCD
 * Description: converts the input 6-bit binary number into two four bit numbers representing the decimal form (tens and ones digits) of the input number
 */
module binary_to_BCD(
	input [5:0] num_pi,
	output [3:0] ones_digit_po,
	output [3:0] tens_digit_po);
	
	wire [3:0] c1,c2,c3,c4,c5;
	wire [2:0] c6,c7;
	wire [3:0] d1,d2,d3,d4,d5,d6,d7;

	assign d1 = {3'b0,num_pi[5]};
	assign d2 = {c1[2:0],num_pi[4]};
	assign d3 = {c2[2:0],num_pi[3]};
	assign d4 = {c3[2:0],num_pi[2]};
	assign d5 = {c4[2:0],num_pi[1]};
	assign d6 = {1'b0,c1[3],c2[3],c3[3]};
	assign d7 = {c6[2:0],c4[3]};
	bcd_add3 m1(d1,c1);
	bcd_add3 m2(d2,c2);
	bcd_add3 m3(d3,c3);
	bcd_add3 m4(d4,c4);
	bcd_add3 m5(d5,c5);
	bcd_add3 m6(d6,c6);
	bcd_add3 m7(d7,c7);
	assign ones_digit_po = {c5[2:0],num_pi[0]};
	assign tens_digit_po = {c7[2:0],c5[3]};
endmodule

/*
 * Module: bcd_add3
 * Description: binary_to_BCD submodule
 */
module bcd_add3(
	input [3:0] in,
   output reg [3:0] out);
	always @(*) begin
		case (in)
			4'b0000: out <= 4'b0000;
			4'b0001: out <= 4'b0001;
			4'b0010: out <= 4'b0010;
			4'b0011: out <= 4'b0011;
			4'b0100: out <= 4'b0100;
			4'b0101: out <= 4'b1000;
			4'b0110: out <= 4'b1001;
			4'b0111: out <= 4'b1010;
			4'b1000: out <= 4'b1011;
			4'b1001: out <= 4'b1100;
			default: out <= 4'b0000;
		endcase
	end
endmodule


/*
 * Module: button_debouncer
 *
 * Description: Sequential logic to prevent seeing a button press more than once when the button is pressed
 *
 */
module button_debouncer (
	input clk, 
	input pushbutton, 
	output pushbutton_down);

reg pushbutton_state;
reg pushbutton_sync_0;
reg pushbutton_sync_1;
reg [15:0] pushbutton_cnt;

initial begin
	pushbutton_state <= 1;
	pushbutton_sync_0 <= 1;
	pushbutton_sync_1 <= 1;
	pushbutton_cnt <= 0;
end


// First use two flipflops to synchronize the pushbutton signal the "clk" clock domain
always @(posedge clk)
    pushbutton_sync_0 <= ~pushbutton; 
always @(posedge clk)
    pushbutton_sync_1 <= pushbutton_sync_0;

wire pushbutton_idle = (pushbutton_state == pushbutton_sync_1);
wire pushbutton_cnt_max = &pushbutton_cnt;  

always @(posedge clk)
if(pushbutton_idle)
    pushbutton_cnt <= 0;  // nothing's going on
else
begin
    pushbutton_cnt <= pushbutton_cnt + 1;  // something's going on, increment the counter
    if(pushbutton_cnt_max)
        pushbutton_state <= ~pushbutton_state;  // if thecounter is maxed out, pushbutton changed!
end

assign pushbutton_down = ~pushbutton_state & ~pushbutton_idle & pushbutton_cnt_max;  // true for one clock cycle when we detect that pushbutton went down

endmodule 
