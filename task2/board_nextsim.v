module board_nextsim(
    input clk,
    input [3:0] cur_block,      // tile inputs
    input [3:0] cur_col,
    input [1:0] cur_rotation,
    input [199:0] cur_board,    
    input sim_request,

    output reg valid,
    output reg [199:0] next_board,
    output reg sim_ready   
);
    
    parameter BLOCKS_IN_ROW = 20;
    parameter BLOCKS_IN_COL = 10;

    parameter BLOCKS_IN_ROW_EXT = 24;       // +4
    parameter BLOCKS_IN_COL_EXT = 13;       // +2
    parameter BLOCK_SIZE = 4;

    reg [1:0] state = 0;

    reg [311:0] buffered_board;    // 24*13 - 1
    reg [15:0] new_block;

    reg [5:0] col_idx, row_idx;

    reg [5:0] merge_row_offset;   // board<row_offset, 0> = block<0, 0>
    reg [2:0] merged_row_idx;
    reg merge_ok, coll;

    always @(posedge clk) begin 
        if(sim_request == 1 && state == 0) begin
        
            for(row_idx = BLOCK_SIZE; row_idx < BLOCKS_IN_ROW_EXT; row_idx = row_idx + 1) begin
                buffered_board[row_idx * BLOCKS_IN_COL_EXT + 3 +: BLOCKS_IN_COL] = cur_board[(row_idx - 4) * BLOCKS_IN_COL +: BLOCKS_IN_COL];
            end

            // $display("INIT target blk %d, target col(+2) %d", cur_block, cur_col);

            /*
            for(row_idx = 0; row_idx < BLOCKS_IN_ROW_EXT; row_idx = row_idx + 1) begin
                $display("INIT %dth col BUFBOARD %13b", row_idx, buffered_board[BLOCKS_IN_COL_EXT*row_idx +: BLOCKS_IN_COL_EXT]);
            end
            */
            
            case(cur_block)

                3'd1: begin
                    new_block = {4'b1100, 4'b1100, 4'b0000, 4'b0000};   
                end

                3'd2: begin
                    case(cur_rotation)
                        2'd0: new_block = {4'b1110, 4'b0100, 4'b0000, 4'b0000};
                        
                        // 2'd1: new_block = {4'b0100, 4'b0110, 4'b0100, 4'b0000};
                        2'd1: new_block = {4'b1000, 4'b1100, 4'b1000, 4'b0000}; // left 1
                        
                        2'd2: new_block = {4'b0100, 4'b1110, 4'b0000, 4'b0000};
                        
                        2'd3: new_block = {4'b0100, 4'b1100, 4'b0100, 4'b0000}; 
                    endcase
                end

                3'd3: begin
                    case(cur_rotation)
                        2'd0: new_block = {4'b1100, 4'b0110, 4'b0000, 4'b0000};
                        
                        // 2'd1: new_block = {4'b0010, 4'b0110, 4'b0100, 4'b0000};
                        2'd1: new_block = {4'b0100, 4'b1100, 4'b1000, 4'b0000}; // left 1

                        2'd2: new_block = {4'b1100, 4'b0110, 4'b0000, 4'b0000};
                        
                        2'd3: new_block = {4'b0100, 4'b1100, 4'b1000, 4'b0000};
                    endcase
                end

                3'd4: begin
                    case(cur_rotation)
                        2'd0: new_block = {4'b0110, 4'b1100, 4'b0000, 4'b0000};
                        
                        2'd1: new_block = {4'b0100, 4'b0110, 4'b0010, 4'b0000};
                        // 2'd1: new_block = {4'b1000, 4'b1100, 4'b0100, 4'b0000}; // left 1

                        2'd2: new_block = {4'b0110, 4'b1100, 4'b0000, 4'b0000};
                        
                        2'd3: new_block = {4'b1000, 4'b1100, 4'b0100, 4'b0000};
                    endcase
                end

                3'd5: begin
                    case(cur_rotation)
                        2'd0: new_block = {4'b1110, 4'b1000, 4'b0000, 4'b0000};
                        
                        // 2'd1: new_block = {4'b0100, 4'b0100, 4'b0110, 4'b0000}; // why?
                        2'd1: new_block = {4'b1000, 4'b1000, 4'b1100, 4'b0000}; // left 1
                        
                        2'd2: new_block = {4'b0010, 4'b1110, 4'b0000, 4'b0000};
                        
                        2'd3: new_block = {4'b1100, 4'b0100, 4'b0100, 4'b0000}; // why?
                    endcase
                end

                3'd6: begin
                    case(cur_rotation)
                        2'd0: new_block = {4'b1110, 4'b0010, 4'b0000, 4'b0000};

                        // 2'd1: new_block = {4'b0110, 4'b0100, 4'b0100, 4'b0000};
                        2'd1: new_block = {4'b1100, 4'b1000, 4'b1000, 4'b0000}; // left 1
                        
                        2'd2: new_block = {4'b1000, 4'b1110, 4'b0000, 4'b0000};
                        2'd3: new_block = {4'b0100, 4'b0100, 4'b1100, 4'b0000};
                    endcase
                end

                default: begin
                    case(cur_rotation)
                        2'd0: new_block = {4'b1111, 4'b0000, 4'b0000, 4'b0000};
                        
                        // 2'd1: new_block = {4'b0010, 4'b0010, 4'b0010, 4'b0010}; 
                        2'd1: new_block = {4'b1000, 4'b1000, 4'b1000, 4'b1000}; // left 2

                        2'd2: new_block = {4'b1111, 4'b0000, 4'b0000, 4'b0000};
                        
                        // 2'd3: new_block = {4'b0100, 4'b0100, 4'b0100, 4'b0100};
                        2'd3: new_block = {4'b1000, 4'b1000, 4'b1000, 4'b1000}; // left 1
                    endcase
                end
            endcase

            merge_row_offset = 0;
            coll = 0;
            for(row_idx = BLOCK_SIZE; row_idx <= BLOCKS_IN_ROW; row_idx = row_idx + 1) begin
                merge_ok = 1;
                for(merged_row_idx = 0; merged_row_idx < BLOCK_SIZE; merged_row_idx = merged_row_idx + 1) begin
                    merge_ok = 
                        (((buffered_board[(row_idx + merged_row_idx) * BLOCKS_IN_COL_EXT + (cur_col + 3) -: BLOCK_SIZE] 
                            & new_block[merged_row_idx * BLOCK_SIZE + 3 -: BLOCK_SIZE]) 
                            == 4'd0) ? merge_ok : 0);
                        // $display("and result %d", buffered_board[(row_idx + merged_row_idx) * BLOCKS_IN_COL_EXT + (cur_col + 2) -: BLOCK_SIZE] 
                        //    & new_block[merged_row_idx * BLOCK_SIZE + 3 -: BLOCK_SIZE]);
                        // $display("buffer %dth: %4b", row_idx + merged_row_idx, buffered_board[(row_idx + merged_row_idx) * BLOCKS_IN_COL_EXT + (cur_col + 2) -: BLOCK_SIZE]);
                        // $display("new_block %dth: %4b", merged_row_idx, new_block[merged_row_idx * BLOCK_SIZE + 3 -: BLOCK_SIZE]);
                end

                if(merge_ok == 1 && coll == 0) begin
                    // $display("new row idx %d", row_idx);
                    merge_row_offset = row_idx;
                
                end else if (merge_ok == 0) begin
                    coll = 1;
                end
            end
            
            for(merged_row_idx = 0; merged_row_idx < BLOCK_SIZE; merged_row_idx = merged_row_idx + 1) begin
                buffered_board[(merge_row_offset + merged_row_idx) * BLOCKS_IN_COL_EXT + (cur_col + 3) -: BLOCK_SIZE] = 
                    buffered_board[(merge_row_offset + merged_row_idx) * BLOCKS_IN_COL_EXT + (cur_col + 3) -: BLOCK_SIZE] 
                    | new_block[merged_row_idx * BLOCK_SIZE + 3 -: BLOCK_SIZE];
            end

            valid = 1;
            for(row_idx = 0; row_idx < BLOCK_SIZE; row_idx = row_idx + 1) begin
                if(buffered_board[BLOCKS_IN_COL_EXT * row_idx +: BLOCKS_IN_ROW_EXT] != 12'd0) begin
                    valid = 0;
                end
            end

            for(row_idx = 0; row_idx < BLOCKS_IN_ROW_EXT; row_idx = row_idx + 1) begin
                if(buffered_board[BLOCKS_IN_COL_EXT * row_idx +: 3] != 2'd0) begin
                    valid = 0;
                end
            end

            for(row_idx = 0; row_idx < BLOCKS_IN_ROW; row_idx = row_idx + 1) begin
                next_board[row_idx * BLOCKS_IN_COL +: BLOCKS_IN_COL] = buffered_board[(row_idx + 4) * BLOCKS_IN_COL_EXT + 3 +: BLOCKS_IN_COL];
            end 
            state <= 1;
            sim_ready <= 1;
        
        end else if(state == 1) begin
            /*
            for(row_idx = 0; row_idx < BLOCKS_IN_ROW_EXT; row_idx = row_idx + 1) begin
                $display("BUFBOARD %13b", buffered_board[BLOCKS_IN_COL_EXT * row_idx +: BLOCKS_IN_COL_EXT]);
            end

            for(row_idx = 0; row_idx < BLOCK_SIZE; row_idx = row_idx + 1) begin
                $display("BLK %4b", new_block[BLOCK_SIZE*row_idx +: BLOCK_SIZE]);
            end

            for(row_idx = 0; row_idx < BLOCKS_IN_ROW; row_idx  = row_idx + 1) begin
                $display("FINBORAD %10b", next_board[BLOCKS_IN_COL*row_idx  +: BLOCKS_IN_COL]);
            end
            */

            state <= 0;
            sim_ready <= 0;
            buffered_board = 312'd0;
        
        end else begin
            sim_ready <= 0;
            buffered_board = 312'd0;
        end 
    end

endmodule
