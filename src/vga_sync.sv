/*******************************************************************************
 * CS220: Digital Circuit Lab
 * Computer Science Department
 * University of Crete
 * 
 * Date: 2023/XX/XX
 * Author: Dimitris Vlachos
 * Filename: vga_sync.sv
 * Description: Implements VGA HSYNC and VSYNC timings for 640 x 480 @ 60Hz
 *
 ******************************************************************************/

module vga_sync(
  input logic clk,
  input logic rst,

  output logic o_pix_valid,
  output logic [9:0] o_col,
  output logic [9:0] o_row,

  output logic o_hsync,
  output logic o_vsync
);


parameter int FRAME_HPIXELS     = 640;
parameter int FRAME_HFPORCH     = 16;
parameter int FRAME_HSPULSE     = 96;
parameter int FRAME_HBPORCH     = 48;
parameter int FRAME_MAX_HCOUNT  = 800;

parameter int FRAME_VLINES      = 480;
parameter int FRAME_VFPORCH     = 10;
parameter int FRAME_VSPULSE     = 2;
parameter int FRAME_VBPORCH     = 29;
parameter int FRAME_MAX_VCOUNT  = 521;



// Implement your code here


logic hcnt_clr;
logic[9:0] hcnt; //count columns 10(0-1024) bits for 800 columns
logic hs_set;
logic hs_clr;
logic hsync;
logic vcnt_clr;
logic [9:0] vcnt; //count rows 10(0-1024) bits for 520 rows  
logic vs_set;
logic vs_clr;
logic vsync;
logic hsync_out ;

always_comb begin //produce hcnt_clr ,hs_set ,hs_clr signals 
   hcnt_clr = ((FRAME_MAX_HCOUNT-1) == hcnt);
   hs_set = ((FRAME_HPIXELS + FRAME_HFPORCH -1 ) == hcnt);
   hs_clr = ((FRAME_HPIXELS + FRAME_HFPORCH + FRAME_HSPULSE -1) == hcnt);
end 

always_comb begin //produce vcnt_clear,vs_set,vs_clr signals
    vcnt_clr = (vcnt == FRAME_MAX_VCOUNT-1) & hcnt_clr;
    vs_set = ((vcnt == (FRAME_VLINES + FRAME_VFPORCH -1)) & hcnt_clr);
    vs_clr = ( (vcnt== (FRAME_VLINES + FRAME_VFPORCH + FRAME_VSPULSE -1)) & hcnt_clr);
end


 

always_ff @( posedge clk) begin //increase counter or reset in flip flop
    if(rst)
        hcnt <=0;
    else   begin
        if(hcnt_clr)
             hcnt<=0;
         else
            hcnt <= hcnt+1;
    end
end


always_ff @( posedge clk) begin //red2
    if(rst)
        hsync <=0 ;
     else
        hsync <= (hs_set | hsync) & (~hs_clr);
end

always_ff @( posedge clk) begin //red3
     if(rst)
         hsync_out <=0;
      else
         hsync_out <= hsync;
 end



always_ff @( posedge clk)begin //green1
    if(rst)
        vcnt <= 0;
    else begin   
        if(hcnt_clr) //if zero cnt keeps the old val
            vcnt <= vcnt +1;
        if(vcnt_clr) //if zero cnt gets the value from the prev mux
            vcnt <= 0;
    end
    
end

always_ff @( posedge clk) begin//green2
    if(rst)
        vsync <=0 ;
     else
        vsync <= (vs_set | vsync) & (~vs_clr);
end

always_comb begin //out signals
    o_pix_valid = (hcnt<FRAME_HPIXELS) & (vcnt < FRAME_VLINES);
    o_col = hcnt;
    o_row = vcnt; 
end 

always_comb begin
    o_vsync = ~vsync;
    o_hsync = ~hsync_out;
end





endmodule

