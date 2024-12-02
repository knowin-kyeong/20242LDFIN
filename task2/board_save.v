//`include "board_analysis.v"

module board_save(
    input clk,
    input req_save_to_board,
    input req_analy_to_board,
    input [5:0] row_idx,      
    input [9:0] row_info,      // 10-wide row's info (RIGHTMOST(9) ... LEFTMOST(0))
    
    output reg ready_from_board,
    output reg resp_from_board,
    output reg [199:0] board
);
    
    parameter BLOCKS_IN_ROW = 20;
    parameter BLOCKS_IN_COL = 10;

    reg [5:0] save_row_idx;

    always @(posedge clk) begin 
        if(req_save_to_board == 1) begin
            // $display("SAVE) REQ ROW: %d", row_idx);

            board[row_idx * BLOCKS_IN_COL +: BLOCKS_IN_COL] = row_info;
            
            resp_from_board <= 1;
            ready_from_board <= 0;

        end else if(req_analy_to_board == 1) begin
            // $display("SAVE) ANALYSIS RUNNING");

            resp_from_board <= 1;
            ready_from_board <= 0;
        
        end else begin
            resp_from_board <= 0;
            ready_from_board <= 1;
        end
    end
endmodule