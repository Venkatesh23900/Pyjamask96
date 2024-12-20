//`include"src/rtl/pyjamask96.v"
`timescale 1ns/1ps

module tb_pyjamask96;

    parameter CLOCK_PERIOD = 8;

    // Inputs
    reg clk;
    reg reset_n;
    reg load;
    reg start;
    reg [7:0] byte_in;
    reg [7:0] byte_key_in;

    // Outputs
    wire valid;
    wire [7:0] byte_out;

    // Instantiate the Unit Under Test (UUT)
    pyjamask96 dut (
        .clk(clk),
        .reset_n(reset_n),
        .load(load),
        .start(start),
        .byte_in(byte_in),
        .byte_key_in(byte_key_in),
        .valid(valid),
        .byte_out(byte_out)
    );

    // Test vectors
    reg [95:0] test_state;
    reg [127:0] test_key;
    reg [95:0] test_exp;
    integer i;

    reg [95:0] temp_state;
    reg [127:0] temp_key;

    // Actual output
    reg [95:0] out_fifo;
    reg [3:0]   cnt_out;
    integer j = 0;

    // Test
    initial begin

        //TEST VECTOR INPUT
        /* Pyjamask -96 */
        // Key:        00 11 22 33 44 55 66 77 88 99 aa bb cc dd ee ff
        // Plaintext:  50 79 6a 61 6d 61 73 6b 39 36 3a 29
        // Ciphertext: ca 9c 6e 1a bb de 4e dc 27 07 3d a6

        test_key =   128'h00_11_22_33_44_55_66_77_88_99_aa_bb_cc_dd_ee_ff;
        test_state =  96'h50_79_6a_61_6d_61_73_6b_39_36_3a_29;
        test_exp =    96'hca_9c_6e_1a_bb_de_4e_dc_27_07_3d_a6;

        // Initialize inputs
        clk = 0;
        reset_n = 1;
        load = 0;
        start = 0;
        byte_in = 0;
        byte_key_in = 0;
        temp_state = 0;
        temp_key = 0;

        // Reset
        #(CLOCK_PERIOD*5);
        reset_n = 0;

        #(CLOCK_PERIOD*5);
        reset_n = 1;

        #(CLOCK_PERIOD*3);

        // Main test loop
        for(i=0; i<16; i=i+1) begin
            
            load = 1;

            if(i <= 11) begin
                temp_key = test_key << 8*i;
                temp_state = test_state << 8*i;
                byte_in = temp_state[95:88];
                byte_key_in = temp_key[127:120];
            end

            else begin
                temp_key = test_key << 8*i;
                byte_key_in = temp_key[127:120];
            end

            #(CLOCK_PERIOD);
        end

        load = 0;
        #(CLOCK_PERIOD);

        start=1;
        #(CLOCK_PERIOD*2);
        start=0;

        #(CLOCK_PERIOD*69); // Aha!, the funny number

        // Compare out_fifo with the expected ciphertext
        if (out_fifo == test_exp)
            $display("TEST VECTOR PASSED: Ciphertext matches expected output.");
        else begin
            $display("TEST VECTOR FAILED: Ciphertext does not match expected output.");
            $display("Expected: %h, Got: %h", test_exp, out_fifo);
        end

        $stop;
    end

    // Generate clock
    always #(CLOCK_PERIOD/2) clk = ~clk;

    // Check if output matches the expected one
    always @ (posedge clk or posedge reset_n)
    begin
        if (!reset_n)
        begin
            cnt_out <= 0;
            out_fifo <= 0;
        end

        else if (valid)
        begin
            cnt_out <= cnt_out + 1;
            out_fifo[8*j +: 8] <= byte_out;
            j = j + 1;
        end

        else if (cnt_out == 12)
            cnt_out <= 0;
    end

    initial begin
      $dumpfile("dump.vcd");
      $dumpvars(0, tb_pyjamask96);
    end
endmodule
