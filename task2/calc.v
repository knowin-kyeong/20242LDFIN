`include "board_analysis.v"
`include "board_nextsim.v"

module calc(
    input clk,
    input req_to_client,
    input [3:0] cur_block,      // tile inputs
    input [199:0] cur_board,    
    output resp_from_client,
    output [3:0] opt_col,       // leftmost anchor index for N*N (N = 2, 3, 4)-sized block
    output [1:0] opt_rotation   // 0~3 Rotation modes
);
    parameter RECIEVED_BOARD = 3'd0;
    parameter CALC_NEXT_BOARD = 3'd1;
    parameter REFLECT_NEXT_BOARD = 3'd2;
    parameter CALC_NEXT_EVALUATION = 3'd3;
    parameter REFLECT_NEXT_EVALUATION = 3'd4;
    parameter RECP_TO_MAIN = 3'd5;

    reg [2:0] state = RECIEVED_BOARD; 
    
    parameter BLOCKS_IN_ROW = 20;
    parameter BLOCKS_IN_COL = 10;
    
    parameter int_max = 32'd20_0000_0000;

    reg [4:0] row_idx;

    reg [3:0] cur_col;
    reg [1:0] cur_rotation;

    wire sim_ready;
    reg sim_request;

    reg req_score;
    wire recv_score;

    reg [199:0] board;
    reg [199:0] next_board;
    wire [199:0] temp_board;
    
    /* DEBUG */
    // reg [199:0] capture_board;

    reg valid;
    wire temp_valid;

    reg [31:0] cur_score, next_score;
    wire [31:0] temp_score;

    reg [3:0] resp_col;
    reg [1:0] resp_rotation;

    reg [3:0] i;

    reg resp_ready;

    always @(posedge clk) begin 
        if(req_to_client == 1 && state == RECIEVED_BOARD) begin
            board <= cur_board;

            cur_col <= 0;
            cur_rotation <= 0;
            cur_score <= int_max;

            resp_ready <= 0;
            state <= CALC_NEXT_BOARD;

        end else if(state == CALC_NEXT_BOARD) begin

            sim_request <= 1;
            state <= REFLECT_NEXT_BOARD;

        end else if(state == REFLECT_NEXT_BOARD && sim_ready == 1) begin
            sim_request <= 0;
            next_board <= temp_board;
            
            valid <= temp_valid;

            state <= CALC_NEXT_EVALUATION;
        
        end else if(state == CALC_NEXT_EVALUATION) begin
            req_score <= 1;

            state <= REFLECT_NEXT_EVALUATION;

        end else if(state == REFLECT_NEXT_EVALUATION && recv_score == 1) begin
            
            /*
            if(valid == 1) begin
                for(row_idx = 0; row_idx < BLOCKS_IN_ROW; row_idx = row_idx + 1) begin
                    $display("CUR %dth col) %10b", row_idx, next_board[BLOCKS_IN_COL*row_idx +: BLOCKS_IN_COL]);
                end
                $display("PREV score %d, CUR score %d <- col %d, rot %d\n", cur_score, temp_score, cur_col, cur_rotation);
            end
            */

            req_score <= 0;

            if((temp_score < cur_score) && valid == 1) begin
                resp_col <= cur_col;
                resp_rotation <= cur_rotation;
                cur_score <= temp_score;
                // capture_board <= next_board;
            end

            if(cur_col == 4'd9 && cur_rotation == 2'd3) begin
                resp_ready <= 1;
                state <= RECP_TO_MAIN;
            
            end else if(cur_rotation == 2'd3) begin
                cur_col <= cur_col + 1;
                cur_rotation <= 0;
                state <= CALC_NEXT_BOARD;

            end else begin
                cur_rotation <= cur_rotation + 1;
                state <= CALC_NEXT_BOARD;
            end

        end else if(state == RECP_TO_MAIN) begin
            /* DEBUG */ 
            /*
            for(row_idx = 0; row_idx < BLOCKS_IN_ROW; row_idx = row_idx + 1) begin
                $display("CLAIM %dth row) %10b", row_idx, capture_board[BLOCKS_IN_COL*row_idx +: BLOCKS_IN_COL]);
            end
            $display("CLAIM RAW col = %d, rot = %d", resp_col, resp_rotation);
            capture_board <= 0;
            */

            resp_ready <= 0;
            state <= RECIEVED_BOARD;

        end else begin
            resp_ready <= 0;
            sim_request <= 0;
            req_score <= 0;
        end
    end
    
    assign opt_col = resp_col;
    assign opt_rotation = resp_rotation;
    assign resp_from_client = resp_ready;
    
    board_nextsim predict(clk, cur_block, cur_col, cur_rotation, board, sim_request,
                    temp_valid, temp_board, sim_ready);

    board_analysis bevaluate(clk, req_score, next_board,                    
                             recv_score, temp_score);

endmodule


