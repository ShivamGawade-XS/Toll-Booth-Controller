`timescale 1ns/1ps
module toll_booth_tb;

    reg clk, reset, car_detect, paid;
    wire gate_open, red_led, green_led;
    wire [7:0] car_count;

    // Unit Under Test (UUT)
    toll_booth uut (
        .clk(clk), .reset(reset),
        .car_detect(car_detect), .paid(paid),
        .gate_open(gate_open), .red_led(red_led),
        .green_led(green_led), .car_count(car_count)
    );

    // 10 ns clock period (5 ns half-period)
    always #5 clk = ~clk;

    initial begin
        clk = 0; reset = 1; car_detect = 0; paid = 0;
        #20 reset = 0;

        // Test 1: car arrives, pays, passes
        #10 car_detect = 1;
        #20 paid = 1;
        #10 paid = 0;
        #20 car_detect = 0;

        // Test 2: car arrives, leaves WITHOUT paying
        #20 car_detect = 1;
        #30 car_detect = 0;

        // Test 3: another car pays and passes
        #20 car_detect = 1;
        #20 paid = 1;
        #10 paid = 0;
        #20 car_detect = 0;

        #30 $finish;
    end

    // Monitor signals in ModelSim transcript
    initial begin
        $monitor("t=%0t car=%b paid=%b | gate=%b red=%b green=%b | count=%d",
                 $time, car_detect, paid, gate_open, red_led, green_led, car_count);
    end

endmodule
