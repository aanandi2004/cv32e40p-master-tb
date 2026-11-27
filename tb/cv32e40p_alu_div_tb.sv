module cv32e40p_alu_div_tb;

    // Clock and reset
    logic Clk_CI;
    logic Rst_RBI;

    // DUT inputs
    logic [31:0] OpA_DI;        // dividend (A)
    logic [31:0] OpB_DI;        // divisor (B), already shifted left
    logic [ 5:0] OpBShift_DI;
    logic        OpBIsZero_SI;
    logic        OpBSign_SI;
    logic [ 1:0] OpCode_SI;     // 00=DIVU, 01=DIV, 10=REMU, 11=REM
    logic        InVld_SI;
    logic        OutRdy_SI;

    // DUT outputs
    logic        OutVld_SO;
    logic [31:0] Res_DO;

    cv32e40p_alu_div uut (
        .Clk_CI      (Clk_CI),
        .Rst_RBI     (Rst_RBI),
        .OpA_DI      (OpA_DI),
        .OpB_DI      (OpB_DI),
        .OpBShift_DI (OpBShift_DI),
        .OpBIsZero_SI(OpBIsZero_SI),
        .OpBSign_SI  (OpBSign_SI),
        .OpCode_SI   (OpCode_SI),
        .InVld_SI    (InVld_SI),
        .OutRdy_SI   (OutRdy_SI),
        .OutVld_SO   (OutVld_SO),
        .Res_DO      (Res_DO)
    );

    // Clock: period = 20
    initial Clk_CI = 0;
    always #10 Clk_CI = ~Clk_CI;

    // Ye variables har test me sirf EK baar update hote hain,
    // isliye $monitor har test ki sirf ek line print karta hai.
    integer           test_no    = 0;
    integer           pass_count = 0;
    integer           fail_count = 0;
    reg [8*4-1:0]     m_op;
    reg signed [31:0] m_a, m_b, m_result, m_expected;
    reg [8*4-1:0]     m_status;

    // ALU.sv me jo shift (FF1 logic) banta hai, wahi yahan calculate hota hai.
    // Positive/unsigned B : shift = leading zeros ki ginti
    // Negative signed B   : shift = leading ones ki ginti - 1
    function automatic [5:0] get_shift(input [31:0] b, input negative);
        integer i, count;
        begin
            count = 0;
            i     = 31;
            while (i >= 0 && b[i] == negative) begin
                count = count + 1;
                i     = i - 1;
            end
            get_shift = negative ? count - 1 : count;
        end
    endfunction

    // Ek test case chalata hai: A / B  ya  A % B
    task run_test(input [1:0] op, input [31:0] a, input [31:0] b,
                  input [31:0] expected);
        begin
            // 1. inputs do (negative edge par)
            @(negedge Clk_CI);
            OpCode_SI    = op;
            OpA_DI       = a;
            OpBSign_SI   = op[0] & b[31];          // sirf signed op me
            OpBShift_DI  = get_shift(b, op[0] & b[31]);
            OpB_DI       = b << OpBShift_DI;
            OpBIsZero_SI = (b == 0);
            InVld_SI     = 1;

            // 2. ek clock ke baad InVld band
            @(negedge Clk_CI);
            InVld_SI = 0;

            // 3. result ready hone ka wait
            while (OutVld_SO !== 1'b1) @(negedge Clk_CI);

            // 4. compare karo
            test_no = test_no + 1;
            case (op)
                2'b00: m_op = "DIVU";
                2'b01: m_op = "DIV";
                2'b10: m_op = "REMU";
                2'b11: m_op = "REM";
            endcase
            m_a        = a;
            m_b        = b;
            m_result   = Res_DO;
            m_expected = expected;

            if (Res_DO === expected) begin
                m_status   = "PASS";
                pass_count = pass_count + 1;
            end else begin
                m_status   = "FAIL";
                fail_count = fail_count + 1;
            end

            // pehle test par monitor start karo (extra line nahi aayegi)
            if (test_no == 1)
                $monitor("Test %2d | %s | A=%0d | B=%0d | Result=%0d | Expected=%0d | %s",
                         test_no, m_op, m_a, m_b, m_result, m_expected, m_status);

            // 5. result accept karo, divider wapas IDLE me jayega
            OutRdy_SI = 1;
            @(negedge Clk_CI);
            OutRdy_SI = 0;
        end
    endtask

    initial begin
        // Reset
        Rst_RBI      = 0;
        InVld_SI     = 0;
        OutRdy_SI    = 0;
        OpA_DI       = 0;
        OpB_DI       = 0;
        OpBShift_DI  = 0;
        OpBIsZero_SI = 0;
        OpBSign_SI   = 0;
        OpCode_SI    = 0;
        repeat (2) @(negedge Clk_CI);
        Rst_RBI = 1;

        //            opcode      A        B      expected
        // ---------- 10 NORMAL CASES ----------
        run_test(2'b00,    20,      5,        4);   //  1
        run_test(2'b00,   100,     10,       10);   //  2
        run_test(2'b00,    27,      4,        6);   //  3
        run_test(2'b00,     5,     20,        0);   //  4  A < B
        run_test(2'b10,    23,      5,        3);   //  5
        run_test(2'b10,   100,      7,        2);   //  6
        run_test(2'b01,    50,      5,       10);   //  7
        run_test(2'b01,   -40,      8,       -5);   //  8
        run_test(2'b11,    29,      6,        5);   //  9
        run_test(2'b11,   -23,      5,       -3);   // 10

        // ---------- 10 EDGE CASES ----------
        run_test(2'b01,     0,      0,       -1);   // 11  A=0, B=0
        run_test(2'b01,     0,      5,        0);   // 12  A=0
        run_test(2'b01,    20,      0,       -1);   // 13  B=0
        run_test(2'b01,   100,     20,        5);   // 14  A +ve, B +ve
        run_test(2'b01,  -100,    -20,        5);   // 15  A -ve, B -ve
        run_test(2'b01,  -100,     20,       -5);   // 16  A -ve, B +ve
        run_test(2'b01,   100,    -20,       -5);   // 17  A +ve, B -ve
        run_test(2'b11,    20,      0,       20);   // 18  remainder, B=0
        run_test(2'b11,   -23,     -5,       -3);   // 19  remainder, dono -ve
        run_test(2'b01, 32'h8000_0000, -1, 32'h8000_0000); // 20  overflow

        #1;
        $display("TOTAL=%0d  PASS=%0d  FAIL=%0d", test_no, pass_count, fail_count);
        $finish(0);
    end

    // Safety: agar DUT atak jaye to simulation band ho
    initial begin
        #100000;
        $display("TIMEOUT: OutVld nahi aaya");
        $finish(0);
    end

    // Waveform chahiye to compile me -DDUMP lagao
`ifdef DUMP
    initial begin
        $dumpfile("top_sim.vcd");
        $dumpvars(0, cv32e40p_alu_div_tb);
    end
`endif

endmodule
