`timescale 1ns/10ps
module geofence (clk, reset, X, Y, valid, is_inside);
input clk;
input reset;
input [9:0] X;
input [9:0] Y;
output reg valid;
output reg is_inside;

parameter INIT=3'd0, IN_DATA=3'd1, FIND_LEFT_POINT=3'd2, SLOPE_SORT=3'd3
          ,CROSS_PRODUCT=3'd4,CROSS_PRODUCT1=3'd5,FINAL=3'd6;
reg [3:0] state, next_state;
reg [19:0] data_y_x[0:7];
reg signed [21:0] multiply_result1,multiply_result2,
                  cross_pro_result1,cross_pro_result2,cross_pro_result3,cross_pro_result4;
reg [2:0] i, j, k,h;
reg [3:0] f;

mul_shift_add slope1(
    .a(data_y_x[i][19:10]), 
    .b(data_y_x[1][19:10]),
    .c(data_y_x[i+1][9:0]),
    .d(data_y_x[1][9:0]),
    .result(multiply_result1)
);
mul_shift_add slope2(
    .a(data_y_x[i+1][19:10]),
    .b(data_y_x[1][19:10]),
    .c(data_y_x[i][9:0]),
    .d(data_y_x[1][9:0]),
    .result(multiply_result2)
);
mul_shift_add cross_pro1(
    .a(data_y_x[j][9:0]),
    .b(data_y_x[0][9:0]),
    .c(data_y_x[j+1][19:10]),
    .d(data_y_x[0][19:10]),
    .result(cross_pro_result1)
);
mul_shift_add cross_pro2(
    .a(data_y_x[j][19:10]),
    .b(data_y_x[0][19:10]),
    .c(data_y_x[j+1][9:0]),
    .d(data_y_x[0][9:0]),
    .result(cross_pro_result2)
);

mul_shift_add cross_pro3(
    .a(data_y_x[1][19:10]),
    .b(data_y_x[0][19:10]),
    .c(data_y_x[7][9:0]),
    .d(data_y_x[0][9:0]),
    .result(cross_pro_result3)
);

mul_shift_add cross_pro4(
    .a(data_y_x[7][19:10]),
    .b(data_y_x[0][19:10]),
    .c(data_y_x[1][9:0]),
    .d(data_y_x[0][9:0]),
    .result(cross_pro_result4)
);

always @(posedge clk or posedge reset ) begin
  if(reset) state<=IN_DATA;
  else state<=next_state;
end

always @(*) begin
    case (state)
        INIT: next_state<=IN_DATA;
        IN_DATA: next_state<=(i>6)?FIND_LEFT_POINT:IN_DATA;
        FIND_LEFT_POINT:next_state<=(j>4)?SLOPE_SORT:FIND_LEFT_POINT;
        SLOPE_SORT:next_state<=(k>3)?CROSS_PRODUCT:SLOPE_SORT;
        CROSS_PRODUCT:next_state<=(j>5)?CROSS_PRODUCT1:CROSS_PRODUCT;
        CROSS_PRODUCT1:next_state<=FINAL;
        FINAL:next_state<=INIT;
        default: next_state<=INIT;
    endcase
end

always @(posedge clk or posedge reset) begin
    if (reset) begin
        i<=0;
        j<=0;
        k<=0;
        h<=0;
        valid<=0;
    end

    else begin
       case (state)
       INIT: begin
            i<=0;
            j<=0;
            k<=0;
            h<=0;
            valid<=0;          
        end

        IN_DATA: begin
            data_y_x[i][9:0]<=X;
            data_y_x[i][19:10]<=Y;
            i<=i+1;
        end

        FIND_LEFT_POINT: begin
            i<=2;
            data_y_x[1]<=(data_y_x[1][9:0]<data_y_x[j+2][9:0])?data_y_x[1]:data_y_x[j+2];
            data_y_x[j+2]<=(data_y_x[1][9:0]<data_y_x[j+2][9:0])?data_y_x[j+2]:data_y_x[1];
            j<=j+1;
        end

        SLOPE_SORT:begin
            j<=1;   
            data_y_x[i]<=(multiply_result1>multiply_result2)?data_y_x[i]:data_y_x[i+1];
            data_y_x[i+1]<=(multiply_result1>multiply_result2)?data_y_x[i+1]:data_y_x[i];
            k<=(i>5)?k+1:k;
            i<=(i>5)?2:i+1;
        end

        CROSS_PRODUCT:begin
            k<=0;
            h<=(cross_pro_result1<cross_pro_result2)?h+1:h;
            j<=j+1;
        end

        CROSS_PRODUCT1:begin
            h<=(cross_pro_result3<cross_pro_result4)?h+1:h;
        end

        FINAL:begin
            is_inside<=(h>6||h==0)?1:0;
            valid<=1;
        end
        default: begin
            i<=0;
            j<=0;
            k<=0;
            valid<=0;
            is_inside<=0;
        end   
    endcase
        
    end
end
endmodule

module mul_shift_add(
    input  [9:0] a,
    input  [9:0] b,
    input  [9:0] c,
    input  [9:0] d,
    output reg signed [21:0] result
);
    
    reg signed [10:0] a_b,c_d,a_abs, b_abs;
    reg  [21:0] accumulate1;
    always @(*) begin
            a_b=a-b;
            c_d=c-d;
            a_abs=(a_b < 0)?-a_b:a_b;
            b_abs=(c_d < 0)?-c_d:c_d;
            //  accumulate
            
            accumulate1= ((b_abs[4])?a_abs<<4:0)+((b_abs[5])?a_abs<<5:0)+((b_abs[6])?a_abs<<6:0)+((b_abs[7])?a_abs<<7:0)+
                       ((b_abs[8])?a_abs<<8:0)+((b_abs[9])?a_abs<<9:0);
            
            result=((a_b < 0) ^ (c_d < 0))?-accumulate1:accumulate1;
     
    end
endmodule


