`timescale 1ns / 1ps
module vending_machine_tb;
    // Inputs
    reg clk;
    reg clr;
    reg nickel_pulse;
    reg dime_pulse;
    reg quarter_pulse;
    reg [3:0] sw;
    // Outputs
    wire [3:0] ld;
    wire err;
    wire [6:0] amount;
    wire [6:0] cost;
    // Instantiate DUT
    vending_machine DUT (
        .clk(clk),
        .clr(clr),
        .nickel_pulse(nickel_pulse),
        .dime_pulse(dime_pulse),
        .quarter_pulse(quarter_pulse),
        .sw(sw),
        .ld(ld),
        .err(err),
        .amount(amount),
        .cost(cost)
    );
    // 100 MHz clock
    always #5 clk = ~clk;
    // Helper task to generate a clean coin pulse
    task pulse;
        output reg sig;
        begin
            sig = 1'b1;
            #20;
            sig = 1'b0;
        end
    endtask
    initial begin
        // -------------------------------
        // INITIALIZATION
        // -------------------------------
        clk = 0;
        clr = 1;
        nickel_pulse = 0;
        dime_pulse = 0;
        quarter_pulse = 0;
        sw = 4'b0000;
        #100;
        clr = 0;   // release reset
        // -------------------------------
        // TEST 1: Buy product 0 (25c)
        // -------------------------------
        #50;
        sw = 4'b0001;      // select product 0 (25c)
        #50; pulse(nickel_pulse);   // +5
        #50; pulse(dime_pulse);     // +10
        #50; pulse(dime_pulse);     // +10 → total = 25 → vend
        #200;
        sw = 4'b0000;      // deselect product
        // -------------------------------
        // TEST 2: Buy product 1 (50c)
        // -------------------------------
        #100;
        sw = 4'b0010;      // select product 1 (50c)
        #50; pulse(quarter_pulse); // +25
        #50; pulse(quarter_pulse); // +25 → vend
        #200;
        sw = 4'b0000;
        // -------------------------------
        // TEST 3: Error condition (>95c)
        // -------------------------------
        #100;
        sw = 4'b1111;      // cost = 25+50+65+80 = 220 → ERROR
        #200;
        sw = 4'b0000;
        // -------------------------------
        // END SIMULATION
        // -------------------------------
        #200;
        $stop;
    end
endmodule
