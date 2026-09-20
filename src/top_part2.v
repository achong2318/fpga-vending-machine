`timescale 1ns / 1ps
module top_part2 (
    input        clk,      // 100 MHz
    input        clr,      // reset 
    input        dime,
    input        nickel,
    input        quarter,
    input  [3:0] sw,
    // Seven segment display 
    output [3:0] an,
    output [6:0] ca,
    // Product delivered LEDs + error LED 
    output [3:0] ld,
    output       err,
    // New: 1 Hz clock indicator on LED15
    output       led15,
    // OLED Pmod JA/JB signals (physical pins)
    output CS,
    output SDIN,
    output SCLK,
    output DC,
    output RES,
    output VBAT,
    output VDD
);
    ////////////////////////////////////////////////////////////////////////////
    // 1 Hz CLOCK (for LED15 and OLED update timing)
    ////////////////////////////////////////////////////////////////////////////
    reg [26:0] clk_div_cnt = 27'd0;
    reg        clk_1hz     = 1'b0;
    always @(posedge clk or posedge clr) begin
        if (clr) begin
            clk_div_cnt <= 27'd0;
            clk_1hz     <= 1'b0;
        end else begin
            // 100 MHz / (2 * 50_000_000) = 1 Hz square wave
            if (clk_div_cnt == 27'd49_999_999) begin
                clk_div_cnt <= 27'd0;
                clk_1hz     <= ~clk_1hz;
            end else begin
                clk_div_cnt <= clk_div_cnt + 1'b1;
            end
        end
    end
    // Drive LED15 with the 1 Hz clock
    assign led15 = clk_1hz;
    // 1 Hz tick (rising edge of clk_1hz) used for OLED EN handshake timing
    reg  clk_1hz_d = 1'b0;
    always @(posedge clk or posedge clr) begin
        if (clr)
            clk_1hz_d <= 1'b0;
        else
            clk_1hz_d <= clk_1hz;
    end
    wire tick_1hz = (~clk_1hz_d) & clk_1hz;
    ////////////////////////////////////////////////////////////////////////////
    // DEBOUNCED COIN INPUTS 
    ////////////////////////////////////////////////////////////////////////////
    wire dime_pulse;
    wire nickel_pulse;
    wire quarter_pulse;
    debounce db_d (
        .clk       (clk),
        .clr       (clr),
        .btn_in    (dime),
        .btn_pulse (dime_pulse)
    );
    debounce db_n (
        .clk       (clk),
        .clr       (clr),
        .btn_in    (nickel),
        .btn_pulse (nickel_pulse)
    );
    debounce db_q (
        .clk       (clk),
        .clr       (clr),
        .btn_in    (quarter),
        .btn_pulse (quarter_pulse)
    );
    ////////////////////////////////////////////////////////////////////////////
    // SYNCHRONIZED SWITCHES (same as Part 1)
    ////////////////////////////////////////////////////////////////////////////
    wire [3:0] sw_sync;
    switch_sync ss (
        .clk   (clk),
        .clr   (clr),
        .sw_in (sw),
        .sw_out(sw_sync)
    );
    ////////////////////////////////////////////////////////////////////////////
    // VENDING MACHINE FSM 
    ////////////////////////////////////////////////////////////////////////////
    wire [6:0] amount; // current balance in cents (0–95)
    wire [6:0] cost;   // selected cost in cents (0–95)
    vending_machine vm (
        .clk           (clk),          // keep 100 MHz like Part 1
        .clr           (clr),
        .nickel_pulse  (nickel_pulse),
        .dime_pulse    (dime_pulse),
        .quarter_pulse (quarter_pulse),
        .sw            (sw_sync),
        .ld            (ld),
        .err           (err),
        .amount        (amount),
        .cost          (cost)
    );
    ////////////////////////////////////////////////////////////////////////////
    // SEVEN-SEGMENT DISPLAY (same as working Part 1)
    // LEFT two digits: COST
    // RIGHT two digits: AMOUNT
    ////////////////////////////////////////////////////////////////////////////
    wire [3:0] dig1 = amount % 10;   // rightmost digit
    wire [3:0] dig2 = amount / 10;   // tens of amount
    wire [3:0] dig3 = cost   % 10;   // ones of cost
    wire [3:0] dig4 = cost   / 10;   // leftmost digit
    seven_seg disp (
        .clk  (clk),
        .clr  (clr),
        .dig1 (dig1),
        .dig2 (dig2),
        .dig3 (dig3),
        .dig4 (dig4),
        .an   (an),
        .ca   (ca)
    );
    ////////////////////////////////////////////////////////////////////////////
    // OLED PAGE CONTENT – ASCII in HEX 
    ////////////////////////////////////////////////////////////////////////////
    // Amount / cost -> two ASCII digits each
    wire [6:0] amount_tens_val = amount / 10;
    wire [6:0] amount_ones_val = amount % 10;
    wire [6:0] cost_tens_val   = cost   / 10;
    wire [6:0] cost_ones_val   = cost   % 10;
    // Show space for leading zero in tens place
    wire [7:0] amount_tens_char =
        (amount_tens_val == 0) ? 8'h20 : (8'h30 + amount_tens_val[3:0]);
    wire [7:0] amount_ones_char = 8'h30 + amount_ones_val[3:0];
    wire [7:0] cost_tens_char =
        (cost_tens_val == 0) ? 8'h20 : (8'h30 + cost_tens_val[3:0]);
    wire [7:0] cost_ones_char  = 8'h30 + cost_ones_val[3:0];
    // Switches as ASCII '0' or '1'
    wire [7:0] sw3_char = sw_sync[3] ? 8'h31 : 8'h30; // '1' or '0'
    wire [7:0] sw2_char = sw_sync[2] ? 8'h31 : 8'h30;
    wire [7:0] sw1_char = sw_sync[1] ? 8'h31 : 8'h30;
    wire [7:0] sw0_char = sw_sync[0] ? 8'h31 : 8'h30;
    // Page0: Your name (line 0) – "ANDREW CHONG"
    wire [127:0] page0 = {
        8'h41, 8'h4E, 8'h44, 8'h52, 8'h45, 8'h57, 8'h20, // "ANDREW "
        8'h43, 8'h48, 8'h4F, 8'h4E, 8'h47,               // "CHONG"
        8'h20, 8'h20, 8'h20, 8'h20                      // padding
    };
    // Page1: Amount and Cost – "A:xy C:uv"
    wire [127:0] page1 = {
        8'h41, 8'h3A, 8'h20,              // "A: "
        amount_tens_char,
        amount_ones_char,
        8'h20,                           // space
        8'h43, 8'h3A, 8'h20,             // "C: "
        cost_tens_char,
        cost_ones_char,
        8'h20, 8'h20, 8'h20, 8'h20, 8'h20 // padding
    };
    // Page2: Selected switches – "SW: b3b2b1b0 PRODS"
    wire [127:0] page2 = {
        8'h53, 8'h57, 8'h3A, 8'h20,      // "SW: "
        sw3_char,
        sw2_char,
        sw1_char,
        sw0_char,
        8'h20,                           // space
        8'h50, 8'h52, 8'h4F, 8'h44, 8'h53, // "PRODS"
        8'h20, 8'h20                     // padding
    };
    // Page3: READY vs ERROR
    wire [127:0] page3_ok = {
        8'h52, 8'h45, 8'h41, 8'h44, 8'h59, // "READY"
        8'h20, 8'h20, 8'h20, 8'h20, 8'h20,
        8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20
    };
    wire [127:0] page3_err = {
        8'h45, 8'h52, 8'h52, 8'h4F, 8'h52, // "ERROR"
        8'h20, 8'h3E, 8'h39, 8'h35,        // " >95"
        8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20
    };
    wire [127:0] page3 = (err ? page3_err : page3_ok);
    ////////////////////////////////////////////////////////////////////////////
    // PmodOLEDCtrl – OLED driver (from demo)
    ////////////////////////////////////////////////////////////////////////////
    reg        oled_en   = 1'b0;
    wire       oled_fin;
    PmodOLEDCtrl oled_ctrl (
        .CLK   (clk),     // 100 MHz board clock
        .RST   (clr),     // reuse same reset
        .EN    (oled_en),
        .Page0 (page0),
        .Page1 (page1),
        .Page2 (page2),
        .Page3 (page3),
        .CS    (CS),
        .SDIN  (SDIN),
        .SCLK  (SCLK),
        .DC    (DC),
        .RES   (RES),
        .VBAT  (VBAT),
        .VDD   (VDD),
        .FIN   (oled_fin)
    );
    ////////////////////////////////////////////////////////////////////////////
    // EN / FIN HANDSHAKE: update OLED once per second
    ////////////////////////////////////////////////////////////////////////////
    reg [1:0] oled_state = 2'd0;
    always @(posedge clk or posedge clr) begin
        if (clr) begin
            oled_state <= 2'd0;
            oled_en    <= 1'b0;
        end else begin
            case (oled_state)
                2'd0: begin
                    // Wait for 1 Hz tick to request a refresh
                    if (tick_1hz) begin
                        oled_en    <= 1'b1; // start update
                        oled_state <= 2'd1;
                    end
                end
                2'd1: begin
                    // Wait until OLED controller finishes and asserts FIN
                    if (oled_fin) begin
                        oled_en    <= 1'b0; // tell it we're done
                        oled_state <= 2'd2;
                    end
                end
                2'd2: begin
                    // Wait for FIN to go low again before next update
                    if (!oled_fin) begin
                        oled_state <= 2'd0;
                    end
                end
                default: begin
                    oled_state <= 2'd0;
                    oled_en    <= 1'b0;
                end
            endcase
        end
    end
endmodule
