module vending_machine (
    input clk,
    input clr,
    input nickel_pulse,
    input dime_pulse,
    input quarter_pulse,
    input [3:0] sw,
    output reg [3:0] ld,
    output reg err,
    output reg [6:0] amount,   // 0-95, capped
    output reg [6:0] cost      // shown on display (0-99 range is enough)
);
    // Product prices (now 8-bit to avoid overflow)
    localparam [7:0] P0  = 8'd25;
    localparam [7:0] P1  = 8'd50;
    localparam [7:0] P2  = 8'd65;
    localparam [7:0] P3  = 8'd80;
    localparam [7:0] MAX = 8'd95;   // max valid cost / balance
    reg [3:0] sw_prev;
    reg vend_inhibit;
    reg [7:0] temp_amt;
    reg [7:0] cost_full;   // INTERNAL FULL-WIDTH COST (0-220)
    always @(posedge clk or posedge clr) begin
        if (clr) begin
            amount       <= 7'd0;
            cost         <= 7'd0;
            cost_full    <= 8'd0;
            ld           <= 4'b0000;
            err          <= 1'b0;
            sw_prev      <= 4'b0000;
            vend_inhibit <= 1'b0;
        end else begin
            // -------------------------------------------------
            // Recompute cost from switches using FULL 8-bit sum
            // -------------------------------------------------
            cost_full = 8'd0;
            if (sw[0]) cost_full = cost_full + P0;
            if (sw[1]) cost_full = cost_full + P1;
            if (sw[2]) cost_full = cost_full + P2;
            if (sw[3]) cost_full = cost_full + P3;
            // Drive 7-bit cost output for display (truncate)
            cost <= cost_full[6:0];
            // Error if TRUE cost exceeds MAX (95)
            err <= (cost_full > MAX);
            // -------------------------------------------------
            // Handle coins (amount is capped at 95)
            // -------------------------------------------------
            if (nickel_pulse) begin
                temp_amt = amount + 5;
                if (temp_amt > MAX)
                    amount <= MAX[6:0];
                else
                    amount <= temp_amt[6:0];
                vend_inhibit <= 1'b0;
            end
            if (dime_pulse) begin
                temp_amt = amount + 10;
                if (temp_amt > MAX)
                    amount <= MAX[6:0];
                else
                    amount <= temp_amt[6:0];
                vend_inhibit <= 1'b0;
            end
            if (quarter_pulse) begin
                temp_amt = amount + 25;
                if (temp_amt > MAX)
                    amount <= MAX[6:0];
                else
                    amount <= temp_amt[6:0];
                vend_inhibit <= 1'b0;
            end
            // -------------------------------------------------
            // Clear LEDs for deselected products
            // -------------------------------------------------
            ld <= ld & sw;
            // If selection changed, allow vending again
            if (sw != sw_prev)
                vend_inhibit <= 1'b0;
            // -------------------------------------------------
            // Vend when there is enough balance and no error
            // -------------------------------------------------
            if (!err && (cost_full > 0) && (amount >= cost_full[6:0]) && !vend_inhibit) begin
                amount       <= amount - cost_full[6:0];
                ld           <= ld | sw;
                vend_inhibit <= 1'b1;
            end
            // Remember switches for next cycle
            sw_prev <= sw;
        end
    end
endmodule
