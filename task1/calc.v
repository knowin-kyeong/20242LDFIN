module calc(
    input clk,
    input req_to_client,
    input [3:0] cur_block,      // tile inputs
    input [9:0] row1_info,      // 10-wide row's info (RIGHTMOST(9) ... LEFTMOST(0))
    input [9:0] row2_info,      // 10-wide row's info (RIGHTMOST(9) ... LEFTMOST(0))

    output resp_from_client,
    output [3:0] opt_col,       // leftmost anchor index for N*N (N = 2, 3, 4)-sized block
    output [1:0] opt_rotation   // 0~3 Rotation modes
);
    parameter NO_PROPER_POS = 4'd11;
    reg [3:0] proper_2col, proper_4col;

    reg [3:0] resp_col;
    reg [1:0] resp_rotation;

    reg [3:0] i;

    reg resp_ready;

    always @(posedge clk) begin 
        if(req_to_client == 1) begin
            proper_2col = NO_PROPER_POS;
            proper_4col = NO_PROPER_POS;

            for(i = 1; i <= 9; i = i + 1) begin
                if(row1_info[i] == 0 && row1_info[i-1] == 0 && 
                   row2_info[i] == 0 && row2_info[i-1] == 0) begin
                    // O mino can go to [i, i-1] RIGHTMOST = 0
                    // so the LEFTMOST INDEX = i
                    // We have to conver RIGHTMOST COORDINATE = 9 - i
                    proper_2col = 9-i;
                end
            end
            if(proper_2col == NO_PROPER_POS) begin
                for(i = 1; i <= 9; i = i + 1) begin
                    if(row1_info[i] == 0 && row1_info[i-1] == 0) begin
                        proper_2col = 9-i;
                    end
                end
            end 

            
            for(i = 3; i <= 9; i = i + 1) begin
                if(row1_info[i] == 0 && row1_info[i-1] == 0 && 
                row1_info[i-2] == 0 && row1_info[i-3] == 0 && 
                row2_info[i] == 0 && row2_info[i-1] == 0 &&
                row2_info[i-2] == 0 && row2_info[i-3] == 0) begin
                    // I mino can go to [i, ... , i - 3] RIGHTMOST = 0
                    // so the LEFTMOST INDEX = i
                    // We have to conver RIGHTMOST COORDINATE = 9 - i
                    proper_4col = 9-i;
                end
            end
            if(proper_4col == NO_PROPER_POS) begin
                for(i = 3; i <= 9; i = i + 1) begin
                    if(row1_info[i] == 0 && row1_info[i-1] == 0 && 
                    row1_info[i-2] == 0 && row1_info[i-3] == 0) begin
                        proper_4col = 9-i;
                    end
                end
            end
            
            if(cur_block == 0) begin
                resp_col <= (proper_4col == NO_PROPER_POS) ? 0 : proper_4col;
            end else begin
                resp_col <= (proper_2col == NO_PROPER_POS) ? 0 : proper_2col;
            end
            resp_rotation <= 2'd0;
            resp_ready <= 1;

        end else begin
            resp_ready <= 0;
        end
    end

    assign opt_col = resp_col;
    assign opt_rotation = resp_rotation;
    assign resp_from_client = resp_ready;

endmodule