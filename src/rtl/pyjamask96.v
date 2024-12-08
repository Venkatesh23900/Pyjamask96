// Pyjamask-96 macros
`timescale 1ns/1ps

`define NB_ROUNDS_96    14

`define COL_M0          32'ha3861085
`define COL_M1          32'h63417021
`define COL_M2          32'h692cf280
`define COL_MK          32'hb881b9ca

`define KS_ROT_GAP1      8
`define KS_ROT_GAP2     15
`define KS_ROT_GAP3     18

`define KS_CONSTANT_0   32'h00000080
`define KS_CONSTANT_1   32'h00006a00
`define KS_CONSTANT_2   32'h003f0000
`define KS_CONSTANT_3   32'h24000000


module pyjamask96(
    input clk,
    input reset_n,
    input load,
    input start,
    input [7:0] byte_in,
    input [7:0] byte_key_in,
    output reg valid,
    output reg [7:0] byte_out 
    );

    // FSM states
    localparam [3:0]  
        IDLE =              4'd0,
        LOAD_STATES =       4'd1,
        PYJAMASK_RND =      4'd2,
        ADD_RND_KEY =       4'd3,
        SUB_BYTES =         4'd4,
        MIX_ROWS =          4'd5,
        FINAL_RND =         4'd6,
        OUT =               4'd7,
        DONE =              4'd8;

    // Store state and keystate
    reg [0:95] state;
    reg [0:127] key_state;

    // State vectors
    reg [2:0] curr_state, next_state;

    // Control signals
    reg load_key_and_state;
    reg load_key;

    reg add_rnd_key;
    reg sub_byte;
    reg mix_row;

    reg ks_mix_col;
    reg ks_mix_and_rot;
    reg ks_add_const;

    reg rst; // Reset counters
    reg out; // Output is ready

    reg [3:0] round_count;
    reg [4:0] byte_count;

    // State transition
    always @(posedge clk or negedge reset_n) begin
        if(!reset_n) curr_state <= IDLE;
        else curr_state <= next_state;       
    end

    //==============================================================================
    //=== Control path logic
    //==============================================================================

    always@(*) begin
        case(curr_state)
            IDLE: begin
                if(load) begin
                    load_key_and_state = 1;
                    load_key           = 0;
                    add_rnd_key        = 0;
                    sub_byte           = 0;
                    mix_row            = 0;
                    ks_mix_col         = 0;
                    ks_mix_and_rot     = 0;
                    ks_add_const       = 0;
                    rst                = 0;
                    out                = 0;  
                    next_state         = LOAD_STATES;
                end
                else begin
                    load_key_and_state = 0;
                    load_key           = 0;
                    add_rnd_key        = 0;
                    sub_byte           = 0;
                    mix_row            = 0;
                    ks_mix_col         = 0;
                    ks_mix_and_rot     = 0;
                    ks_add_const       = 0;
                    rst                = 0;
                    out                = 0;                
                    next_state         = IDLE;
                end
            end

            LOAD_STATES: begin
                if(start) begin
                    load_key_and_state = 0;
                    load_key           = 0;
                    add_rnd_key        = 0;
                    sub_byte           = 0;
                    mix_row            = 0;
                    ks_mix_col         = 0;
                    ks_mix_and_rot     = 0;
                    ks_add_const       = 0;
                    rst                = 0;
                    out                = 0; 
                    next_state         = PYJAMASK_RND;
                end
                else begin
                    load_key_and_state = (byte_count <= 5'hb) ? 1 : 0;
                    load_key           = (byte_count >= 5'hb & byte_count <= 5'hf) ? 1 : 0;
                    add_rnd_key        = 0;
                    sub_byte           = 0;
                    mix_row            = 0;
                    ks_mix_col         = 0;
                    ks_mix_and_rot     = 0;
                    ks_add_const       = 0;
                    rst                = 0;
                    out                = 0;                   
                    next_state         = LOAD_STATES;
                end
            end

            PYJAMASK_RND: begin
                if(round_count == `NB_ROUNDS_96) begin
                    load_key_and_state     = 0;
                    load_key               = 0;
                    add_rnd_key            = 1;
                    sub_byte               = 0;
                    mix_row                = 0;
                    ks_mix_col             = 0;
                    ks_mix_and_rot         = 0;
                    ks_add_const           = 0;
                    rst                    = 1;
                    out                    = 0;               
                    next_state             = FINAL_RND;
                end

                else begin
                    load_key_and_state     = 0;
                    load_key               = 0;
                    add_rnd_key            = 1;
                    sub_byte               = 0;
                    mix_row                = 0;
                    ks_mix_col             = 1;
                    ks_mix_and_rot         = 0;
                    ks_add_const           = 0;
                    rst                    = 0;
                    out                    = 0;               
                    next_state             = ADD_RND_KEY;
                end
            end

            ADD_RND_KEY: begin
                load_key_and_state     = 0;
                load_key               = 0;
                add_rnd_key            = 0;
                sub_byte               = 1;
                mix_row                = 0;
                ks_mix_col             = 0;
                ks_mix_and_rot         = 1;
                ks_add_const           = 0;
                rst                    = 0;
                out                    = 0;                 
                next_state             = SUB_BYTES;
            end

            SUB_BYTES: begin
                load_key_and_state     = 0;
                load_key               = 0;
                add_rnd_key            = 0;
                sub_byte               = 0;
                mix_row                = 1;
                ks_mix_col             = 0;
                ks_mix_and_rot         = 0;
                ks_add_const           = 1;
                rst                    = 0;
                out                    = 0;   
                next_state             = MIX_ROWS;
            end

            MIX_ROWS: begin
                load_key_and_state     = 0;
                load_key               = 0;
                add_rnd_key            = 0;
                sub_byte               = 0;
                mix_row                = 0;
                ks_mix_col             = 0;
                ks_mix_and_rot         = 0;
                ks_add_const           = 0;
                rst                    = 0;
                out                    = 0;                 
                next_state             = PYJAMASK_RND;
            end

            FINAL_RND: begin
                load_key_and_state     = 0;
                load_key               = 0;
                add_rnd_key            = 0;
                sub_byte               = 0;
                mix_row                = 0;
                ks_mix_col             = 0;
                ks_mix_and_rot         = 0;
                ks_add_const           = 0;
                rst                    = 0;
                out                    = 1;   
                next_state             = OUT;
            end

            OUT: begin
                if(byte_count == 4'd12) begin
                    load_key_and_state     = 0;
                    load_key               = 0;
                    add_rnd_key            = 0;
                    sub_byte               = 0;
                    mix_row                = 0;
                    ks_mix_col             = 0;
                    ks_mix_and_rot         = 0;
                    ks_add_const           = 0;
                    rst                    = 1;
                    out                    = 0; 
                    next_state             = DONE;
                end

                else begin
                    load_key_and_state     = 0;
                    load_key               = 0;
                    add_rnd_key            = 0;
                    sub_byte               = 0;
                    mix_row                = 0;
                    ks_mix_col             = 0;
                    ks_mix_and_rot         = 0;
                    ks_add_const           = 0;
                    rst                    = 0;
                    out                    = 1;     
                    next_state             = OUT;
                end
            end

            DONE: begin
                load_key_and_state     = 0;
                load_key               = 0;
                add_rnd_key            = 0;
                sub_byte               = 0;
                mix_row                = 0;
                ks_mix_col             = 0;
                ks_mix_and_rot         = 0;
                ks_add_const           = 0;
                rst                    = 0;
                out                    = 0; 
                next_state             = IDLE;
            end

        endcase
    end


    //==============================================================================
    //=== Data path logic
    //==============================================================================

    // state reg.
    always@(posedge clk) begin
        if(!reset_n) begin
            state <= 96'b0;
            round_count <= 4'b0;
        end
        
        // Reset pyjamask rounds
        if(rst) begin
            round_count <= 4'b0;
        end

        // Add Round Key
        if(add_rnd_key) begin
            state <= state ^ key_state[0:95];
        end

        // Load state
        else if(load_key_and_state) begin
            state <= (state << 8) | byte_in;
        end

        // SubByte
        else if(sub_byte) begin
            state <= sub_bytes_96(state);
        end

        // Mixrows
        else if(mix_row) begin
            state[0:31] <= mat_mult(`COL_M0, state[0:31]);
            state[32:63] <= mat_mult(`COL_M1, state[32:63]);
            state[64:95] <= mat_mult(`COL_M2, state[64:95]);

            round_count <= round_count + 1;
        end
    end


    // pyjamask round ctrl.
    always@(posedge clk or negedge reset_n) begin
        if(!reset_n) begin
            byte_count <= 5'b0;
            valid <= 0;
        end

        // Reset rounds
        if(rst) begin
            byte_count <= 5'b0;
            valid <= 0;
        end

        else if(load_key) begin
            byte_count <= byte_count + 1;
        end

        else if(load_key_and_state) begin
            byte_count <= byte_count + 1;
        end

        // Pyjamask output
        else if(out) begin
            valid <= 1;
            byte_out <= state >> (8*byte_count);
            byte_count <= byte_count + 1;
        end
    end

          
    // SubByte
    function [0:95] sub_bytes_96 (input [0:95] state);
        reg [0:31] s0, s1, s2;

        begin
            // Split the state in rows
            s0 = state[0:31];
            s1 = state[32:63];
            s2 = state[64:95];

            s0 = s0 ^ s1;
            s1 = s1 ^ s2;
            s2 = s2 ^ (s0 & s1);
            s0 = s0 ^ (s1 & s2);
            s1 = s1 ^ (s0 & s2);
            s2 = s2 ^ s0;
            s0 = s0 ^ s1;
            s2 = ~s2;

            // Swap s0 <-> s1
            s0 = s0 ^ s1;
            s1 = s1 ^ s0;
            s0 = s0 ^ s1;

            sub_bytes_96 = {s0, s1, s2};
        end
    endfunction


    // Matrix-Multiplcation
    function [0:31] mat_mult (input [0:31] mat_col, input [0:31] vec);
        integer i;
        reg [0:31] mask, res, tmp_mat_col;
        begin
            mask = 32'b0;
            res = 32'b0;
            tmp_mat_col = mat_col;

            for(i=31; i>=0; i=i-1) begin
                mask = -((vec >> i) & 1);
                res = res ^ (mask & tmp_mat_col);
                tmp_mat_col = {tmp_mat_col[31], tmp_mat_col[0:30]};
            end

            mat_mult = res;
        end
    endfunction


    //==============================================================================
    //=== Key schedule
    //==============================================================================

    // key state reg.
    always@(posedge clk or negedge reset_n) begin
        if(!reset_n) begin
            key_state <= 128'b0;
        end

        // Load key
        else if(load_key_and_state) begin
            key_state <= (key_state << 8) | byte_key_in;
        end

        else if(load_key) begin
            key_state <= (key_state << 8) | byte_key_in;
        end

        // Key mix cols.
        else if(ks_mix_col) begin
            key_state <= ks_mix_columns(key_state);
        end

        // Key mix and rotate rows
        else if(ks_mix_and_rot) begin
            key_state <= ks_mix_and_rotate_rows(key_state);
        end

        // Key add const.
        else if(ks_add_const) begin
            key_state <= ks_add_constant(key_state, round_count);
        end
    end

    // MixColumns
    function [0:127] ks_mix_columns (input [0:127] key_state);
        reg [0:127] temp;
        reg [0:31] k0, k1, k2, k3;
        begin
            k0 = key_state[0:31];
            k1 = key_state[32:63];
            k2 = key_state[64:95];
            k3 = key_state[96:127];

            temp = k0 ^ k1 ^ k2 ^ k3;

            k0 = k0 ^ temp;
            k1 = k1 ^ temp;
            k2 = k2 ^ temp;
            k3 = k3 ^ temp;

            ks_mix_columns = {k0, k1, k2, k3};
        end
    endfunction

    // MixAndRotateRows
    function [0:127] ks_mix_and_rotate_rows(input [0:127] key_state);
        reg [0:31] k0, k1, k2, k3;
        begin

            k0 = key_state[0:31];
            k1 = key_state[32:63];
            k2 = key_state[64:95];
            k3 = key_state[96:127];

            k0 = mat_mult(`COL_MK, k0);

            // Left rotate
            k1 = (k1 >> `KS_ROT_GAP1) | (k1 << (32 - `KS_ROT_GAP1));
            k2 = (k2 >> `KS_ROT_GAP2) | (k2 << (32 - `KS_ROT_GAP2));
            k3 = (k3 >> `KS_ROT_GAP3) | (k3 << (32 - `KS_ROT_GAP3));

            ks_mix_and_rotate_rows = {k0 ,k1, k2, k3};
        end
    endfunction

    // AddConstant
    function [0:127] ks_add_constant( input [0:127] key_state, input[3:0] ctr);
        reg [0:31] k0, k1, k2, k3;
        begin

            k0 = key_state[0:31];
            k1 = key_state[32:63];
            k2 = key_state[64:95];
            k3 = key_state[96:127];

            k0 = k0 ^ `KS_CONSTANT_0 ^ ctr;
            k1 = k1 ^ `KS_CONSTANT_1;
            k2 = k2 ^ `KS_CONSTANT_2;
            k3 = k3 ^ `KS_CONSTANT_3;

            ks_add_constant = {k0, k1, k2, k3};
        end
    endfunction
endmodule