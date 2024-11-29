module tetris(
    input clk,
    input reset,
    input host_ready,
    output reg player_ready,

    input [3:0] tile_type,

    output reg row_req,
    output reg [5:0] row,
    input [9:0] row_info,

    output reg [3:0] col,
    output reg [1:0] rotation,
    output reg set_tile
);
    // declare registers, variables freely
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
            player_ready <= 1;
            set_tile <= 1;
	    end
    end //end always
endmodule
