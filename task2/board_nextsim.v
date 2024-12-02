module calc(
    input clk,
    input req_to_client,
    input [3:0] cur_block,      // tile inputs
    input [199:0] cur_board,    
    output resp_from_client,
    output [3:0] opt_col,       // leftmost anchor index for N*N (N = 2, 3, 4)-sized block
    output [1:0] opt_rotation   // 0~3 Rotation modes
);
    parameter CALC_OPTIM_POS = 1'd1;
    reg calculating = 0;
    
    parameter BLOCKS_IN_ROW = 20;
    parameter BLOCKS_IN_COL = 10;
    reg [199:0] board;
    integer board_idx;

    reg [31:0] score;

    reg [3:0] resp_col;
    reg [1:0] resp_rotation;

    reg [3:0] i;

    reg resp_ready;

    always @(posedge clk) begin 
        if(req_to_client == 1) begin
            board <= cur_board;
            calculating <= 1;

        end else if(calculating == 1) begin
            $display("CALC) RECIEVED BOARD STATUS");
            for(board_idx = 0; board_idx < 20; board_idx = board_idx + 1) begin
                $display("%10b", board[BLOCKS_IN_COL*board_idx +: BLOCKS_IN_COL]);
            end

            if(cur_block == 0) begin
                resp_col <= board[13:10];
            end else begin
                resp_col <= board[9:6];
            end

            resp_rotation <= board[8:7];
            resp_ready <= 1;
            calculating <= 0;

        end else begin
            resp_ready <= 0;
        end
    end
    
    assign opt_col = resp_col;
    assign opt_rotation = resp_rotation;
    assign resp_from_client = resp_ready;

    board_analysis bevaluate(board,                    
                            score);           // hole_count

endmodule


