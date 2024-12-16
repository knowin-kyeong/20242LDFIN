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
    
    parameter signed int_max = 64'd18_0000_0000;

    reg [4:0] row_idx;

    reg [3:0] cur_col;
    reg [1:0] cur_rotation;

    wire sim_ready;
    reg sim_request;

    reg req_score;
    wire recv_score;

    reg [199:0] board;
    wire [199:0] temp_board;
    reg [199:0] next_board;

    wire [9:0] temp_cleared_lines;
    reg [9:0] cleared_lines;
    
    /* DEBUG */
    reg [199:0] capture_board;
    reg [9:0] capture_cleared_lines;
    reg [9:0] capture_max_height;                    // max height
    reg [9:0] capture_cumulative_height;             // cumulative_height
    reg [9:0] capture_relative_height;               // max height - min height
    reg [9:0] capture_roughness;                     // sum of |diff. of two adjoint column)
    reg [9:0] capture_hole_count;                    // hole_count
    reg [9:0] capture_row_transition;                // row transition
    reg [9:0] capture_col_transition;                // col transition
    reg [9:0] capture_deepest_well;
    wire [9:0] max_height;                    // max height
    wire [9:0] cumulative_height;             // cumulative_height
    wire [9:0] relative_height;               // max height - min height
    wire [9:0] roughness;                     // sum of |diff. of two adjoint column)
    wire [9:0] hole_count;                    // hole_count
    wire [9:0] row_transition;                // row transition
    wire [9:0] col_transition;                // col transition
    wire [9:0] deepest_well;                  // deepest weel
    parameter signed MAX_HEIGHT_WEIGHT = 640262;
    parameter signed CUMULATIVE_HEIGHT_WEIGHT = 905723;
    parameter signed RELATIVE_HEIGHT_WEIGHT = -662923;
    parameter signed ROUGHNESS_WEIGHT = 303330;
    parameter signed HOLE_COUNT_WEIGHT = 986219;
    parameter signed CLEARED_LINES_WEIGHT = 822463;
    parameter signed ROW_TRANSITION_WEIGHT = 753124;
    parameter signed COL_TRANSITION_WEIGHT = 819983;
    parameter signed DEEPEST_WELL_WEIGHT = 219884;
    /* DEBUG END*/

    reg valid;
    wire temp_valid;

    reg signed [63:0] cur_score, next_score;
    wire signed [63:0] temp_score;

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
            cleared_lines <= 0;            

            sim_request <= 1;
            state <= REFLECT_NEXT_BOARD;

        end else if(state == REFLECT_NEXT_BOARD && sim_ready == 1) begin
            sim_request <= 0;
            next_board <= temp_board;
            cleared_lines <= temp_cleared_lines;
            valid <= temp_valid;

            state <= CALC_NEXT_EVALUATION;
        
        end else if(state == CALC_NEXT_EVALUATION) begin
            req_score <= 1;

            state <= REFLECT_NEXT_EVALUATION;

        end else if(state == REFLECT_NEXT_EVALUATION && recv_score == 1) begin
            
            req_score <= 0;

            if((temp_score < cur_score) && valid == 1) begin
                resp_col <= cur_col;
                resp_rotation <= cur_rotation;
                cur_score <= temp_score;

                /* DEBUG */
                
                capture_board <= next_board;
                capture_cleared_lines <= cleared_lines;
                    
                capture_max_height <= max_height;
                capture_cumulative_height <= cumulative_height;
                capture_relative_height <= relative_height;
                capture_roughness <= roughness;
                capture_hole_count <= hole_count;
                capture_row_transition <= row_transition;
                capture_col_transition <= col_transition;
                capture_deepest_well <= deepest_well;
                
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
            $display("max_height = %d, weight = %d -> temp_score = %d", 
            capture_max_height, MAX_HEIGHT_WEIGHT, capture_max_height * MAX_HEIGHT_WEIGHT);
            $display("cumulative_height = %d, weight = %d -> temp_score = %d", 
            capture_cumulative_height, CUMULATIVE_HEIGHT_WEIGHT, capture_cumulative_height * CUMULATIVE_HEIGHT_WEIGHT);
            $display("relative_height = %d, weight = %d -> temp_score = %d", 
            capture_relative_height, RELATIVE_HEIGHT_WEIGHT, capture_relative_height * RELATIVE_HEIGHT_WEIGHT);
            $display("roughness = %d, weight = %d -> temp_score = %d", 
            capture_roughness, ROUGHNESS_WEIGHT, capture_roughness * ROUGHNESS_WEIGHT);
            $display("hole_count = %d, weight = %d -> temp_score = %d", 
            capture_hole_count, HOLE_COUNT_WEIGHT, capture_hole_count * HOLE_COUNT_WEIGHT);
            $display("remove_line = %d, weight = %d -> temp_score = %d", 
            capture_cleared_lines, CLEARED_LINES_WEIGHT, capture_cleared_lines * CLEARED_LINES_WEIGHT);
            $display("row_transition = %d, weight = %d -> temp_score = %d", 
            capture_row_transition, ROW_TRANSITION_WEIGHT, capture_row_transition * ROW_TRANSITION_WEIGHT);
            $display("col_transition = %d, weight = %d -> temp_score = %d", 
            capture_col_transition, COL_TRANSITION_WEIGHT, capture_col_transition * COL_TRANSITION_WEIGHT);
            $display("deepest_well = %d, weight = %d -> temp_score = %d", 
            capture_deepest_well, DEEPEST_WELL_WEIGHT, capture_deepest_well * DEEPEST_WELL_WEIGHT);
            $display("score = %d", cur_score);
            */


            capture_board <= 0;
            

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
                    temp_valid, temp_board, temp_cleared_lines, sim_ready);

    board_analysis bevaluate(clk, req_score, next_board, cleared_lines,                   
                             recv_score, temp_score,
                             max_height, cumulative_height, relative_height, roughness, hole_count, row_transition, col_transition, deepest_well
                             );
endmodule


