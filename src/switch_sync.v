module switch_sync (
    input clk,
    input clr,
    input [3:0] sw_in,
    output reg [3:0] sw_out
);
    reg [3:0] sw_mid;
    always @(posedge clk or posedge clr) begin
        if (clr) begin
            sw_mid <= 4'b0000;
            sw_out <= 4'b0000;
        end else begin
            sw_mid <= sw_in;
            sw_out <= sw_mid;
        end
    end
endmodule
