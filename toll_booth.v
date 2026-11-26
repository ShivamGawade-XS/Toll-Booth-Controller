`timescale 1ns/1ps

module toll_booth (
    input clk,
    input reset,            // 1 = reset everything
    input car_detect,       // 1 = car at gate
    input paid,             // 1 = toll paid
    output reg gate_open,
    output reg red_led,
    output reg green_led,
    output reg [7:0] car_count
);

    // State encoding
    parameter IDLE      = 2'b00;
    parameter WAIT_PAY  = 2'b01;
    parameter GATE_OPEN = 2'b10;

    reg [1:0] state, next_state;

    // Block 1: State register (sequential)
    always @(posedge clk or posedge reset) begin
        if (reset)
            state <= IDLE;
        else
            state <= next_state;
    end

    // Block 2: Next-state logic (combinational)
    always @(*) begin
        case (state)
            IDLE: begin
                if (car_detect) next_state = WAIT_PAY;
                else            next_state = IDLE;
            end
            WAIT_PAY: begin
                if (!car_detect)  next_state = IDLE;      // car left, no payment
                else if (paid)    next_state = GATE_OPEN; // paid
                else              next_state = WAIT_PAY;
            end
            GATE_OPEN: begin
                if (!car_detect)  next_state = IDLE;      // car has passed
                else              next_state = GATE_OPEN;
            end
            default: next_state = IDLE;
        endcase
    end

    // Block 3: Output logic (Moore FSM)
    always @(*) begin
        gate_open = 0;
        red_led   = 0;
        green_led = 0;
        case (state)
            IDLE:      red_led = 1;
            WAIT_PAY:  red_led = 1;
            GATE_OPEN: begin
                gate_open = 1;
                green_led = 1;
            end
            default:   red_led = 1;
        endcase
    end

    // Block 4: Paid vehicle counter
    always @(posedge clk or posedge reset) begin
        if (reset)
            car_count <= 8'd0;
        else if (state == GATE_OPEN && !car_detect)
            car_count <= car_count + 1;
    end

endmodule
