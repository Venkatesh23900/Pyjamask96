//`include"src/rtl/pyjamask96.v"
`timescale 1ns/1ps

module tb_pyjamask96;

    parameter CLOCK_PERIOD = 10;

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

    // Test
    initial begin

        //TEST VECTOR INPUT 0
        test_key = 128'h00112233445566778899aabbccddeeff;
        test_state = 96'h50796a616d61736b39363a29;
        test_exp = 96'hca9c6e1abbde4edc27073da6;

        // Initialize inputs
        clk = 0;
        reset_n = 1;
        load = 0;
        start = 0;
        byte_in = 0;
        byte_key_in = 0;

        // Reset
        #(CLOCK_PERIOD*5);
        reset_n = 0;

        #(CLOCK_PERIOD*5);
        reset_n = 1;

        #(CLOCK_PERIOD*3);

		//main test loop
        for(i=0; i<=15; i=i+1) begin
            
            load = 1;

            if(i <= 11) begin
            byte_key_in = test_key[8*i +: 8];
            byte_in = test_state[8*i +: 8];
            end

            else begin
                byte_key_in = test_key[8*i +: 8];
            end

            #(CLOCK_PERIOD);
        end

        load = 0;
		#(CLOCK_PERIOD);

		start=1;
		#(CLOCK_PERIOD*2);
		start=0;


        $stop;
    end

    //generate clock
	always #(CLOCK_PERIOD/2) clk = ~clk;

    initial begin
      $dumpfile("dump.vcd");
      $dumpvars(0, dut);
    end
endmodule
