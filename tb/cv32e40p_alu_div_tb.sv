
module cv32e40p_alu_div_tb;

    //parameters based on the rtl
    parameter C_WIDTH     = 32;
    parameter C_LOG_WIDTH = 6;

    // Clock and reset
    logic Clk_CI;
    logic Rst_RBI;

    // DUT inputs
    logic [C_WIDTH-1:0] OpA_DI;
    logic [C_WIDTH-1:0] OpB_DI;
    logic [C_LOG_WIDTH-1:0] OpBShift_DI;
    logic OpBIsZero_SI;
    logic OpBSign_SI;
    logic [1:0] OpCode_SI;
    logic InVld_SI;
    logic OutRdy_SI;

    // DUT outputs
    logic OutVld_SO;
    logic [C_WIDTH-1:0] Res_DO;

    // dut writing
    
    cv32e40p_alu_div uut(
        //inputs
        .Clk_CI(Clk_CI),
        .Rst_RBI(Rst_RBI),
        .OpA_DI(OpA_DI),
        .OpB_DI(OpB_DI),
        .OpBShift_DI(OpBShift_DI),
        .OpBIsZero_SI(OpBIsZero_SI),
        .OpBSign_SI(OpBSign_SI),
        .OpCode_SI(OpCode_SI),
        .InVld_SI(InVld_SI),
        .OutRdy_SI(OutRdy_SI),
        //outputs
        .OutVld_SO(OutVld_SO),
        .Res_DO(Res_DO)
    );

    initial begin
        Clk_CI=0;
        forever #10 Clk_CI = ~Clk_CI;
    end

    initial begin
        $dumpfile("top_sim.vcd"); //waveforms
        $dumpvars(0, cv32e40p_alu_div_tb);   //waveforms
    end

    // sirf chaar op h - signed div, unsigned div, signed rem, unsigned rem,
    initial begin
    $monitor(
        "Opcode=%b | A=%0d | B=%0d | Shift=%0d | OutVld=%b | Result=%0d", OpCode_SI, OpA_DI, OpB_DI,
        OpBShift_DI, OutVld_SO, Res_DO
    );
end

    // rst conditions intially everything will be 0 
    initial begin
        Rst_RBI      = 0;
        InVld_SI     = 0;
        OutRdy_SI    = 0;

        OpA_DI       = 0;
        OpB_DI       = 0;
        OpBShift_DI  = 0;
        OpBIsZero_SI = 0;
        OpBSign_SI   = 0;
        OpCode_SI    = 0;

        #20;
        Rst_RBI = 1;

        // 1. a=20,b=5, 20/5, opcode=00, res=4- div unsigned test kar rhi hu 
        #20;

        OpA_DI       = 32'd20;
        OpB_DI       = 32'd20;
        OpBShift_DI  = 6'd2;
        OpBIsZero_SI = 0;
        OpBSign_SI   = 0;
        OpCode_SI    = 2'b00;
        InVld_SI     = 1;

    //2.
        #20;
        InVld_SI = 0;
        wait (OutVld_SO == 1);
        OutRdy_SI = 1;
        #30;
        OutRdy_SI = 0;
        #20;
    //3.
        OpA_DI       = 32'd15;
        OpB_DI       = 32'd4;
        OpBShift_DI  = 6'd0;
        OpBIsZero_SI = 0;
        OpBSign_SI   = 0;
        OpCode_SI    = 2'b00;
        InVld_SI     = 1;
    //4.
        #20;
        InVld_SI = 0;
        wait (OutVld_SO == 1);
        OutRdy_SI = 1;
        #30;
        OutRdy_SI = 0;
        #20;
    //5.
        OpA_DI       = 32'd27;
        OpB_DI       = 32'd16;
        OpBShift_DI  = 6'd2;
        OpBIsZero_SI = 0;
        OpBSign_SI   = 0;
        OpCode_SI    = 2'b00;
        InVld_SI     = 1;
    //6.
        #20;
        InVld_SI = 0;
        wait (OutVld_SO == 1);
        OutRdy_SI = 1;
        #30;
        OutRdy_SI = 0;
        #20;
    //7.
        OpA_DI       = 32'd20;
        OpB_DI       = 32'd20;
        OpBShift_DI  = 6'd2;
        OpBIsZero_SI = 0;
        OpBSign_SI   = 0;
        OpCode_SI    = 2'b01;
        InVld_SI     = 1;
    //8.
        #20;
        InVld_SI = 0;
        wait (OutVld_SO == 1);
        OutRdy_SI = 1;
        #30;
        OutRdy_SI = 0;
    //9.
        #20;
        OpA_DI       = -32'sd20;
        OpB_DI       = 32'd20;
        OpBShift_DI  = 6'd2;
        OpBIsZero_SI = 0;
        OpBSign_SI   = 0;
        OpCode_SI    = 2'b01;
        InVld_SI     = 1;
    //10.
        #20;
        InVld_SI = 0;
        wait (OutVld_SO == 1);
        OutRdy_SI = 1;
        #30;
        OutRdy_SI = 0;
    //11.
        #20;
        OpA_DI       = 32'd20;
        OpB_DI       = -32'sd20;
        OpBShift_DI  = 6'd2;
        OpBIsZero_SI = 0;
        OpBSign_SI   = 1;
        OpCode_SI    = 2'b01;
        InVld_SI     = 1;
    //12.
        #20;
        InVld_SI = 0;
        wait (OutVld_SO == 1);
        OutRdy_SI = 1;
        #30;
        OutRdy_SI = 0;
        #20;
    //13.
        OpA_DI       = -32'sd30;
        OpB_DI       = -32'sd20;
        OpBShift_DI  = 6'd2;
        OpBIsZero_SI = 0;
        OpBSign_SI   = 1;
        OpCode_SI    = 2'b01;
        InVld_SI     = 1;
    //14.
        #20;
        InVld_SI = 0;
        wait (OutVld_SO == 1);
        OutRdy_SI = 1;
        #30;
        OutRdy_SI = 0;
        #20;

    //15.
        OpA_DI       = 32'd23;
        OpB_DI       = 32'd20;
        OpBShift_DI  = 6'd2;
        OpBIsZero_SI = 0;
        OpBSign_SI   = 0;
        OpCode_SI    = 2'b10;
        InVld_SI     = 1;
    //16.
        #20;
        InVld_SI = 0;
        wait (OutVld_SO == 1);
        OutRdy_SI = 1;
        #30;
        OutRdy_SI = 0;
        #20;
    //17.
        OpA_DI       = -32'sd23;
        OpB_DI       = 32'd20;
        OpBShift_DI  = 6'd2;
        OpBIsZero_SI = 0;
        OpBSign_SI   = 0;
        OpCode_SI    = 2'b11;
        InVld_SI     = 1;
    //18.
        #20;
        InVld_SI = 0;
        wait (OutVld_SO == 1);
        OutRdy_SI = 1;
        #30;
        OutRdy_SI = 0;
        #20;
    //19
        OpA_DI       = 32'd23;
        OpB_DI       = -32'sd20;
        OpBShift_DI  = 6'd2;
        OpBIsZero_SI = 0;
        OpBSign_SI   = 1;
        OpCode_SI    = 2'b11;
        InVld_SI     = 1;
    //20
        #20;
        InVld_SI = 0;
        wait (OutVld_SO == 1);
        OutRdy_SI = 1;
        #30;
        OutRdy_SI = 0;
        #20;
    //21
        OpA_DI       = 32'd0;
        OpB_DI       = 32'd5;
        OpBShift_DI  = 6'd0;
        OpBIsZero_SI = 0;
        OpBSign_SI   = 0;
        OpCode_SI    = 2'b00;
        InVld_SI     = 1;
    //22
        #20;
        InVld_SI = 0;
        wait (OutVld_SO == 1);
        OutRdy_SI = 1;
        #30;
        OutRdy_SI = 0;
        #20;
    //23
        OpA_DI       = 32'd20;
        OpB_DI       = 32'd0;
        OpBShift_DI  = 6'd31;
        OpBIsZero_SI = 1;
        OpBSign_SI   = 0;
        OpCode_SI    = 2'b00;
        InVld_SI     = 1;
    //24
        #20;
        InVld_SI = 0;
        wait (OutVld_SO == 1);
        OutRdy_SI = 1;
        #30;
        OutRdy_SI = 0;
        #20;
    //25
        OpA_DI       = 32'd0;
        OpB_DI       = 32'd0;
        OpBShift_DI  = 6'd31;
        OpBIsZero_SI = 1;
        OpBSign_SI   = 0;
        OpCode_SI    = 2'b00;
        InVld_SI     = 1;
    //26
        #20;
        InVld_SI = 0;
        wait (OutVld_SO == 1);
        OutRdy_SI = 1;
        #30;
        OutRdy_SI = 0;
        #20;
    //27.
        OpA_DI       = 32'd5;
        OpB_DI       = 32'd20;
        OpBShift_DI  = 6'd0;
        OpBIsZero_SI = 0;
        OpBSign_SI   = 0;
        OpCode_SI    = 2'b00;
        InVld_SI     = 1;
    //28
        #20;
        InVld_SI = 0;
        wait (OutVld_SO == 1);
        OutRdy_SI = 1;
        #30;
        OutRdy_SI = 0;
        #20;
    //29
        OpA_DI       = 32'd20;
        OpB_DI       = -32'sd20;
        OpBShift_DI  = 6'd2;
        OpBIsZero_SI = 0;
        OpBSign_SI   = 1;
        OpCode_SI    = 2'b01;
        InVld_SI     = 1;
    //30.
        #20;
        InVld_SI = 0;
        wait (OutVld_SO == 1);
        OutRdy_SI = 1;
        #30;
        OutRdy_SI = 0;
        #20;
    //31
        OpA_DI       = -32'sd20;
        OpB_DI       = 32'd20;
        OpBShift_DI  = 6'd2;
        OpBIsZero_SI = 0;
        OpBSign_SI   = 0;
        OpCode_SI    = 2'b01;
        InVld_SI     = 1;
    //32
        #20;
        InVld_SI = 0;
        wait (OutVld_SO == 1);
        OutRdy_SI = 1;
        #30;
        OutRdy_SI = 0;

        #20;
        $finish;
    end

endmodule
