`define NUM_ROUNDS 14

module pyjamask96(
    input clk,
    input reset_n,
    input load,
    input load_key,
    input load_state,
    input start,
    input [7:0] byte_in,
    input [7:0] byte_key_in,
    output reg valid,
    output reg [7:0] byte_out 
    );

    // FSM states
    localparam [2:0]  
        IDLE =              3'b000,
        LOAD_KEY =          3'b001,
        PYJAMASK_RND =      3'b010,
        FINAL_RND =         3'b011,
        OUT =               3'b100,
        DONE =              3'b101;

    // Store state and keystate
    reg [95:0] state;
    reg [127:0] key_state;
    reg [3:0] round_cnt;

    // State vectors
    reg [2:0] curr_state, next_state;

    // Control signals
    reg rnds_done;



    // State transition
    always @(posedge clk or posedge reset_n) begin
        if(!reset_n) curr_state <= IDLE;
        else curr_state <= next_state;       
    end

    // Control path logic
    always@(*) begin
        case(curr_state)
            IDLE: begin
                if(load) next_state <= LOAD_KEY;
                else next_state <= IDLE;
            end

            LOAD_KEY: begin
                if(start) next_state <= PYJAMASK_RND;
                else next_state <= LOAD_KEY;
            end

            PYJAMASK_RND: begin
                if(rnds_done) next_state <= FINAL_RND;
            end


        endcase
    end


    // Data path logic
    
    // Load state
    always@(posedge clk or negedge reset_n) begin
        if(!reset_n) begin
            state <= 96'b0;
        end

        else begin
            if(load_state) begin
                state <= (state << 8) | byte_in;
            end
        end
    end

    // Load key
    always@(posedge clk or negedge reset_n) begin
        if(!reset_n) begin
            key_state <= 128'b0;
        end

        else begin
            if(load_key) begin
                key_state <= (key_state << 8) | byte_key_in;
            end
        end
    end    




endmodule