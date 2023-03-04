module avl_counter_tb#(int TESTCASE=0);

    logic avl_clk_i = 0;
    logic avl_reset_i;
    logic [2:0] avl_address_i;
    logic avl_read_i;
    logic avl_readdatavalid_o;
    logic [31:0] avl_readdata_o;
    logic avl_write_i;
    logic [31:0] avl_writedata_i;
    logic [3:0] avl_byteenable_i;
    logic avl_waitrequest_o;

    avl_counter#(0) avl(
        .avl_clk_i(avl_clk_i),
        .avl_reset_i(avl_reset_i),
        .avl_address_i(avl_address_i),
        .avl_read_i(avl_read_i),
        .avl_readdatavalid_o(avl_readdatavalid_o),
        .avl_readdata_o(avl_readdata_o),
        .avl_write_i(avl_write_i),
        .avl_writedata_i(avl_writedata_i),
        .avl_byteenable_i(avl_byteenable_i),
        .avl_waitrequest_o(avl_waitrequest_o)
    );

    // clock generator
    always #5 avl_clk_i = ~avl_clk_i;

    // function to wait for an event
    task automatic wait_event(ref logic signal, input logic value, input int timeout);
        begin
            int i;
            for (i = 0; i < timeout; i = i + 1) begin
                if (signal == value) begin
                    break;
                end
                @(posedge avl_clk_i);
            end
        end
    endtask

    // avalon write function
    task avalon_write(input int addr, input int byteenable, input int data);
        begin
            avl_address_i = addr;
            avl_byteenable_i = byteenable;
            avl_read_i = 0;
            avl_writedata_i = data;
            avl_write_i = 1;

            wait_event(avl_waitrequest_o, 1, 15);
            assert(avl_waitrequest_o == 1) else $error("waitrequest didnt rise on write");

            wait_event(avl_waitrequest_o, 0, 15);
            assert(avl_waitrequest_o == 0) else $error("waitrequest didnt fall on write");
            
            avl_write_i = 0;

            @(posedge avl_clk_i);
        end
    endtask

    assert_readdatavalid_waitrequest : assert property
    (
        @(posedge avl_clk_i)
        avl_waitrequest_o |-> !avl_readdatavalid_o
    );

    assert_write_readdata_valid : assert property
    (
        @(posedge avl_clk_i)
        avl_write_i |-> !avl_readdatavalid_o
    );

    // avalon read function 
    task avalon_read(input int addr, output int data);
        begin
            avl_address_i = addr;
            avl_byteenable_i = 15;
            avl_write_i = 0;
            avl_read_i = 1;

            wait_event(avl_waitrequest_o, 1, 15);
            assert(avl_waitrequest_o == 1) else $error("waitrequest didnt rise on read");

            wait_event(avl_waitrequest_o, 0, 15);
            assert(avl_waitrequest_o == 0) else $error("waitrequest didnt fall on read");

            wait_event(avl_readdatavalid_o, 1, 15);
            assert(avl_readdatavalid_o == 1) else $error("readdatavalid didnt rise on read");
            
            data = avl_readdata_o;

            avl_read_i = 0;

            wait_event(avl_readdatavalid_o, 0, 15);
            assert(avl_readdatavalid_o == 0) else $error("readdatavalid didnt fall on read");

            @(posedge avl_clk_i);
        end
    endtask

    initial begin
        int unsigned tmp;
        longint unsigned idx;
        $display("avl_counter_tb started, now reseting");

        @(posedge avl_clk_i);
        avl_reset_i = 1;
        @(posedge avl_clk_i);
        avl_reset_i = 0;
        @(posedge avl_clk_i);

        $display("reset done, now testing");
        $display("testing read on constant value at address 0");
        avalon_read(0, tmp);
        assert(tmp === 'hD0D0C5F0) else $error("constant value at address 0 has the wrong value");

        //READ / WRITE ON STANDARD REGISTERS ===============================================================
        $display("testing some read and writes on basic registers at addr 3, 4, 5 and 6");

        //some low values ===================================================================================

        //reset all registers
        for(idx = 3; idx < 7; idx = idx + 1) begin
            avalon_write(idx, 15, 0);
            avalon_read(idx, tmp);
            assert(tmp === 0) else $error("register at address %d has the wrong value at reset", idx); 
        end 

        //write to register 3 and checking all other registers
        for(idx = 0; idx < 100; idx = idx + 1) begin
            avalon_write (3, 15, idx);
            avalon_read (3, tmp);
            assert(tmp === idx) else $error("register at address 3 has the wrong value which is %d instead of %d", tmp, idx);
            avalon_read (4, tmp);
            assert(tmp === 0) else $error("register at address 4 should not have changed with a write to address 3");
            avalon_read (5, tmp);
            assert(tmp === 0) else $error("register at address 5 should not have changed with a write to address 3");
            avalon_read (6, tmp);
            assert(tmp === 0) else $error("register at address 6 should not have changed with a write to address 3");
        end

        //write to register 4 and checking all other registers
        for(idx = 0; idx < 100; idx = idx + 1) begin
            avalon_write (4, 15, idx);
            avalon_read (3, tmp);
            assert(tmp === 99) else $error("register at address 3 should not have changed with a write to address 4");
            avalon_read (4, tmp);
            assert(tmp === idx) else $error("register at address 4 has the wrong value which is %d instead of %d", tmp, idx);
            avalon_read (5, tmp);
            assert(tmp === 0) else $error("register at address 5 should not have changed with a write to address 4");
            avalon_read (6, tmp);
            assert(tmp === 0) else $error("register at address 6 should not have changed with a write to address 4");
        end

        //write to register 5 and checking all other registers
        for(idx = 0; idx < 100; idx = idx + 1) begin
            avalon_write (5, 15, idx);
            avalon_read (3, tmp);
            assert(tmp === 99) else $error("register at address 3 should not have changed with a write to address 5");
            avalon_read (4, tmp);
            assert(tmp === 99) else $error("register at address 4 should not have changed with a write to address 5");
            avalon_read (5, tmp);
            assert(tmp === idx) else $error("register at address 5 has the wrong value which is %d instead of %d", tmp, idx);
            avalon_read (6, tmp);
            assert(tmp === 0) else $error("register at address 6 should not have changed with a write to address 5");
        end

        //write to register 6 and checking all other registers
        for(idx = 0; idx < 100; idx = idx + 1) begin
            avalon_write (6, 15, idx);
            avalon_read (3, tmp);
            assert(tmp === 99) else $error("register at address 3 should not have changed with a write to address 6");
            avalon_read (4, tmp);
            assert(tmp === 99) else $error("register at address 4 should not have changed with a write to address 6");
            avalon_read (5, tmp);
            assert(tmp === 99) else $error("register at address 5 should not have changed with a write to address 6");
            avalon_read (6, tmp);
            assert(tmp === idx) else $error("register at address 6 has the wrong value which is %d instead of %d", tmp, idx);
        end

        //some high values ===================================================================================

        //reset all registers
        for(idx = 3; idx < 7; idx = idx + 1) begin
            avalon_write(idx, 15, 0);
            avalon_read(idx, tmp);
            assert(tmp === 0) else $error("register at address %d has the wrong value at reset", idx); 
        end 
        
        //write to register 3 and checking all other registers
        for(idx = 64'd4294967195; idx < 64'd4294967295; idx = idx + 1) begin
            avalon_write (3, 15, idx);
            avalon_read (3, tmp);
            assert(tmp === idx) else $error("register at address 3 has the wrong value which is %d instead of %d", tmp, idx);
            avalon_read (4, tmp);
            assert(tmp === 0) else $error("register at address 4 should not have changed with a write to address 3");
            avalon_read (5, tmp);
            assert(tmp === 0) else $error("register at address 5 should not have changed with a write to address 3");
            avalon_read (6, tmp);
            assert(tmp === 0) else $error("register at address 6 should not have changed with a write to address 3");
        end

        //write to register 4 and checking all other registers
        for(idx = 64'd4294967195; idx < 64'd4294967295; idx = idx + 1) begin
            avalon_write (4, 15, idx);
            avalon_read (3, tmp);
            assert(tmp === 64'd4294967294) else $error("register at address 3 should not have changed with a write to address 4");
            avalon_read (4, tmp);
            assert(tmp === idx) else $error("register at address 4 has the wrong value which is %d instead of %d", tmp, idx);
            avalon_read (5, tmp);
            assert(tmp === 0) else $error("register at address 5 should not have changed with a write to address 4");
            avalon_read (6, tmp);
            assert(tmp === 0) else $error("register at address 6 should not have changed with a write to address 4");
        end

        //write to register 5 and checking all other registers
        for(idx = 64'd4294967195; idx < 64'd4294967295; idx = idx + 1) begin
            avalon_write (5, 15, idx);
            avalon_read (3, tmp);
            assert(tmp === 64'd4294967294) else $error("register at address 3 should not have changed with a write to address 5");
            avalon_read (4, tmp);
            assert(tmp === 64'd4294967294) else $error("register at address 4 should not have changed with a write to address 5");
            avalon_read (5, tmp);
            assert(tmp === idx) else $error("register at address 5 has the wrong value which is %d instead of %d", tmp, idx);
            avalon_read (6, tmp);
            assert(tmp === 0) else $error("register at address 6 should not have changed with a write to address 5");
        end

        //write to register 6 and checking all other registers
        for(idx = 64'd4294967195; idx < 64'd4294967295; idx = idx + 1) begin
            avalon_write (6, 15, idx);
            avalon_read (3, tmp);
            assert(tmp === 64'd4294967294) else $error("register at address 3 should not have changed with a write to address 6");
            avalon_read (4, tmp);
            assert(tmp === 64'd4294967294) else $error("register at address 4 should not have changed with a write to address 6");
            avalon_read (5, tmp);
            assert(tmp === 64'd4294967294) else $error("register at address 5 should not have changed with a write to address 6");
            avalon_read (6, tmp);
            assert(tmp === idx) else $error("register at address 6 has the wrong value which is %d instead of %d", tmp, idx);
        end

        //some standard values ===================================================================================
    
        //reset all registers
        for(idx = 3; idx < 7; idx = idx + 1) begin
            avalon_write(idx, 15, 0);
            avalon_read(idx, tmp);
            assert(tmp === 0) else $error("register at address %d has the wrong value at reset", idx); 
        end 
        
        //write to register 3 and checking all other registers
        for(idx = 0; idx < 1000000; idx = idx + 100) begin
            avalon_write (3, 15, idx);
            avalon_read (3, tmp);
            assert(tmp === idx) else $error("register at address 3 has the wrong value which is %d instead of %d", tmp, idx);
            avalon_read (4, tmp);
            assert(tmp === 0) else $error("register at address 4 should not have changed with a write to address 3");
            avalon_read (5, tmp);
            assert(tmp === 0) else $error("register at address 5 should not have changed with a write to address 3");
            avalon_read (6, tmp);
            assert(tmp === 0) else $error("register at address 6 should not have changed with a write to address 3");
        end

        //write to register 4 and checking all other registers
        for(idx = 0; idx < 1000000; idx = idx + 100) begin
            avalon_write (4, 15, idx);
            avalon_read (3, tmp);
            assert(tmp === 999900) else $error("register at address 3 should not have changed with a write to address 4");
            avalon_read (4, tmp);
            assert(tmp === idx) else $error("register at address 4 has the wrong value which is %d instead of %d", tmp, idx);
            avalon_read (5, tmp);
            assert(tmp === 0) else $error("register at address 5 should not have changed with a write to address 4");
            avalon_read (6, tmp);
            assert(tmp === 0) else $error("register at address 6 should not have changed with a write to address 4");
        end

        //write to register 5 and checking all other registers
        for(idx = 0; idx < 1000000; idx = idx + 100) begin
            avalon_write (5, 15, idx);
            avalon_read (3, tmp);
            assert(tmp === 999900) else $error("register at address 3 should not have changed with a write to address 5");
            avalon_read (4, tmp);
            assert(tmp === 999900) else $error("register at address 4 should not have changed with a write to address 5");
            avalon_read (5, tmp);
            assert(tmp === idx) else $error("register at address 5 has the wrong value which is %d instead of %d", tmp, idx);
            avalon_read (6, tmp);
            assert(tmp === 0) else $error("register at address 6 should not have changed with a write to address 5");
        end

        //write to register 6 and checking all other registers
        for(idx = 0; idx < 1000000; idx = idx + 100) begin
            avalon_write (6, 15, idx);
            avalon_read (3, tmp);
            assert(tmp === 999900) else $error("register at address 3 should not have changed with a write to address 6");
            avalon_read (4, tmp);
            assert(tmp === 999900) else $error("register at address 4 should not have changed with a write to address 6");
            avalon_read (5, tmp);
            assert(tmp === 999900) else $error("register at address 5 should not have changed with a write to address 6");
            avalon_read (6, tmp);
            assert(tmp === idx) else $error("register at address 6 has the wrong value which is %d instead of %d", tmp, idx);
        end

        // BYTE ENABLE TESTING ========================================================================  
        $display("Testing byte enables");

        //reset all registers
        for(idx = 3; idx < 7; idx = idx + 1) begin
            avalon_write(idx, 15, 0);
            avalon_read(idx, tmp);
            assert(tmp === 0) else $error("BE: register at address %d has the wrong value at reset", idx); 
        end

        //write 0xFFFFFFFF to the 4 registers with a byte enable of 1

        for(idx = 3; idx < 7; idx = idx + 1) begin
            avalon_write(idx, 1, 'hffffffff);
            avalon_read(idx, tmp);
            assert(tmp === 'hff) else $error("BE: register at address %d has the wrong value which is %d instead of %d", idx, tmp, 'hff);
        end

        //reset all registers
        for(idx = 3; idx < 7; idx = idx + 1) begin
            avalon_write(idx, 15, 0);
            avalon_read(idx, tmp);
            assert(tmp == 0) else $error("BE: register at address %d has the wrong value at reset", idx); 
        end

        //write 0xFFFFFFFF to the 4 registers with a byte enable of 2
        for(idx = 3; idx < 7; idx = idx + 1) begin
            avalon_write(idx, 2, 'hffffffff);
            avalon_read(idx, tmp);
            assert(tmp === 'hff00) else $error("BE: register at address %d has the wrong value which is %d instead of %d", idx, tmp, 'hff00);
        end

        //reset all registers
        for(idx = 3; idx < 7; idx = idx + 1) begin
            avalon_write(idx, 15, 0);
            avalon_read(idx, tmp);
            assert(tmp === 0) else $error("BE: register at address %d has the wrong value at reset", idx); 
        end

        //write 0xFFFFFFFF to the 4 registers with a byte enable of 4
        for(idx = 3; idx < 7; idx = idx + 1) begin
            avalon_write(idx, 4, 'hffffffff);
            avalon_read(idx, tmp);
            assert(tmp === 'hff0000) else $error("BE: register at address %d has the wrong value which is %d instead of %d", idx, tmp, 'hff0000);
        end

        //reset all registers
        for(idx = 3; idx < 7; idx = idx + 1) begin
            avalon_write(idx, 15, 0);
            avalon_read(idx, tmp);
            assert(tmp === 0) else $error("BE: register at address %d has the wrong value at reset", idx); 
        end

        //write 0xFFFFFFFF to the 4 registers with a byte enable of 8
        for(idx = 3; idx < 7; idx = idx + 1) begin
            avalon_write(idx, 8, 'hffffffff);
            avalon_read(idx, tmp);
            assert(tmp === 'hff000000) else $error("BE: register at address %d has the wrong value which is %d instead of %d", idx, tmp, 'hff000000);
        end

        //reset all registers
        for(idx = 3; idx < 7; idx = idx + 1) begin
            avalon_write(idx, 15, 0);
            avalon_read(idx, tmp);
            assert(tmp === 0) else $error("BE: register at address %d has the wrong value at reset", idx); 
        end

        //write 0xFFFFFFFF to the 4 registers with a byte enable of 3
        for(idx = 3; idx < 7; idx = idx + 1) begin
            avalon_write(idx, 3, 'hffffffff);
            avalon_read(idx, tmp);
            assert(tmp === 'hffff) else $error("BE: register at address %d has the wrong value which is %d instead of %d", idx, tmp, 'hffff);
        end

        //reset all registers
        for(idx = 3; idx < 7; idx = idx + 1) begin
            avalon_write(idx, 15, 0);
            avalon_read(idx, tmp);
            assert(tmp === 0) else $error("BE: register at address %d has the wrong value at reset", idx); 
        end

        //write 0xFFFFFFFF to the 4 registers with a byte enable of 12 (0xC)
        for(idx = 3; idx < 7; idx = idx + 1) begin
            avalon_write(idx, 12, 'hffffffff);
            avalon_read(idx, tmp);
            assert(tmp === 'hffff0000) else $error("BE: register at address %d has the wrong value which is %d instead of %d", idx, tmp, 'hffff0000);
        end

        //ajouter des combinaisons de mots?? TODO

        // COUNTER TESTING ====================================================================================================  
        $display("Testing counter");

        tmp = 0;

        avalon_write(2, 15, 1);
        avalon_read(1, tmp);
        assert(tmp === 0) else $error("counter value should be 0 after reset and his value is %d", tmp);

        for(idx = 1; idx < 1000; idx = idx + 1) begin
            avalon_write(2, 15, 2);
            avalon_read(1, tmp);
            assert(tmp === idx) else $error("counter value is %d instead of %d", tmp, idx);
        end
        
        avalon_write(2, 15, 1);
        avalon_read(1, tmp);
        assert(tmp === 0) else $error("counter value should be 0 after reset and his value is %d", tmp);

        // testing some bad inputs on register at address 2
        for(idx = 0; idx < 1000; idx = idx + 5) begin
            avalon_write(2, 15, idx);
            avalon_read(1, tmp);
            assert(tmp === 0) else $error("counter value should not have changed with a bad value on controle register");
        end

        $finish;
    end

endmodule
