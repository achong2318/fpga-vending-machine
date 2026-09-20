// ============================================================
// seven_seg.v - Your lab's 4-digit display driver
// ============================================================
module clock_enable(
    input clr,
    input clk,
    output reg enable
);
    reg [16:0] count;
    always @(posedge clk or posedge clr) begin
        if (clr) begin
            count <= 1;
            enable <= 1;
        end
        else begin
            if (count == 100000) begin
                count <= 1;
                enable <= 1;
            end else begin
                count <= count + 1;
                enable <= 0;
            end
        end
    end
endmodule
module anode_driver(
    input clr,
    input enable,
    input clk,
    output wire [3:0] an,
    output reg  [1:0] s
);
    always @(posedge clk or posedge clr)
        if (clr)
            s <= 0;
        else if (enable)
            s <= s + 1;
    assign an = (s == 0) ? 4'b0111 :
                (s == 1) ? 4'b1011 :
                (s == 2) ? 4'b1101 :
                (s == 3) ? 4'b1110 :
                           4'b0000;
endmodule
module four_to_one_mux(
    input [3:0] dig1,
    input [3:0] dig2,
    input [3:0] dig3,
    input [3:0] dig4,
    input [1:0] s,
    output [3:0] x
);
    assign x = (s == 0) ? dig1 :
               (s == 1) ? dig2 :
               (s == 2) ? dig3 :
                          dig4;
endmodule
module hex_to_seven_segment_decoder(
    input [3:0] x,
    output reg [6:0] ca
);
    always @(*) begin
        case (x)
             0: ca = 7'b0000001;
             1: ca = 7'b1001111;
             2: ca = 7'b0010010;
             3: ca = 7'b0000110;
             4: ca = 7'b1001100;
             5: ca = 7'b0100100;
             6: ca = 7'b0100000;
             7: ca = 7'b0001111;
             8: ca = 7'b0000000;
             9: ca = 7'b0000100;
            10: ca = 7'b0001000;
            11: ca = 7'b1100000;
            12: ca = 7'b0110001;
            13: ca = 7'b1000010; // FIXED: no '2' allowed
            14: ca = 7'b0110000;
            15: ca = 7'b0111000;
        endcase
    end
endmodule
module seven_seg(
    input clk,
    input clr,
    input [3:0] dig1,
    input [3:0] dig2,
    input [3:0] dig3,
    input [3:0] dig4,
    output [3:0] an,
    output [6:0] ca
);
    wire enable;
    wire [1:0] s;
    wire [3:0] x;
    clock_enable ce(.clr(clr), .clk(clk), .enable(enable));
    anode_driver ad(.clr(clr), .enable(enable), .clk(clk), .an(an), .s(s));
    four_to_one_mux ftom(.s(s), .dig1(dig1), .dig2(dig2), .dig3(dig3), .dig4(dig4), .x(x));
    hex_to_seven_segment_decoder htssd(.x(x), .ca(ca));
endmodule
