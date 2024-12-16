module board_analysis(
    input clk,
    input req_score,
    input [199:0] board,                    // [10*rnum + 9 : 10*rnum] -> rnum 'th row
    input [9:0] cleared_lines,              // cleared lines
    output reg recv_score,
    output reg signed [63:0] score,          // 10 elements of 5bit col. height

    /* DEBUG ONLY */
    output reg [9:0] max_height,                    // max height
    output reg [9:0] cumulative_height,             // cumulative_height
    output reg [9:0] relative_height,               // max height - min height
    output reg [9:0] roughness,                     // sum of |diff. of two adjoint column)
    output reg [9:0] hole_count,                    // hole_count
    output reg [9:0] row_transition,                // row transition
    output reg [9:0] col_transition,                // col transition
    output reg [9:0] deepest_well                  // deepest weel
);

    parameter BLOCKS_IN_ROW = 20, BLOCKS_IN_COL = 10;

    reg [5:0] col_idx, row_idx;

    reg [9:0] column_heights [0:9];          // 10 elements of 5bit col. height
    // reg [9:0] max_height;                    // max height
    // reg [9:0] cumulative_height;             // cumulative_height
    reg [9:0] min_height;
    // reg [9:0] relative_height;               // max height - min height
    // reg [9:0] roughness;                     // sum of |diff. of two adjoint column)
    // reg [9:0] hole_count;                    // hole_count
    reg prev_value;
    // reg [9:0] row_transition;                // row transition
    // reg [9:0] col_transition;                // col transition
    reg [9:0] temp_depth;
    // reg [9:0] deepest_well;                  // deepest weel
                 

    // NEGATE value of real trained weight in genetic_train.py
    /* genetic_train.py (ver. 3) */
    parameter signed MAX_HEIGHT_WEIGHT = 640262;
    parameter signed CUMULATIVE_HEIGHT_WEIGHT = 905723;
    parameter signed RELATIVE_HEIGHT_WEIGHT = -662923;
    parameter signed ROUGHNESS_WEIGHT = 303330;
    parameter signed HOLE_COUNT_WEIGHT = 986219;
    parameter signed CLEARED_LINES_WEIGHT = 822463;
    parameter signed ROW_TRANSITION_WEIGHT = 753124;
    parameter signed COL_TRANSITION_WEIGHT = 819983;
    parameter signed DEEPEST_WELL_WEIGHT = 219884;

    parameter REQ_SCORE = 2'd0;
    parameter CALC_SCORE = 2'd1;
    parameter RECV_SCORE = 2'd2;
    reg [2:0] state = REQ_SCORE;
    
    always @(posedge clk) begin
        
        if(state == REQ_SCORE && req_score == 1) begin
            recv_score <= 0;
            // column_heights
            for(col_idx = 0; col_idx < BLOCKS_IN_COL; col_idx = col_idx + 1) begin
                column_heights[col_idx] = 10'd0;
                
                for(row_idx = 0; row_idx < BLOCKS_IN_ROW; row_idx = row_idx + 1) begin
                    if(board[BLOCKS_IN_COL * row_idx + col_idx] != 0 && column_heights[col_idx] == 10'd0) begin
                        column_heights[col_idx] = 10'd20 - row_idx;
                    end
                end
            end

            // max_height
            max_height = 10'd0;
            for(col_idx = 0; col_idx < BLOCKS_IN_COL; col_idx = col_idx + 1) begin
                if (column_heights[col_idx] > max_height) begin
                    max_height = column_heights[col_idx];
                end
            end
            // $display("ANALY) max %2d", max_height);
    
            // cumulative_height
            cumulative_height = 10'd0;
            for(col_idx = 0; col_idx < BLOCKS_IN_COL; col_idx = col_idx + 1) begin
                cumulative_height = cumulative_height + column_heights[col_idx];
            end
            // $display("ANALY) cumulatve %3d", cumulative_height);


            // relative Height
            min_height = 10'd20;
            for(col_idx = 0; col_idx < BLOCKS_IN_COL; col_idx = col_idx + 1) begin
                if (column_heights[col_idx] < min_height) begin
                    min_height = column_heights[col_idx];
                end
            end

            relative_height = max_height - min_height;
            // $display("ANALY) relative %3d", relative_height);

            // roughness
            roughness = 10'd0;
            for(col_idx = 0; col_idx < BLOCKS_IN_COL - 1; col_idx = col_idx + 1) begin
                roughness = roughness + (column_heights[col_idx] > column_heights[col_idx+1] ?
                                        column_heights[col_idx] - column_heights[col_idx+1] :
                                        column_heights[col_idx+1] - column_heights[col_idx]
                                        );
            end
            // $display("ANALY) roughness %3d", roughness);


            // hole count
            hole_count = 10'd0;
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
            // $display("ANALY) cleared_lines %3d", cleared_lines);
            

            // row_transition
            row_transition = 10'd0;  
            for (row_idx = 0; row_idx < BLOCKS_IN_ROW; row_idx = row_idx + 1) begin
                prev_value = board[row_idx * BLOCKS_IN_COL];
                for (col_idx = 1; col_idx < BLOCKS_IN_COL; col_idx = col_idx + 1) begin
                    if (board[row_idx * BLOCKS_IN_COL + col_idx] != prev_value) begin
                        row_transition = row_transition + 1;
                        prev_value = board[row_idx * BLOCKS_IN_COL + col_idx];
                    end
                end
            end
            // $display("ANALY) row_transition %3d", row_transition);


            // Calculate column_transition
            col_transition = 10'd0;
            for (col_idx = 0; col_idx < BLOCKS_IN_COL; col_idx = col_idx + 1) begin
                if (column_heights[col_idx] > 1) begin
                    prev_value = board[(20-column_heights[col_idx]) * BLOCKS_IN_COL + col_idx];
                    for (row_idx = 1; row_idx < 20; row_idx = row_idx + 1) begin
                        if(row_idx >= BLOCKS_IN_ROW - column_heights[col_idx] + 1) begin
                            if (board[row_idx * BLOCKS_IN_COL + col_idx] != prev_value) begin
                            col_transition = col_transition + 1;
                            prev_value = board[row_idx * BLOCKS_IN_COL + col_idx];
                            end
                        end   
                    end
                end
            end
            // $display("ANALY) column_transition %3d", col_transition);


            // Calculate deepest_well
            deepest_well = (column_heights[1] - column_heights[0] > 0) ? 
                            (column_heights[1] - column_heights[0]) : 0; 
            deepest_well = (column_heights[BLOCKS_IN_COL-2] - column_heights[BLOCKS_IN_COL-1] > deepest_well) ? 
                            (column_heights[BLOCKS_IN_COL-2] - column_heights[BLOCKS_IN_COL-1]) : deepest_well; 

            for (col_idx = 1; col_idx < BLOCKS_IN_COL-1 ; col_idx = col_idx + 1) begin
                if (column_heights[col_idx] < column_heights[col_idx-1]) begin
                    if (column_heights[col_idx] < column_heights[col_idx+1]) begin

                        temp_depth = (column_heights[col_idx-1] < column_heights[col_idx+1] ? column_heights[col_idx-1] : column_heights[col_idx+1]) 
                                    - column_heights[col_idx];
                        
                        if (temp_depth > deepest_well) begin
                            deepest_well = temp_depth;
                        end
                    end
                end
            end
            // $display("ANALY) deepest_well %3d", deepest_well);
            
            state <= CALC_SCORE;
    
        end else if (state == CALC_SCORE) begin
            // total score
            score <= (
                  $signed(max_height) * MAX_HEIGHT_WEIGHT 
                + $signed(cumulative_height) * CUMULATIVE_HEIGHT_WEIGHT 
                + $signed(relative_height) * RELATIVE_HEIGHT_WEIGHT 
                + $signed(roughness) * ROUGHNESS_WEIGHT
                + $signed(hole_count) * HOLE_COUNT_WEIGHT
                + $signed(cleared_lines) * CLEARED_LINES_WEIGHT
                + $signed(row_transition) * ROW_TRANSITION_WEIGHT
                + $signed(col_transition) * COL_TRANSITION_WEIGHT
                + $signed(deepest_well) * DEEPEST_WELL_WEIGHT
            );

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

/* genetic_train.py (ver. 3)
    {
        'max_height': -0.6402616941177253, 
        'cumulative_height': -0.9057227254992681, 
        'relative_height': 0.6629232398286269, 
        'roughness': -0.30333012819140825, 
        'hole_count': -0.9862193439177145, 
        'rows_cleared':-0.8224629285758067, 
        'row_transition': -0.7531236446218958,
        'col_transition': -0.8199832628897716,
        'deepest_well': -0.21988398773744078
    }
*/ 