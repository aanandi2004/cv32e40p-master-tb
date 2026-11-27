module cv32e40p_alu_tb;
    import cv32e40p_pkg::*;

    // vector modes
    localparam [1:0] V32 = 2'b00, V16 = 2'b10, V8 = 2'b11;

    // ---------------- DUT inputs ----------------
    logic        clk;
    logic        rst_n;
    logic        enable_i;
    alu_opcode_e operator_i;
    logic [31:0] operand_a_i, operand_b_i, operand_c_i;
    logic [ 1:0] vector_mode_i;
    logic [ 4:0] bmask_a_i, bmask_b_i;
    logic [ 1:0] imm_vec_ext_i;
    logic        is_clpx_i, is_subrot_i;
    logic [ 1:0] clpx_shift_i;
    logic        ex_ready_i;

    // ---------------- DUT outputs ----------------
    logic [31:0] result_o;
    logic        comparison_result_o;
    logic        ready_o;

    cv32e40p_alu uut (
        .clk                (clk),
        .rst_n              (rst_n),
        .enable_i           (enable_i),
        .operator_i         (operator_i),
        .operand_a_i        (operand_a_i),
        .operand_b_i        (operand_b_i),
        .operand_c_i        (operand_c_i),
        .vector_mode_i      (vector_mode_i),
        .bmask_a_i          (bmask_a_i),
        .bmask_b_i          (bmask_b_i),
        .imm_vec_ext_i      (imm_vec_ext_i),
        .is_clpx_i          (is_clpx_i),
        .is_subrot_i        (is_subrot_i),
        .clpx_shift_i       (clpx_shift_i),
        .result_o           (result_o),
        .comparison_result_o(comparison_result_o),
        .ready_o            (ready_o),
        .ex_ready_i         (ex_ready_i)
    );

    // Clock: period = 20 (sirf divider ko chahiye)
    initial clk = 0;
    always #10 clk = ~clk;

    // ---------------- Monitor variables ----------------
    // Ye har test me sirf EK baar update hote hain => ek test, ek line
    integer       test_no    = 0;
    integer       pass_count = 0;
    integer       fail_count = 0;
    reg [8*10-1:0] m_name;
    reg [31:0]     m_a, m_b, m_c, m_result, m_expected;
    reg [8*8-1:0]  m_status;

    // Control signals ko default par le aao
    task clear_controls;
        begin
            vector_mode_i = V32;
            bmask_a_i     = 0;
            bmask_b_i     = 0;
            imm_vec_ext_i = 0;
            is_clpx_i     = 0;
            is_subrot_i   = 0;
            clpx_shift_i  = 0;
        end
    endtask

    // Compare operations me comparison_result_o bhi check hota hai
    function automatic cmp_check(input alu_opcode_e op, input [31:0] expected);
        case (op)
            ALU_EQ, ALU_NE, ALU_GTS, ALU_GTU, ALU_GES, ALU_GEU,
            ALU_LTS, ALU_LTU, ALU_LES, ALU_LEU:
                cmp_check = (comparison_result_o === expected[31]);
            ALU_SLTS, ALU_SLTU, ALU_SLETS, ALU_SLETU:
                cmp_check = (comparison_result_o === expected[0]);
            default:
                cmp_check = 1'b1;
        endcase
    endfunction

    // ---------------- Ek test case ----------------
    task run_test(input [8*10-1:0] name, input alu_opcode_e op,
                  input [31:0] a, input [31:0] b, input [31:0] c,
                  input [31:0] expected);
        begin
            // 1. inputs do
            operator_i  = op;
            operand_a_i = a;
            operand_b_i = b;
            operand_c_i = c;
            enable_i    = 1;

            // 2. result ready hone tak wait
            //    (normal ops: 1 clock, DIV/REM: kai clocks)
            @(negedge clk);
            while (ready_o !== 1'b1) @(negedge clk);

            // 3. data save karo
            test_no    = test_no + 1;
            m_name     = name;
            m_a        = a;
            m_b        = b;
            m_c        = c;
            m_result   = result_o;
            m_expected = expected;

            // 4. PASS / FAIL
            if (result_o !== expected) begin
                m_status   = "FAIL";
                fail_count = fail_count + 1;
            end else if (!cmp_check(op, expected)) begin
                m_status   = "FAIL_CMP";
                fail_count = fail_count + 1;
            end else begin
                m_status   = "PASS";
                pass_count = pass_count + 1;
            end

            // monitor pehle test par start hota hai
            if (test_no == 1)
                $monitor("Test %3d | %s | A=%h | B=%h | C=%h | Result=%h | Expected=%h | %0s",
                         test_no, m_name, m_a, m_b, m_c, m_result, m_expected, m_status);

            // 5. agle test ke liye tayyar
            enable_i = 0;
            @(negedge clk);
            clear_controls;
        end
    endtask

    initial begin
        // Reset
        rst_n       = 0;
        enable_i    = 0;
        ex_ready_i  = 1;
        operator_i  = ALU_ADD;
        operand_a_i = 0;
        operand_b_i = 0;
        operand_c_i = 0;
        clear_controls;
        repeat (2) @(negedge clk);
        rst_n = 1;
        @(negedge clk);

        //        name        opcode     A             B             C             Expected

        // ===== A. ADD / SUBTRACT =====
        run_test("ADD",       ALU_ADD,   32'd25,       32'd17,       0,            32'd42);
        run_test("ADD_WRAP",  ALU_ADD,   32'hFFFFFFFF, 32'd1,        0,            32'h00000000);
        run_test("ADD_OVF",   ALU_ADD,   32'h7FFFFFFF, 32'd1,        0,            32'h80000000);
        run_test("SUB",       ALU_SUB,   32'd40,       32'd25,       0,            32'd15);
        run_test("SUB_NEG",   ALU_SUB,   32'd25,       32'd40,       0,            -32'd15);
        vector_mode_i = V16;
        run_test("ADD_16",    ALU_ADD,   32'h0001FFFF, 32'h00010001, 0,            32'h00020000);
        vector_mode_i = V8;
        run_test("ADD_8",     ALU_ADD,   32'h01FF7F10, 32'h01010101, 0,            32'h02008011);
        vector_mode_i = V16;
        run_test("SUB_16",    ALU_SUB,   32'h00050000, 32'h00010001, 0,            32'h0004FFFF);
        vector_mode_i = V8;
        run_test("SUB_8",     ALU_SUB,   32'h05000A10, 32'h01010101, 0,            32'h04FF090F);
        // normalization: bmask_b = shift amount
        bmask_b_i = 2;
        run_test("ADD_N2",    ALU_ADD,   32'd100,      32'd60,       0,            32'd40);
        bmask_b_i = 4;
        run_test("ADD_N4",    ALU_ADD,   32'hFFFFFFF0, 32'd0,        0,            32'hFFFFFFFF);
        bmask_b_i = 4;
        run_test("ADDU_N4",   ALU_ADDU,  32'hFFFFFFF0, 32'd0,        0,            32'h0FFFFFFF);
        bmask_b_i = 2;
        run_test("SUBU_N2",   ALU_SUBU,  32'd100,      32'd36,       0,            32'd16);
        bmask_b_i = 2;
        run_test("ADDR_N2",   ALU_ADDR,  32'd100,      32'd63,       0,            32'd41);
        bmask_b_i = 2;
        run_test("SUBR_N2",   ALU_SUBR,  32'd0,        32'd103,      0,            32'hFFFFFFE6);
        bmask_b_i = 2;
        run_test("ADDUR_N2",  ALU_ADDUR, 32'd103,      32'd0,        0,            32'd26);
        bmask_b_i = 2;
        run_test("SUBUR_N2",  ALU_SUBUR, 32'd0,        32'd103,      0,            32'h3FFFFFE6);

        // ===== B. LOGICAL =====
        run_test("AND",       ALU_AND,   32'h0000F0F0, 32'h00000FF0, 0,            32'h000000F0);
        run_test("OR",        ALU_OR,    32'h0000F0F0, 32'h00000FF0, 0,            32'h0000FFF0);
        run_test("XOR",       ALU_XOR,   32'h0000F0F0, 32'h00000FF0, 0,            32'h0000FF00);
        run_test("AND_ZERO",  ALU_AND,   32'hA5A5A5A5, 32'h5A5A5A5A, 0,            32'h00000000);
        run_test("OR_ALL1",   ALU_OR,    32'hA5A5A5A5, 32'h5A5A5A5A, 0,            32'hFFFFFFFF);
        run_test("XOR_INV",   ALU_XOR,   32'hA5A5A5A5, 32'hFFFFFFFF, 0,            32'h5A5A5A5A);

        // ===== C. SHIFT / ROTATE =====  (A = data, B = shift amount)
        run_test("SLL",       ALU_SLL,   32'h0000000F, 32'd4,        0,            32'h000000F0);
        run_test("SLL_31",    ALU_SLL,   32'h00000001, 32'd31,       0,            32'h80000000);
        run_test("SLL_32",    ALU_SLL,   32'h00000001, 32'd32,       0,            32'h00000001);
        run_test("SRL",       ALU_SRL,   32'h80000000, 32'd4,        0,            32'h08000000);
        run_test("SRA_NEG",   ALU_SRA,   32'h80000000, 32'd4,        0,            32'hF8000000);
        run_test("SRA_POS",   ALU_SRA,   32'h7FFFFFFF, 32'd4,        0,            32'h07FFFFFF);
        run_test("ROR",       ALU_ROR,   32'h1234567F, 32'd8,        0,            32'h7F123456);
        run_test("ROR_0",     ALU_ROR,   32'h1234567F, 32'd0,        0,            32'h1234567F);
        vector_mode_i = V16;
        run_test("SLL_16",    ALU_SLL,   32'h00010001, 32'h00040001, 0,            32'h00100002);
        vector_mode_i = V16;
        run_test("SRL_16",    ALU_SRL,   32'h80008000, 32'h00040001, 0,            32'h08004000);
        vector_mode_i = V8;
        run_test("SRA_8",     ALU_SRA,   32'h80808080, 32'h01020304, 0,            32'hC0E0F0F8);

        // ===== D. COMPARE =====  (true = FFFFFFFF, false = 0)
        run_test("EQ_T",      ALU_EQ,    32'd5,        32'd5,        0,            32'hFFFFFFFF);
        run_test("EQ_F",      ALU_EQ,    32'd5,        32'd6,        0,            32'h00000000);
        run_test("NE_T",      ALU_NE,    32'd5,        32'd6,        0,            32'hFFFFFFFF);
        run_test("NE_F",      ALU_NE,    32'd5,        32'd5,        0,            32'h00000000);
        run_test("GTS",       ALU_GTS,   32'hFFFFFFFF, 32'd1,        0,            32'h00000000);
        run_test("GTU",       ALU_GTU,   32'hFFFFFFFF, 32'd1,        0,            32'hFFFFFFFF);
        run_test("LTS",       ALU_LTS,   32'hFFFFFFFF, 32'd1,        0,            32'hFFFFFFFF);
        run_test("LTU",       ALU_LTU,   32'hFFFFFFFF, 32'd1,        0,            32'h00000000);
        run_test("GES",       ALU_GES,   32'd7,        32'd7,        0,            32'hFFFFFFFF);
        run_test("GEU",       ALU_GEU,   32'd6,        32'd7,        0,            32'h00000000);
        run_test("LES",       ALU_LES,   32'd7,        32'd7,        0,            32'hFFFFFFFF);
        run_test("LEU",       ALU_LEU,   32'd8,        32'd7,        0,            32'h00000000);
        vector_mode_i = V8;
        run_test("EQ_8",      ALU_EQ,    32'h11223344, 32'h11003300, 0,            32'hFF00FF00);
        vector_mode_i = V16;
        run_test("GTS_16",    ALU_GTS,   32'h0005FFFF, 32'h00010001, 0,            32'hFFFF0000);

        // ===== E. SET IF LESS =====  (result = 1 ya 0)
        run_test("SLTS",      ALU_SLTS,  32'hFFFFFFFF, 32'd1,        0,            32'd1);
        run_test("SLTU",      ALU_SLTU,  32'hFFFFFFFF, 32'd1,        0,            32'd0);
        run_test("SLETS",     ALU_SLETS, 32'd3,        32'd3,        0,            32'd1);
        run_test("SLETU",     ALU_SLETU, 32'd4,        32'd3,        0,            32'd0);

        // ===== F. MIN / MAX =====
        run_test("MIN",       ALU_MIN,   -32'd5,       32'd3,        0,            -32'd5);
        run_test("MINU",      ALU_MINU,  -32'd5,       32'd3,        0,            32'd3);
        run_test("MAX",       ALU_MAX,   -32'd5,       32'd3,        0,            32'd3);
        run_test("MAXU",      ALU_MAXU,  -32'd5,       32'd3,        0,            -32'd5);
        vector_mode_i = V16;
        run_test("MIN_16",    ALU_MIN,   32'h0005FFFF, 32'h00010001, 0,            32'h0001FFFF);
        vector_mode_i = V8;
        run_test("MAX_8",     ALU_MAX,   32'h01FF7F80, 32'h02017E7F, 0,            32'h02017F7F);

        // ===== G. ABS / CLIP =====  (ABS me B = 0 zaroori; CLIP me B = limit)
        run_test("ABS_NEG",   ALU_ABS,   -32'd25,      32'd0,        0,            32'd25);
        run_test("ABS_POS",   ALU_ABS,   32'd25,       32'd0,        0,            32'd25);
        run_test("ABS_MIN",   ALU_ABS,   32'h80000000, 32'd0,        0,            32'h80000000);
        vector_mode_i = V16;
        run_test("ABS_16",    ALU_ABS,   32'hFFFF0005, 32'd0,        0,            32'h00010005);
        run_test("CLIP_HI",   ALU_CLIP,  32'd200,      32'd127,      0,            32'd127);
        run_test("CLIP_LO",   ALU_CLIP,  -32'd200,     32'd127,      0,            -32'd128);
        run_test("CLIP_IN",   ALU_CLIP,  32'd50,       32'd127,      0,            32'd50);
        run_test("CLIPU_HI",  ALU_CLIPU, 32'd200,      32'd127,      0,            32'd127);
        run_test("CLIPU_NEG", ALU_CLIPU, -32'd5,       32'd127,      0,            32'd0);
        run_test("CLIPU_IN",  ALU_CLIPU, 32'd50,       32'd127,      0,            32'd50);

        // ===== H. BIT MANIPULATION =====  (width = bmask_a + 1, position = bmask_b)
        bmask_a_i = 7;
        run_test("BEXT_NEG",  ALU_BEXT,  32'h00000AB0, 32'd4,        0,            32'hFFFFFFAB);
        bmask_a_i = 7;
        run_test("BEXT_POS",  ALU_BEXT,  32'h000007B0, 32'd4,        0,            32'h0000007B);
        bmask_a_i = 7;
        run_test("BEXTU",     ALU_BEXTU, 32'h00000AB0, 32'd4,        0,            32'h000000AB);
        bmask_a_i = 7;  bmask_b_i = 8;
        run_test("BINS",      ALU_BINS,  32'h000000AB, 32'd8,        32'h11111111, 32'h1111AB11);
        bmask_a_i = 7;  bmask_b_i = 8;
        run_test("BCLR",      ALU_BCLR,  32'hFFFFFFFF, 32'd0,        0,            32'hFFFF00FF);
        bmask_a_i = 7;  bmask_b_i = 8;
        run_test("BSET",      ALU_BSET,  32'h00000000, 32'd0,        0,            32'h0000FF00);
        bmask_a_i = 0;   // radix-2
        run_test("BREV_R2",   ALU_BREV,  32'h00000001, 32'd0,        0,            32'h80000000);
        bmask_a_i = 1;   // radix-4
        run_test("BREV_R4",   ALU_BREV,  32'h00000001, 32'd0,        0,            32'h40000000);
        bmask_a_i = 2;   // radix-8
        run_test("BREV_R8",   ALU_BREV,  32'h00000004, 32'd0,        0,            32'h08000000);
        run_test("BREV_SH",   ALU_BREV,  32'h00000001, 32'd4,        0,            32'h08000000);

        // ===== I. BIT COUNTING =====
        run_test("FF1",       ALU_FF1,   32'h00000F00, 0,            0,            32'd8);
        run_test("FF1_ZERO",  ALU_FF1,   32'h00000000, 0,            0,            32'd32);
        run_test("FL1",       ALU_FL1,   32'h00000F00, 0,            0,            32'd11);
        run_test("FL1_ZERO",  ALU_FL1,   32'h00000000, 0,            0,            32'd32);
        run_test("CNT",       ALU_CNT,   32'h00000F00, 0,            0,            32'd4);
        run_test("CNT_ALL1",  ALU_CNT,   32'hFFFFFFFF, 0,            0,            32'd32);
        run_test("CLB_POS",   ALU_CLB,   32'h00000F00, 0,            0,            32'd19);
        run_test("CLB_NEG",   ALU_CLB,   32'hFFFFF000, 0,            0,            32'd19);
        run_test("CLB_ZERO",  ALU_CLB,   32'h00000000, 0,            0,            32'd0);
        run_test("CLB_ALL1",  ALU_CLB,   32'hFFFFFFFF, 0,            0,            32'd31);

        // ===== J. EXTRACT / INSERT =====  (imm_vec_ext = byte/halfword number)
        vector_mode_i = V8;   imm_vec_ext_i = 1;
        run_test("EXTS_8",    ALU_EXTS,  32'h12348056, 0,            0,            32'hFFFFFF80);
        vector_mode_i = V8;   imm_vec_ext_i = 1;
        run_test("EXT_8",     ALU_EXT,   32'h12348056, 0,            0,            32'h00000080);
        vector_mode_i = V16;  imm_vec_ext_i = 0;
        run_test("EXTS_16",   ALU_EXTS,  32'h12348056, 0,            0,            32'hFFFF8056);
        vector_mode_i = V16;  imm_vec_ext_i = 1;
        run_test("EXT_16",    ALU_EXT,   32'h12348056, 0,            0,            32'h00001234);
        vector_mode_i = V8;   imm_vec_ext_i = 2;
        run_test("INS_8",     ALU_INS,   32'h000000AA, 0,            32'h11223344, 32'h11AA3344);
        vector_mode_i = V16;  imm_vec_ext_i = 1;
        run_test("INS_16",    ALU_INS,   32'h0000BEEF, 0,            32'h11223344, 32'hBEEF3344);

        // ===== K. PACK / SHUFFLE =====
        vector_mode_i = V16;
        run_test("PCKLO_16",  ALU_PCKLO, 32'hAAAA1111, 32'hBBBB2222, 0,            32'h11112222);
        vector_mode_i = V16;
        run_test("PCKHI_16",  ALU_PCKHI, 32'hAAAA1111, 32'hBBBB2222, 0,            32'hAAAABBBB);
        vector_mode_i = V8;
        run_test("PCKLO_8",   ALU_PCKLO, 32'h000000AA, 32'h000000BB, 32'h11223344, 32'h1122AABB);
        vector_mode_i = V8;
        run_test("PCKHI_8",   ALU_PCKHI, 32'h000000AA, 32'h000000BB, 32'h11223344, 32'hAABB3344);
        vector_mode_i = V8;
        run_test("SHUF_8",    ALU_SHUF,  32'h44332211, 32'h00010203, 0,            32'h11223344);
        vector_mode_i = V16;
        run_test("SHUF_16",   ALU_SHUF,  32'hBBBBAAAA, 32'h00000001, 0,            32'hAAAABBBB);
        vector_mode_i = V8;
        run_test("SHUF2_8",   ALU_SHUF2, 32'h44332211, 32'h04000501, 32'hDDCCBBAA, 32'h11AA22BB);
        vector_mode_i = V16;
        run_test("SHUF2_16",  ALU_SHUF2, 32'hBBBBAAAA, 32'h00020001, 32'hDDDDCCCC, 32'hAAAADDDD);

        // ===== COMPLEX NUMBER MODES =====  (upper = imaginary, lower = real)
        vector_mode_i = V16;  is_clpx_i = 1;
        run_test("CPLXCONJ",  ALU_ABS,   32'h00050003, 32'd0,        0,            32'hFFFB0003);
        vector_mode_i = V16;  is_clpx_i = 1;  clpx_shift_i = 1;
        run_test("CADD_DIV2", ALU_ADD,   32'h00080006, 32'h00040002, 0,            32'h00060004);
        vector_mode_i = V16;  is_clpx_i = 1;  clpx_shift_i = 1;
        run_test("CSUB_DIV2", ALU_SUB,   32'h00080006, 32'h00040002, 0,            32'h00020002);
        vector_mode_i = V16;  is_clpx_i = 1;  is_subrot_i = 1;
        run_test("SUBROTMJ",  ALU_SUB,   32'h000A0003, 32'h00040014, 0,            32'h00110006);

        // ===== L. DIVIDE / REMAINDER =====
        // DHYAN: ALU me A = divisor, B = dividend  =>  Result = B / A  ya  B % A
        run_test("DIVU",      ALU_DIVU,  32'd5,        32'd20,       0,            32'd4);
        run_test("DIVU_BIG",  ALU_DIVU,  32'd2,        32'hFFFFFFFF, 0,            32'h7FFFFFFF);
        run_test("DIV_PP",    ALU_DIV,   32'd20,       32'd100,      0,            32'd5);
        run_test("DIV_NN",    ALU_DIV,   -32'd20,      -32'd100,     0,            32'd5);
        run_test("DIV_PN",    ALU_DIV,   32'd20,       -32'd100,     0,            -32'd5);
        run_test("DIV_NP",    ALU_DIV,   -32'd6,       32'd100,      0,            -32'd16);
        run_test("DIV_0BY5",  ALU_DIV,   32'd5,        32'd0,        0,            32'd0);
        run_test("DIV_BY0",   ALU_DIV,   32'd0,        32'd20,       0,            32'hFFFFFFFF);
        run_test("DIV_0BY0",  ALU_DIV,   32'd0,        32'd0,        0,            32'hFFFFFFFF);
        run_test("DIV_OVF",   ALU_DIV,   32'hFFFFFFFF, 32'h80000000, 0,            32'h80000000);
        run_test("REMU",      ALU_REMU,  32'd7,        32'd100,      0,            32'd2);
        run_test("REMU_BY0",  ALU_REMU,  32'd0,        32'd20,       0,            32'd20);
        run_test("REM_NEG",   ALU_REM,   32'd5,        -32'd23,      0,            -32'd3);
        run_test("REM_OVF",   ALU_REM,   32'hFFFFFFFF, 32'h80000000, 0,            32'd0);

        #1;
        $display("TOTAL=%0d  PASS=%0d  FAIL=%0d", test_no, pass_count, fail_count);
        $finish(0);
    end

    // Safety: agar DUT atak jaye to simulation band ho
    initial begin
        #200000;
        $display("TIMEOUT: ready_o nahi aaya (Test %0d ke baad)", test_no);
        $finish(0);
    end

    // Waveform chahiye to compile me -DDUMP lagao
`ifdef DUMP
    initial begin
        $dumpfile("alu_sim.vcd");
        $dumpvars(0, cv32e40p_alu_tb);
    end
`endif

endmodule
