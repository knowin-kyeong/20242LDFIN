module board_analysis(
    input [199:0] board,                    // [10*rnum + 9 : 10*rnum] -> rnum 'th row
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
    parameter MAX_HEIGHT_WEIGHT = 79112;
    parameter CUMULATIVE_HEIGHT_WEIGHT = 99462;
    parameter RELATIVE_HEIGHT_WEIGHT = -65674;
    parameter ROUGHNESS_WEIGHT = 39506;
    parameter HOLE_COUNT_WEIGHT = 86143;
    parameter CLEARED_LINES_WEIGHT = 44103;

    // column_heights
    always @(*) begin
        for(col_idx = 0; col_idx < BLOCKS_IN_COL; col_idx = col_idx + 1) begin
            column_heights[col_idx] = 5'd0;
            
            for(row_idx = 0; row_idx < BLOCKS_IN_ROW; row_idx = row_idx + 1) begin
                if(board[BLOCKS_IN_COL * row_idx + col_idx] != 0 && column_heights[col_idx] == 5'd0) begin
                    column_heights[col_idx] = 5'd20 - row_idx;
                end
            end
        end
    end

    // max_height
    always @(*) begin
        max_height = 5'd0;
        for(col_idx = 0; col_idx < BLOCKS_IN_COL; col_idx = col_idx + 1) begin
            if (column_heights[col_idx] > max_height) begin
                max_height = column_heights[col_idx];
            end
        end

        $display("ANALY) max %2d", max_height);
    end

    
    // cumulative_height
    always @(*) begin
        cumulative_height = 0;
        for(col_idx = 0; col_idx < BLOCKS_IN_COL; col_idx = col_idx + 1) begin
            cumulative_height = cumulative_height + column_heights[col_idx];
        end

        $display("ANALY) cumulatve %3d", cumulative_height);
    end

    // relative Height
    always @(*) begin
        min_height = 5'd20;
        for(col_idx = 0; col_idx < BLOCKS_IN_COL; col_idx = col_idx + 1) begin
            if (column_heights[col_idx] < min_height) begin
                min_height = column_heights[col_idx];
            end
        end

        relative_height = max_height - min_height;
        $display("ANALY) relative %3d", relative_height);
    end

    // roughness
    always @(*) begin
        roughness = 8'd0;
        for(col_idx = 0; col_idx < BLOCKS_IN_COL - 1; col_idx = col_idx + 1) begin
            roughness = roughness + (column_heights[col_idx] > column_heights[col_idx+1] ?
                                     column_heights[col_idx] - column_heights[col_idx+1] :
                                     column_heights[col_idx+1] - column_heights[col_idx]
                                     );
        end
        $display("ANALY) roughness %3d", roughness);
    end

    // hole count
    always @(*) begin
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
        $display("ANALY) holes %3d", hole_count);
    end 

    // cleared lines
    always @(*) begin
        cleared_lines = 8'd0;
        for(row_idx = 0; row_idx < BLOCKS_IN_ROW; row_idx = row_idx + 1) begin
            if(board[row_idx * BLOCKS_IN_COL +: BLOCKS_IN_COL] == 10'b1111111111) begin  
                cleared_lines = cleared_lines + 1;
            end
        end
        $display("ANALY) cleared_lines %3d", cleared_lines);
    end 

    // total score
    always @(*) begin
        score = max_height * MAX_HEIGHT_WEIGHT 
            + cumulative_height * CUMULATIVE_HEIGHT_WEIGHT 
            + relative_height * RELATIVE_HEIGHT_WEIGHT 
            + roughness * ROUGHNESS_WEIGHT
            + hole_count * HOLE_COUNT_WEIGHT
            + cleared_lines *CLEARED_LINES_WEIGHT;

        $display("ANALY) score %d", score);
    end 

endmodule

// ["max_height", "cumulative_height", "relative_height", "roughness", "hole_count", "rows_cleared"]
// [-0.7911168974843971, -0.9946149316688104, 0.6567364663099897, -0.39506011206546365, -0.8614241326515506, -0.4410330203032128]