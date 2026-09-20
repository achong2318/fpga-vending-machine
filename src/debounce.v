module debounce (
    input clk,
    input clr,
    input btn_in,
    output reg btn_pulse
);
    reg btn_sync0, btn_sync1;
    reg btn_state, btn_state_prev;
    reg [15:0] cnt;
    always @(posedge clk or posedge clr) begin
        if (clr) begin
            btn_sync0 <= 0;
            btn_sync1 <= 0;
            btn_state <= 0;
            btn_state_prev <= 0;
            btn_pulse <= 0;
            cnt <= 0;
        end else begin
            btn_sync0 <= btn_in;
            btn_sync1 <= btn_sync0;
            if (btn_sync1 != btn_state) begin
                cnt <= cnt + 1;
                if (cnt == 16'hFFFF) begin
                    btn_state <= btn_sync1;
                    cnt <= 0;
                end
            end else begin
                cnt <= 0;
            end
            btn_pulse <= btn_state & ~btn_state_prev;
            btn_state_prev <= btn_state;
        end
    end
endmodule
