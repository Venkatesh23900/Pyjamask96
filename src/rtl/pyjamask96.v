//==============================================================================
//=== Pyjamask-96 Macros
//==============================================================================

`define NB_ROUNDS_96    14

`define COL_M0  32'ha3861085
`define COL_M1  32'h63417021
`define COL_M2  32'h692cf280
`define COL_MK  32'hb881b9ca


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
    reg [95:0] state;
    reg [127:0] key_state;

    // State vectors
    reg [2:0] curr_state, next_state;

    // Control signals
    reg load_key_and_state;
    reg load_key;
    reg [3:0] round_count;
    reg [4:0] byte_count;

    // State transition
    always @(posedge clk or posedge reset_n) begin
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
                    next_state         = LOAD_STATES;
                end
                else begin
                    load_key_and_state = 0;
                    load_key           = 0;                
                    next_state         = IDLE;
                end
            end

            LOAD_STATES: begin
                if(start) begin
                    load_key_and_state = 0;
                    load_key           = 0;
                    next_state         = PYJAMASK_RND;
                end
                else begin
                    load_key_and_state = (byte_count <= 5'hb) ? 1 : 0;
                    load_key           = (byte_count >= 5'hb & byte_count <= 5'h10) ? 1 : 0;                     
                    next_state         = LOAD_STATES;
                end
            end

            PYJAMASK_RND: begin
                next_state             = ADD_RND_KEY;
            end

            ADD_RND_KEY: begin
                next_state             = SUB_BYTES;
            end

            SUB_BYTES: begin
                next_state             = MIX_ROWS;
            end

            MIX_ROWS: begin
                if(round_count == `NB_ROUNDS_96-1) next_state = FINAL_RND;
                else next_state = PYJAMASK_RND;
            end

            FINAL_RND: begin
                next_state             = OUT;
            end


        endcase
    end


    //==============================================================================
    //=== Data path logic
    //==============================================================================
    
    // Load state and key
    always@(posedge clk or negedge reset_n) begin
        if(!reset_n) begin
            state <= 96'b0;
            key_state <= 128'b0;
            byte_count <= 5'b0;
        end

        else begin
            if(load_key_and_state) begin
                state[8*(byte_count) +: 8] <= byte_in;
                key_state[8*(byte_count) +: 8] <= byte_key_in;
                byte_count <= byte_count + 1;
            end

            if(load_key) begin
                key_state[8*(byte_count) +: 8] <= byte_key_in;
                byte_count <= byte_count + 1;
            end
        end
    end



endmodule