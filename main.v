module Histogram_image #(
    parameter integer W = 750,
    parameter integer H = 750
)(
    input              clk,
    input              rst,
    input              in_valid,
    input      [7:0]   data_in,
    output reg [7:0]   data_out,
    output reg         out_rdy
);

    reg  [9:0] x;
    reg  [9:0] y;

    wire inner_valid;
    assign inner_valid = (x >= 10'd1) && (x < (W-1)) &&
                         (y >= 10'd1) && (y < (H-1));

    reg  [9:0] addr;
    reg  [0:0] we1, we2;
    reg  [7:0] din1, din2;
    wire [7:0] q1, q2;

    RAM1 MyRam1 (
        .clka  (clk),
        .wea   (we1),
        .addra (addr),
        .dina  (din1),
        .douta (q1)
    );

    RAM1 MyRam2 (
        .clka  (clk),
        .wea   (we2),
        .addra (addr),
        .dina  (din2),
        .douta (q2)
    );

    reg ping;

    wire [7:0] px_y1 = (ping == 1'b0) ? q2 : q1;
    wire [7:0] px_y2 = (ping == 1'b0) ? q1 : q2;

    reg [7:0] w00, w01, w02;
    reg [7:0] w10, w11, w12;
    reg [7:0] w20, w21, w22;

    localparam [2:0]
        S_IDLE   = 3'd0,
        S_READ   = 3'd1,
        S_SHIFT  = 3'd2,
        S_CALC   = 3'd3,
        S_PAUSE  = 3'd4,
        S_PAUSE2 = 3'd5,
        S_WRITE  = 3'd6,
        S_ADV    = 3'd7;

    reg [2:0] state, next_state;

    reg [9:0] right_sum, left_sum;
    reg [9:0] avg;

    always @(*) begin
        next_state = state;
        case (state)
            S_IDLE:   if (in_valid) next_state = S_READ;
            S_READ:   next_state = S_SHIFT;
            S_SHIFT:  next_state = S_CALC;
            S_CALC:   next_state = S_PAUSE;
            S_PAUSE:  next_state = S_PAUSE2;
            S_PAUSE2: next_state = S_WRITE;
            S_WRITE:  next_state = S_ADV;
            S_ADV:    next_state = S_IDLE;
            default:  next_state = S_IDLE;
        endcase
    end

    always @(posedge clk) begin
        if (rst) begin
            state   <= S_IDLE;
            x       <= 10'd0;
            y       <= 10'd0;
            ping    <= 1'b0;
            addr    <= 10'd0;

            we1     <= 1'b0;
            we2     <= 1'b0;
            din1    <= 8'd0;
            din2    <= 8'd0;

            out_rdy <= 1'b0;
            data_out <= 8'd0;

            {w00,w01,w02,w10,w11,w12,w20,w21,w22} <= {9{8'd0}};

            right_sum <= 10'd0;
            left_sum  <= 10'd0;
            avg       <= 10'd0;

        end else begin
            state <= next_state;

            we1     <= 1'b0;
            we2     <= 1'b0;
            out_rdy <= 1'b0;

            case (state)

                S_IDLE: begin
                    if (in_valid) begin
                        addr <= x;
                    end
                end

                S_READ: begin
                end

                S_SHIFT: begin
                    w00 <= w01;
                    w01 <= w02;
                    w02 <= px_y2;

                    w10 <= w11;
                    w11 <= w12;
                    w12 <= px_y1;

                    w20 <= w21;
                    w21 <= w22;
                    w22 <= data_in;
                end

                S_CALC: begin
                    right_sum <= w02 + w12 + w22;
                    left_sum  <= w00 + w10 + w20;
                end

                S_PAUSE: begin
                    if (right_sum > left_sum)
                        avg <= (right_sum - left_sum) / 2'b11;
                    else
                        avg <= (left_sum - right_sum) / 2'b11;
                end

                S_PAUSE2: begin
                    out_rdy  <= 1'b1;
                    data_out <= avg[7:0];
                end

                S_WRITE: begin
                    if (ping == 1'b0) begin
                        we1  <= 1'b1;
                        din1 <= data_in;
                    end else begin
                        we2  <= 1'b1;
                        din2 <= data_in;
                    end
                end

                S_ADV: begin
                    if (x == W-1) begin
                        x <= 10'd0;
                        if (y == H-1) begin
                            y    <= 10'd0;
                            ping <= 1'b0;
                        end else begin
                            y    <= y + 10'd1;
                            ping <= ~ping;
                        end
                    end else begin
                        x <= x + 10'd1;
                    end
                end

            endcase
        end
    end

endmodule