`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////////////////////
// Engineer: Oguz Kaan Agac & Bora Ecer
//
// Create Date: 13/12/2016
// Updated:     Fixed VGA 640x480 @ 60 Hz timing for HDMI adapter compatibility.
//   - Removed mod-2 divider; clk must now be 25.175 MHz pixel clock directly
//     (reconfigure clk_wiz_0 in Vivado from 50 MHz → 25.175 MHz)
//   - HSYNC active-low pulse at counter_h [656..751]  (was wrong at [704..799])
//   - VSYNC active-low pulse at counter_v [490..491], total 525 lines (was 524)
//   - video_on and x/y pixel coordinates corrected to visible area 0..639 / 0..479
//
// Design Name: VGA Synchronization Logic
// Module Name: sync_mod
// Project Name: BASPONG
// Target Devices: BASYS3
//////////////////////////////////////////////////////////////////////////////////

module sync_mod (
    input  logic        clk,            // 25.175 MHz pixel clock from clk_wiz_0
    input  logic        reset,
    input  logic        start,
    output logic [9:0]  y_control,
    output logic [9:0]  x_control,
    output logic        horizontal_scan, // HSYNC  (active-low)
    output logic        vertical_scan,   // VSYNC  (active-low)
    output logic        video_on
);

    // ----------------------------------------------------------------
    // 640x480 @ 60 Hz timing parameters
    // ----------------------------------------------------------------
    // Horizontal (pixel counts, total = 800)
    localparam H_VISIBLE    = 640;
    localparam H_FP         = 16;   // front porch
    localparam H_SYNC_W     = 96;   // sync pulse width
    localparam H_BP         = 48;   // back porch
    localparam H_TOTAL      = 800;  // 640+16+96+48

    // HSYNC window [656 .. 751]
    localparam H_SYNC_START = H_VISIBLE + H_FP;           // 656
    localparam H_SYNC_END   = H_VISIBLE + H_FP + H_SYNC_W;// 752

    // Vertical (line counts, total = 525)
    localparam V_VISIBLE    = 480;
    localparam V_FP         = 10;   // front porch
    localparam V_SYNC_W     = 2;    // sync pulse width
    localparam V_BP         = 33;   // back porch
    localparam V_TOTAL      = 525;  // 480+10+2+33

    // VSYNC window [490 .. 491]
    localparam V_SYNC_START = V_VISIBLE + V_FP;            // 490
    localparam V_SYNC_END   = V_VISIBLE + V_FP + V_SYNC_W; // 492

    // ----------------------------------------------------------------
    // Counters
    // ----------------------------------------------------------------
    logic [9:0] counter_h;
    logic [9:0] counter_v;

    // Horizontal counter — increments every pixel clock
    always_ff @(posedge clk or posedge reset) begin
        if (reset)
            counter_h <= 10'd0;
        else if (start) begin
            if (counter_h == H_TOTAL - 1)
                counter_h <= 10'd0;
            else
                counter_h <= counter_h + 10'd1;
        end
    end

    // Vertical counter — increments at the end of each scanline
    always_ff @(posedge clk or posedge reset) begin
        if (reset)
            counter_v <= 10'd0;
        else if (start && (counter_h == H_TOTAL - 1)) begin
            if (counter_v == V_TOTAL - 1)
                counter_v <= 10'd0;
            else
                counter_v <= counter_v + 10'd1;
        end
    end

    // ----------------------------------------------------------------
    // Sync pulses — both active-low for 640x480 @ 60 Hz
    // ----------------------------------------------------------------
    assign horizontal_scan = ~((counter_h >= H_SYNC_START) && (counter_h < H_SYNC_END));
    assign vertical_scan   = ~((counter_v >= V_SYNC_START) && (counter_v < V_SYNC_END));

    // ----------------------------------------------------------------
    // Video active area and pixel coordinates
    // ----------------------------------------------------------------
    assign video_on  = (counter_h < H_VISIBLE) && (counter_v < V_VISIBLE);
    assign x_control = (counter_h < H_VISIBLE) ? counter_h : 10'd0;
    assign y_control = (counter_v < V_VISIBLE)  ? counter_v : 10'd0;

endmodule // sync_mod
