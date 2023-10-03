/*******************************************************************************
 * CS220: Digital Circuit Lab
 * Computer Science Department
 * University of Crete
 * 
 * Date: 2023/XX/XX
 * Author: Your name here
 * Filename: maze_controller.sv
 * Description: Your description here
 *
 ******************************************************************************/

module maze_controller(
  input  logic clk,
  input  logic rst,

  input  logic i_control,
  input  logic i_up,
  input  logic i_down,
  input  logic i_left,
  input  logic i_right,

  output logic        o_rom_en,
  output logic [10:0] o_rom_addr,
  input  logic [15:0] i_rom_data,

  output logic [5:0] o_player_bcol,
  output logic [5:0] o_player_brow,

  input  logic [5:0] i_exit_bcol,
  input  logic [5:0] i_exit_brow,

  output logic [7:0] o_leds,
  output logic o_update_bar
);

// Implement your code here

logic [1:0] start_condition = 0;
logic [5:0] new_col ;
logic [5:0] new_row ;
logic [2:0] restart ;
logic [31:0] cycles;
logic [5:0] secs;

typedef enum logic [3:0]{
    STATE_IDLE  = 4'h1,
    STATE_PLAY  = 4'h2,
    STATE_UP    = 4'h3,
    STATE_DOWN  = 4'h4,
    STATE_LEFT  = 4'h5 ,
    STATE_RIGHT = 4'h6,
    STATE_READROM= 4'h7,
    STATE_CHECK = 4'h8,
    STATE_UPDATE= 4'h9,
    STATE_END   = 4'hA

} FSM_State_t;

FSM_State_t current_state,next_state;




always_ff @(posedge clk) begin 
    if(rst)
        start_condition <=0;
     else begin
        if(current_state == STATE_IDLE) begin
            if(i_control) begin
                start_condition <= start_condition+1;
                if(i_control >3)
                    start_condition <=0;
            end
            if(i_up || i_down || i_left || i_right)
                start_condition <=0;       
        end
     end
     
end

always_ff @(posedge clk) begin 
    if(rst)
        restart <=0;
     else begin
        if(current_state == STATE_PLAY) begin
            if(i_control) begin
                restart <= restart+1;
                if(i_control >5)
                    restart <=0;
            end
        end
     end
     
end




always_ff @( posedge clk) begin
if (rst) current_state <= STATE_IDLE;
else current_state <= next_state;
end


always_ff @(posedge clk) begin 
    if(rst) begin
        o_player_bcol <= 1; 
        o_player_brow <=0;
    end
    else begin
        if(current_state == STATE_IDLE) begin
            o_player_bcol <=1 ;
            o_player_brow <=0 ;
        end
        else if(current_state == STATE_UPDATE) begin
            o_player_bcol <= new_col;
            o_player_brow <= new_row;
        end
    end

end


always_ff @(posedge clk) begin
    if(rst) begin
        new_col <=1;
        new_row <=0;
    end
    else begin
        if(current_state == STATE_UP) begin
            if(o_player_brow == 0) begin
                new_col <= o_player_bcol;
                new_row <= o_player_brow;
            end
            else begin    
            new_col <= o_player_bcol ;
            new_row <= o_player_brow -1;
            end
        end    
        else if(current_state == STATE_DOWN) begin
            new_col <= o_player_bcol;
            new_row <= o_player_brow +1 ;
        end    
        else if(current_state == STATE_LEFT)begin
            new_col <= o_player_bcol-1;
            new_row <= o_player_brow;
        end   
        else if(current_state ==STATE_RIGHT)begin
            new_col <= o_player_bcol+1;
            new_row <= o_player_brow;        
        end
        
    end
end

always_comb begin
    next_state = current_state;
    o_leds = 8'h0;
    o_rom_en = 0;
    o_rom_addr = 0;
    case (current_state)
        STATE_IDLE :begin
        o_leds = 8'h1;
        if(start_condition == 3)
            next_state = STATE_PLAY;
        end
        STATE_PLAY :begin
            o_leds = 8'h2;
            if(secs == 40)
                next_state = STATE_END;
             //check for exit
            if( (o_player_bcol == i_exit_bcol) &&  (o_player_brow == i_exit_brow))
                next_state = STATE_END;
                
            else begin      
                if(i_up)
                    next_state = STATE_UP;
                else if(i_down)
                    next_state = STATE_DOWN;
                 else if(i_left)
                    next_state = STATE_LEFT;
                else if(i_right)
                    next_state = STATE_RIGHT;
            end
            if(restart == 5)
                next_state = STATE_IDLE;
            
        end
        STATE_UP :begin
         o_leds = 8'h3;
         next_state = STATE_READROM;    
        end
        STATE_DOWN :begin 
         o_leds = 8'h4;
         next_state = STATE_READROM;    
        end
        STATE_LEFT :begin
         o_leds = 8'h5;
         next_state = STATE_READROM;     
        end
        STATE_RIGHT :begin
         o_leds = 8'h6;
         next_state = STATE_READROM;     
        end
        STATE_READROM :begin
         o_leds = 8'h7;
         o_rom_en = 1;
         o_rom_addr = new_col+(new_row*64);
         next_state = STATE_CHECK;    
        end
        STATE_CHECK :begin
         o_leds = 8'h8;
         if(i_rom_data[11:0] == 12'h0) begin //not valid
            next_state = STATE_PLAY;
         end    
         else
            next_state = STATE_UPDATE;     
        end
        STATE_UPDATE :begin
         o_leds = 8'h9;
         next_state = STATE_PLAY;    
        end
        STATE_END :begin
         o_leds = 8'hA;
         if(i_control == 1)
            next_state = STATE_IDLE;    
        end
        default: begin
        end
    endcase

end


always_ff @(posedge clk) begin
    if(rst)
        cycles <=0;
    else begin
       if(current_state == STATE_PLAY)
            cycles<=cycles +1 ;
    end     
end

always_ff @(posedge clk) begin
    if(rst) begin
        secs <=0;
        o_update_bar <= 0;
    end    
    else begin
        if(cycles == 25000000) begin
            secs<=secs+1;
            o_update_bar <= 1;
            cycles<=0;
        end
        if(secs == 40)
            secs<=0;    
    end    
      
end

endmodule
