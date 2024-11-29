`include "calc.v"

module tetris(
    input clk,                  // clock    
    input reset,                // reset
    input host_ready,           // not - busy
    output reg player_ready,    // our AI is active!

    input [3:0] tile_type,      // tile inputs

    output reg row_req,         // send 
    output reg [5:0] row,       // row index (0: top ~ 19 : bottom)
    input [9:0] row_info,       // 10-wide row's info (LEFTMOST(9) ... RIGHTMOST(0))

    output reg [3:0] col,       // leftmost anchor index for N*N (N = 2, 3, 4)-sized block
    output reg [1:0] rotation,  // 0~3 Rotation modes
    output reg set_tile
);
    // declare registers, variables freely
    reg initalized = 0;

    parameter RECV_BLOCK_FROM_BOARD = 3'd0;
    parameter REQ_ROWS_TO_BOARD = 3'd1;
    parameter RESP_ROWS_FROM_BOARD = 3'd2;
    parameter REQ_OPTIM_POS = 3'd3;
    parameter RESP_OPTIM_POS = 3'd4;
    parameter REQ_SET_TO_BOARD = 3'd5;
    reg [2:0] state;      // what is "NEXT TODO"?

    reg [3:0] cur_block;

    reg [9:0] high1_row_info, high2_row_info;
    reg [5:0] cur_row_idx;
    reg block_exist;

    reg req_to_client;
    wire resp_from_client;

    reg [3:0] opt_col;       // leftmost anchor index for N*N (N = 2, 3, 4)-sized block
    reg [1:0] opt_rotation;  // 0~3 Rotation modes
    
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            col <= 0;
            rotation <= 0;
            set_tile <= 0;
            row_req <= 0;
            row <= 0;
        end 
        else begin
            // TODO
            if(initalized == 0) begin
                player_ready <= 1;
                initalized <= 1;
                state <= RECV_BLOCK_FROM_BOARD;

            end else begin
                if(host_ready == 1 && state == RECV_BLOCK_FROM_BOARD) begin
                    cur_row_idx <= 0;
                    block_exist <= 0;
                    req_to_client <= 0;
 
                    cur_block <= tile_type;

                    state <= REQ_ROWS_TO_BOARD;

                    $display("IN) Blk: %d", tile_type);
                    
                end else if(host_ready == 1 && state == REQ_ROWS_TO_BOARD) begin
                    
                    row_req <= 1;
                    row <= cur_row_idx;
                    state <= RESP_ROWS_FROM_BOARD;
  
                end else if(host_ready == 1 && state == RESP_ROWS_FROM_BOARD) begin
                    if(block_exist == 0) begin
                        high1_row_info <= row_info;
                    end else begin
                        high2_row_info <= row_info;
                    end 

                    cur_row_idx <= cur_row_idx + 1;

                    if (block_exist == 1) begin
                        state <= REQ_OPTIM_POS;
                    end else if(cur_row_idx >= 17 || (row_info != 0 && block_exist == 0)) begin
                        block_exist <= 1;
                        state <= REQ_ROWS_TO_BOARD;
                    end else begin
                        state <= REQ_ROWS_TO_BOARD;
                    end
                
                end else if(host_ready == 1 && state == REQ_OPTIM_POS) begin
                    req_to_client <= 1;

                    state <= RESP_OPTIM_POS;

                end else if(resp_from_client == 1 && state == RESP_OPTIM_POS) begin
                    req_to_client <= 0;

                    col <= opt_col;
                    rotation <= opt_rotation;

                    state <= REQ_SET_TO_BOARD;

                end else if(host_ready == 1 && state == REQ_SET_TO_BOARD) begin
                    $display("OUT) Blk : %d\n Board: \n%10b\n%10b\n Res: %d %d", cur_block, high1_row_info, high2_row_info, col, rotation);

                    set_tile <= 1;

                    state <= RECV_BLOCK_FROM_BOARD;

                end else begin
                    row_req <= 0;
                    set_tile <= 0;
                end
            end
       end
    end //end always

    calc calcUnit(clk, req_to_client, cur_block, high1_row_info, high2_row_info, 
                  resp_from_client, opt_col, opt_rotation);

endmodule