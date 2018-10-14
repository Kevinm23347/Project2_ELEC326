    `timescale 1ns / 100ps
    //////////////////////////////////////////////////////////////////////////////////
    // Company: 
    // Engineer: 
    // 
    // Create Date: 10/17/2016 06:16:54 PM
    // Design Name: 
    // Module Name: sim1
    // Project Name: 
    // Target Devices: 
    // Tool Versions: 
    // Description: 
    // 
    // Dependencies: 
    // 
    // Revision:
    // Revision 0.01 - File Created
    // Additional Comments:
    // 
    //////////////////////////////////////////////////////////////////////////////////
    
    //module alarm_clock ( input CLK, input [7:0] SW, input [3:0] BTN, output [7:0] LED, output [6:0] SEG,
    //      	output DP, output [7:0] AN );
    
 module sim1();
    reg CLK;
    
    reg [7:0] SW;
    reg [3:0] BTN;
    wire [7:0] LED;
    wire [6:0] SEG;
    wire DP;
    wire [7:0] AN;
    
    //  Inistiantiate the alarm_clock
    alarm_clock test_alarm(.CLK (CLK), .SW (SW), .BTN (BTN), .LED (LED), .SEG (SEG), .DP (DP), .AN (AN));

    //this process block sets up the free running clock
    initial begin
        CLK = 0;
        forever #5 CLK = ~CLK;
    end

    initial begin// this process block specifies the stimulus.
        SW = 8'b00000000;
        BTN = 4'b0000;
     
        #2000
        SW = 8'b00000001;
        BTN = 4'b0001;
        
        #2000
        BTN = 4'b0000;

        #2000
        BTN = 4'b0010;
                
        #2000
        BTN = 4'b0000;
        #2000
        BTN = 4'b0001;
        #2000
        BTN = 4'b0000;
        #200
        BTN = 4'b0010;
        #2000
        BTN = 4'b0000;

        #2000
        BTN = 4'b0100;
        #2000
        BTN = 4'b0000;

        //#1000 $stop;
    end
    
    initial begin// this process block pipes the ASCII results to the
        //terminal or text editor
        //$timeformat(-9,1,"ns",12);
        //$display(" Time Clk Rst Ld SftRg Data Sel");
        //$monitor("%t %b %b %b %b %b %b", $realtime,
        //clock, reset, load, shiftreg, data, sel);
    end
    
endmodule
