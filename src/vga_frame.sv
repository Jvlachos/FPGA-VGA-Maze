/*******************************************************************************
 * CS220: Digital Circuit Lab
 * Computer Science Department
 * University of Crete
 * 
 * Date: 2023/02/06
 * Author: Dimitris Vlachos
 * Filename: vga_frame.sv
 * Description: Your description here
 *
 ******************************************************************************/

module vga_frame(
  input logic clk,
  input logic rst,

  input logic i_rom_en,
  input logic [10:0] i_rom_addr,
  output logic [15:0] o_rom_data,
  

  input logic i_pix_valid,
  input logic [9:0] i_col,
  input logic [9:0] i_row,
  input logic i_bar_en,
  input logic i_bar_draw,
  input logic [5:0] i_player_bcol,
  input logic [5:0] i_player_brow,

  input logic [5:0] i_exit_bcol,
  input logic [5:0] i_exit_brow,

  output logic [3:0] o_red,
  output logic [3:0] o_green,
  output logic [3:0] o_blue
);

// Implement your code here


logic [10:0] maze_addr;
logic [10:0] player_addr;
logic [10:0] exit_addr;

logic [15:0] maze_pixel;
logic [15:0] player_pixel;
logic [15:0] exit_pixel;

logic maze_en;
logic player_en;
logic exit_en;

logic temp_en_maze; 
logic temp_en_pl;
logic temp_en_exit;


logic[3:0] green_out;
logic[3:0] red_out;
logic[3:0] blue_out;



//ROM Template Instantiation
rom_dp#(
  .size(2048),
  .file("C:/roms/maze1.rom") 
)
maze_rom (
  .clk(clk),
  .en(temp_en_maze),
  .addr(maze_addr),
  .dout(maze_pixel),
  .en_b(i_rom_en),
  .addr_b(i_rom_addr),
  .dout_b(o_rom_data)
);


rom#(
  .size(256),
  .file("C:/roms/exit.rom") 
)
exit_rom (
  .clk(clk),
  .en(temp_en_exit),
  .addr(exit_addr),
  .dout(exit_pixel)
);



rom#(
  .size(256),
  .file("C:/roms/player.rom") 
)
player_rom (
  .clk(clk),
  .en(temp_en_pl),
  .addr(player_addr),
  .dout(player_pixel)
);



logic valid;

always_ff@(posedge clk or posedge rst) begin
    if(rst)
        valid <=0;
    else
        valid<=i_pix_valid;
end 

always_comb begin //calc addresses 
   maze_addr =( (i_col/16) + ((i_row/16)*64));
   player_addr = ((i_row%16) + (i_col%16*16));
   exit_addr = ((i_row%16) + (i_col%16*16));
end

always_comb begin

    if( (i_col/16 == i_player_bcol) && (i_row/16 == i_player_brow)) begin
        temp_en_pl = 1;
        temp_en_maze = 0;
        temp_en_exit = 0;
    end 
    else if( (i_col/16 == i_exit_bcol) && (i_row/16 ==  i_exit_brow))begin
        temp_en_pl = 0;
        temp_en_maze = 0;
        temp_en_exit =1; 
    end     
    else begin
        temp_en_pl = 0;
        temp_en_maze =1;
        temp_en_exit =0;
    end
end



always_ff@(posedge clk or posedge rst) begin
    if(rst) begin
        o_blue <=4'h0;
        o_green<=4'h0;
        o_red  <=4'h0;
    end
    else begin
          if(valid) begin
            if(player_en) begin
                o_blue <= player_pixel[3:0];
                o_green<=player_pixel[7:4];
                o_red<= player_pixel[11:8];
            end
            else if(exit_en) begin
                o_blue <= exit_pixel[3:0];
                o_green<= exit_pixel[7:4];
                o_red<=  exit_pixel[11:8];
            end
            else if(maze_en) begin
                o_blue <= maze_pixel[3:0];
                o_green<=maze_pixel[7:4];
                o_red<= maze_pixel[11:8];
            end
            else begin
                o_blue <=4'h0;
                o_green<=4'h0;
                o_red  <=4'h0;
            end
            if(i_bar_draw == 1)
                o_red <= 4'hf;
            
        end
      else begin
          o_blue <=4'h0;
        o_green<=4'h0;
        o_red  <=4'h0;
      end
    
    end    
end 



always_ff@(posedge clk or posedge rst) begin
   if(rst) begin 
     maze_en <=0;
     player_en <=0;
     exit_en <=0;
   end  
   else begin
     maze_en <= temp_en_maze;
     player_en <= temp_en_pl;
     exit_en <= temp_en_exit;
   end
end


endmodule
