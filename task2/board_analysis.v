module board_analysis(
    input clk,
    input req_score,
    input [199:0] board,                    // [10*rnum + 9 : 10*rnum] -> rnum 'th row

    output reg recv_score,
    output reg [31:0] score                    // 10 elements of 5bit col. height
);

    parameter BLOCKS_IN_ROW = 20;
    parameter BLOCKS_IN_COL = 10;

    reg [5:0] col_idx, row_idx;

    reg [4:0] column_heights [0:9];  // 10 elements of 5bit col. height
    reg [4:0] max_height;            // max height
    reg [7:0] cumulative_height;     // cumulative_height
    reg [4:0] relative_height;       // max height - min height
    reg [7:0] roughness;             // sum of |diff. of two adjoint column)
    reg [7:0] hole_count;            // hole_count
    reg [4:0] cleared_lines;

    reg [4:0] min_height;

    // NEGATE value of real trained weight in genetic_train.py
    /* genetic_train.py (ver. 2) */
    parameter MAX_HEIGHT_WEIGHT = 39511;
    parameter CUMULATIVE_HEIGHT_WEIGHT = 745266;
    parameter RELATIVE_HEIGHT_WEIGHT = -290263;
    parameter ROUGHNESS_WEIGHT = 330122;
    parameter HOLE_COUNT_WEIGHT = 631013;
    parameter CLEARED_LINES_WEIGHT = -872804;

    parameter REQ_SCORE = 2'd0;
    parameter CALC_SCORE = 2'd1;
    parameter RECV_SCORE = 2'd2;
    reg [2:0] state = REQ_SCORE;
    
    always @(posedge clk) begin
        
        if(state == REQ_SCORE && req_score == 1) begin
            recv_score <= 0;
            // column_heights
            for(col_idx = 0; col_idx < BLOCKS_IN_COL; col_idx = col_idx + 1) begin
                column_heights[col_idx] = 5'd0;
                
                for(row_idx = 0; row_idx < BLOCKS_IN_ROW; row_idx = row_idx + 1) begin
                    if(board[BLOCKS_IN_COL * row_idx + col_idx] != 0 && column_heights[col_idx] == 5'd0) begin
                        column_heights[col_idx] = 5'd20 - row_idx;
                    end
                end
            end

            // max_height
            max_height = 5'd0;
            for(col_idx = 1; col_idx < BLOCKS_IN_COL; col_idx = col_idx + 1) begin
                if (column_heights[col_idx] > max_height) begin
                    max_height = column_heights[col_idx];
                end
            end
            // $display("ANALY) max %2d", max_height);
    
            // cumulative_height
            cumulative_height = 0;
            for(col_idx = 0; col_idx < BLOCKS_IN_COL; col_idx = col_idx + 1) begin
                cumulative_height = cumulative_height + column_heights[col_idx];
            end
            // $display("ANALY) cumulatve %3d", cumulative_height);


            // relative Height
            min_height = 5'd20;
            for(col_idx = 0; col_idx < BLOCKS_IN_COL; col_idx = col_idx + 1) begin
                if (column_heights[col_idx] < min_height) begin
                    min_height = column_heights[col_idx];
                end
            end

            relative_height = max_height - min_height;
            // $display("ANALY) relative %3d", relative_height);

            // roughness
            roughness = 8'd0;
            for(col_idx = 0; col_idx < BLOCKS_IN_COL - 1; col_idx = col_idx + 1) begin
                roughness = roughness + (column_heights[col_idx] > column_heights[col_idx+1] ?
                                        column_heights[col_idx] - column_heights[col_idx+1] :
                                        column_heights[col_idx+1] - column_heights[col_idx]
                                        );
            end
            // $display("ANALY) roughness %3d", roughness);


            // hole count
            hole_count = 8'd0;
            for(col_idx = 0; col_idx < BLOCKS_IN_COL; col_idx = col_idx + 1) begin
                if(column_heights[col_idx] > 0) begin  
                    for(row_idx = 0; row_idx < BLOCKS_IN_ROW; row_idx = row_idx + 1) begin
                        if(board[row_idx * BLOCKS_IN_COL + col_idx] == 0 && row_idx > (20 - column_heights[col_idx])) begin
                            hole_count = hole_count + 1;
                        end
                    end
                end
            end
            // $display("ANALY) holes %3d", hole_count);


            // cleared lines
            cleared_lines = 8'd0;
            for(row_idx = 0; row_idx < BLOCKS_IN_ROW; row_idx = row_idx + 1) begin
                if(board[row_idx * BLOCKS_IN_COL +: BLOCKS_IN_COL] == 10'b1111111111) begin  
                    cleared_lines = cleared_lines + 1;
                end
            end
            // $display("ANALY) cleared_lines %3d", cleared_lines);

            state <= CALC_SCORE;
    
        end else if (state == CALC_SCORE) begin
            // total score
            score <= (max_height * MAX_HEIGHT_WEIGHT 
                + cumulative_height * CUMULATIVE_HEIGHT_WEIGHT 
                + relative_height * RELATIVE_HEIGHT_WEIGHT 
                + roughness * ROUGHNESS_WEIGHT
                + hole_count * HOLE_COUNT_WEIGHT
                + cleared_lines *CLEARED_LINES_WEIGHT);

            // $display("ANALY) score %d", score);
            recv_score <= 1;
            state <= 2;

        end else if (state == RECV_SCORE) begin
            recv_score <= 0;
            state <= 0;
    
        end else begin
            recv_score <= 0;
        end
    end 

endmodule

/* practically found weights (ver. 1)
    parameter MAX_HEIGHT_WEIGHT = 178;
    parameter CUMULATIVE_HEIGHT_WEIGHT = 525;
    parameter RELATIVE_HEIGHT_WEIGHT = 198;
    parameter ROUGHNESS_WEIGHT = 284;
    parameter HOLE_COUNT_WEIGHT = 685;
    parameter CLEARED_LINES_WEIGHT = -873;
*/

/* genetic_train.py (ver. 2)
    {
        'max_height': 0.0395105206789681, 
        'cumulative_height': -0.7452658095158735, 
        'relative_height': 0.2902629677655959, 
        'roughness': -0.3301215337913299, 
        'hole_count': -0.6310130023664553, 
        'rows_cleared': 0.8728045079072444}, 
        'play_score': 198, 
        agent_idx': 20
    }
*/
