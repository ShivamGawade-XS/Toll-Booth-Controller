`timescale 1ns/1ps

module toll_booth_tb;

    reg clk, reset, car_detect, paid;
    wire gate_open, red_led, green_led;
    wire [7:0] car_count;
    integer i;

    toll_booth uut (
        .clk(clk), .reset(reset),
        .car_detect(car_detect), .paid(paid),
        .gate_open(gate_open), .red_led(red_led),
        .green_led(green_led), .car_count(car_count)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        reset = 0;
        car_detect = 0;
        paid = 0;

        // Assert reset between clock edges to verify asynchronous behavior.
        #2 reset = 1;
        #1;
        if (car_count !== 8'd0 ||
            gate_open !== 1'b0 || red_led !== 1'b1 || green_led !== 1'b0) begin
            $display("FAIL: asynchronous reset did not clear the counter or select IDLE outputs");
            $finish(1);
        end
        $display("ASYNCHRONOUS RESET CHECK PASSED");
        #1 reset = 0;

        // Test 1: a paid vehicle opens the gate and is counted once on exit.
        @(negedge clk);
        car_detect = 1;
        @(posedge clk);
        #1;
        if (gate_open !== 1'b0 || red_led !== 1'b1 || green_led !== 1'b0) begin
            $display("FAIL: Test 1 - gate/LED outputs incorrect while waiting for payment");
            $finish(1);
        end

        @(posedge clk);
        #1;
        if (gate_open !== 1'b0 || red_led !== 1'b1 || green_led !== 1'b0) begin
            $display("FAIL: Test 1 - gate opened before payment");
            $finish(1);
        end

        @(negedge clk);
        paid = 1;
        @(posedge clk);
        #1;
        if (gate_open !== 1'b1 || red_led !== 1'b0 || green_led !== 1'b1) begin
            $display("FAIL: Test 1 - paid vehicle did not open the gate with correct LEDs");
            $finish(1);
        end
        if (car_count !== 8'd0) begin
            $display("FAIL: Test 1 - vehicle counted before passing the open gate");
            $finish(1);
        end

        @(negedge clk);
        paid = 0;
        @(negedge clk);
        car_detect = 0;
        @(posedge clk);
        #1;
        if (gate_open !== 1'b0 || red_led !== 1'b1 || green_led !== 1'b0) begin
            $display("FAIL: Test 1 - gate/LED outputs incorrect after vehicle left");
            $finish(1);
        end
        if (car_count !== 8'd1) begin
            $display("FAIL: Test 1 - expected car_count=1, got %0d", car_count);
            $finish(1);
        end
        @(posedge clk);
        #1;
        if (car_count !== 8'd1) begin
            $display("FAIL: Test 1 - vehicle was counted more than once");
            $finish(1);
        end
        $display("TEST 1 PASSED");

        // Test 2: an unpaid vehicle must not open the gate or increment the count.
        @(negedge clk);
        car_detect = 1;
        @(posedge clk);
        #1;
        if (gate_open !== 1'b0 || red_led !== 1'b1 || green_led !== 1'b0) begin
            $display("FAIL: Test 2 - outputs incorrect while waiting for payment");
            $finish(1);
        end

        for (i = 0; i < 3; i = i + 1) begin
            @(posedge clk);
            #1;
            if (gate_open !== 1'b0 || red_led !== 1'b1 || green_led !== 1'b0) begin
                $display("FAIL: Test 2 - gate opened for an unpaid vehicle");
                $finish(1);
            end
        end

        @(negedge clk);
        car_detect = 0;
        @(posedge clk);
        #1;
        if (gate_open !== 1'b0 || red_led !== 1'b1 || green_led !== 1'b0) begin
            $display("FAIL: Test 2 - gate/LED outputs incorrect after unpaid vehicle left");
            $finish(1);
        end
        if (car_count !== 8'd1) begin
            $display("FAIL: Test 2 - unpaid vehicle changed car_count; expected 1, got %0d", car_count);
            $finish(1);
        end
        $display("TEST 2 PASSED");

        // Test 3: a second paid vehicle opens the gate and increments the count.
        @(negedge clk);
        car_detect = 1;
        @(posedge clk);
        #1;
        if (gate_open !== 1'b0 || red_led !== 1'b1 || green_led !== 1'b0) begin
            $display("FAIL: Test 3 - outputs incorrect while waiting for payment");
            $finish(1);
        end

        @(negedge clk);
        paid = 1;
        @(posedge clk);
        #1;
        if (gate_open !== 1'b1 || red_led !== 1'b0 || green_led !== 1'b1) begin
            $display("FAIL: Test 3 - paid vehicle did not open the gate with correct LEDs");
            $finish(1);
        end
        if (car_count !== 8'd1) begin
            $display("FAIL: Test 3 - vehicle counted before passing the open gate");
            $finish(1);
        end

        @(negedge clk);
        paid = 0;
        @(negedge clk);
        car_detect = 0;
        @(posedge clk);
        #1;
        if (gate_open !== 1'b0 || red_led !== 1'b1 || green_led !== 1'b0) begin
            $display("FAIL: Test 3 - gate/LED outputs incorrect after vehicle left");
            $finish(1);
        end
        if (car_count !== 8'd2) begin
            $display("FAIL: Test 3 - expected car_count=2, got %0d", car_count);
            $finish(1);
        end
        @(posedge clk);
        #1;
        if (car_count !== 8'd2) begin
            $display("FAIL: Test 3 - vehicle was counted more than once");
            $finish(1);
        end
        if (gate_open !== 1'b0 || red_led !== 1'b1 || green_led !== 1'b0) begin
            $display("FAIL: final gate/LED outputs incorrect");
            $finish(1);
        end
        $display("TEST 3 PASSED");
        $display("ALL TESTS PASSED: car_count=2, gate_open=0, red_led=1, green_led=0");
        $finish;
    end

endmodule
