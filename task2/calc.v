module calc(
    input clk,
    input req_to_client,
    input [3:0] cur_block,      // tile inputs

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