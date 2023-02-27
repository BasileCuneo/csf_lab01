module avl_counter_tb#(int TESTCASE=0);

    logic avl_clk = 0;
    logic avl_reset;
    logic [2:0] avl_address;
    logic avl_read;
    logic avl_readdatavalid;
    logic [31:0] avl_readdata;
    logic avl_write;
    logic [31:0] avl_writedata;
    logic [3:0] avl_byteenable;
    logic avl_waitrequest;

    avl_counter#(0) avl(
        .avl_clk(avl_clk),
        .avl_reset(avl_reset),
        .avl_address(avl_address),
        .avl_read(avl_read),
        .avl_readdatavalid(avl_readdatavalid),
        .avl_readdata(avl_readdata),
        .avl_write(avl_write),
        .avl_writedata(avl_writedata),
        .avl_byteenable(avl_byteenable),
        .avl_waitrequest(avl_waitrequest)
    );

    // clock generator
    always #5 avl_clk = ~avl_clk;

    // function to wait for an event
    task wait_event(input logic signal, input logic value, input int timeout);
        begin
            int i;
            for (i = 0; i < timeout; i = i + 1) begin
                @(posedge avl_clk);
                if (signal == value) begin
                    break;
                end
            end
        end
    endtask

    // avalon write function
    task avalon_write(input int addr, input int byteenable, input int data);
        begin
            avl_address = addr;
            avl_byteenable = byteenable;
            avl_read = 0;
            avl_writedata = data;
            avl_write = 1;

            wait_event(avl_waitrequest, 1, 15);
            assert(avl_waitrequest == 1) else $error("waitrequest didnt rise on write");

            wait_event(avl_waitrequest, 0, 15);
            assert(avl_waitrequest == 0) else $error("waitrequest didnt fall on write");
            
            avl_write = 0;

            @(posedge avl_clk);
        end
    endtask

    // avalon read function 
    task avalon_read(input int addr, output int data);
        begin
            avl_address = addr;
            avl_byteenable = 15;
            avl_read = 1;
            avl_write = 0;

            wait_event(avl_waitrequest, 1, 15);
            assert(avl_waitrequest == 1) else $error("waitrequest didnt rise on read");

            wait_event(avl_readdatavalid, 1, 15);
            assert(avl_readdatavalid == 1) else $error("readdatavalid didnt rise on read");

            data = avl_readdata;

            wait_event(avl_waitrequest, 0, 15);
            assert(avl_waitrequest == 0) else $error("waitrequest didnt fall on read");

            avl_read = 0;

            wait_event(avl_readdatavalid, 0, 15);
            assert(avl_readdatavalid == 0) else $error("readdatavalid didnt fall on read");

            @(posedge avl_clk);
        end
    endtask

    initial begin
        int unsigned tmp;
        longint unsigned idx;
        $display("avl_counter_tb started, now reseting");

        @(posedge avl_clk);
        avl_reset = 1;
        @(posedge avl_clk);
        avl_reset = 0;
        @(posedge avl_clk);

        $display("reset done, now testing");
        $display("testing read on constant value at address 0");
        avalon_read(0, tmp);
        assert(tmp == 'hD0D0C5F0) else $error("constant value at address 0 has the wrong value");

        //READ / WRITE ON STANDARD REGISTERS ===============================================================
        $display("testing some read and writes on basic registers at addr 3, 4, 5 and 6");

        //some low values ===================================================================================

        //reset all registers
        for(idx = 3; idx < 7; idx = idx + 1) begin
            avalon_write(idx, 15, 0);
            avalon_read(idx, tmp);
            assert(tmp == 0) else $error("register at address %d has the wrong value at reset", idx); 
        end 

        //write to register 3 and checking all other registers
        for(idx = 0; idx < 100; idx = idx + 1) begin
            avalon_write (3, 15, idx);
            avalon_read (3, tmp);
            assert(tmp == idx) else $error("register at address 3 has the wrong value which is %d instead of %d", tmp, idx);
            avalon_read (4, tmp);
            assert(tmp == 0) else $error("register at address 4 should not have changed with a write to address 3");
            avalon_read (5, tmp);
            assert(tmp == 0) else $error("register at address 5 should not have changed with a write to address 3");
            avalon_read (6, tmp);
            assert(tmp == 0) else $error("register at address 6 should not have changed with a write to address 3");
        end

        //write to register 4 and checking all other registers
        for(idx = 0; idx < 100; idx = idx + 1) begin
            avalon_write (4, 15, idx);
            avalon_read (3, tmp);
            assert(tmp == 99) else $error("register at address 3 should not have changed with a write to address 4");
            avalon_read (4, tmp);
            assert(tmp == idx) else $error("register at address 4 has the wrong value which is %d instead of %d", tmp, idx);
            avalon_read (5, tmp);
            assert(tmp == 0) else $error("register at address 5 should not have changed with a write to address 4");
            avalon_read (6, tmp);
            assert(tmp == 0) else $error("register at address 6 should not have changed with a write to address 4");
        end

        //write to register 5 and checking all other registers
        for(idx = 0; idx < 100; idx = idx + 1) begin
            avalon_write (5, 15, idx);
            avalon_read (3, tmp);
            assert(tmp == 99) else $error("register at address 3 should not have changed with a write to address 5");
            avalon_read (4, tmp);
            assert(tmp == 99) else $error("register at address 4 should not have changed with a write to address 5");
            avalon_read (5, tmp);
            assert(tmp == idx) else $error("register at address 5 has the wrong value which is %d instead of %d", tmp, idx);
            avalon_read (6, tmp);
            assert(tmp == 0) else $error("register at address 6 should not have changed with a write to address 5");
        end

        //write to register 6 and checking all other registers
        for(idx = 0; idx < 100; idx = idx + 1) begin
            avalon_write (6, 15, idx);
            avalon_read (3, tmp);
            assert(tmp == 99) else $error("register at address 3 should not have changed with a write to address 6");
            avalon_read (4, tmp);
            assert(tmp == 99) else $error("register at address 4 should not have changed with a write to address 6");
            avalon_read (5, tmp);
            assert(tmp == 99) else $error("register at address 5 should not have changed with a write to address 6");
            avalon_read (6, tmp);
            assert(tmp == idx) else $error("register at address 6 has the wrong value which is %d instead of %d", tmp, idx);
        end

        //some high values ===================================================================================

        //reset all registers
        for(idx = 3; idx < 7; idx = idx + 1) begin
            avalon_write(idx, 15, 0);
            avalon_read(idx, tmp);
            assert(tmp == 0) else $error("register at address %d has the wrong value at reset", idx); 
        end 
        
        //write to register 3 and checking all other registers
        for(idx = 4294967195; idx < 4294967295; idx = idx + 1) begin
            avalon_write (3, 15, idx);
            avalon_read (3, tmp);
            assert(tmp == idx) else $error("register at address 3 has the wrong value which is %d instead of %d", tmp, idx);
            avalon_read (4, tmp);
            assert(tmp == 0) else $error("register at address 4 should not have changed with a write to address 3");
            avalon_read (5, tmp);
            assert(tmp == 0) else $error("register at address 5 should not have changed with a write to address 3");
            avalon_read (6, tmp);
            assert(tmp == 0) else $error("register at address 6 should not have changed with a write to address 3");
        end

        //write to register 4 and checking all other registers
        for(idx = 4294967195; idx < 4294967295; idx = idx + 1) begin
            avalon_write (4, 15, idx);
            avalon_read (3, tmp);
            assert(tmp == 4294967294) else $error("register at address 3 should not have changed with a write to address 4");
            avalon_read (4, tmp);
            assert(tmp == idx) else $error("register at address 4 has the wrong value which is %d instead of %d", tmp, idx);
            avalon_read (5, tmp);
            assert(tmp == 0) else $error("register at address 5 should not have changed with a write to address 4");
            avalon_read (6, tmp);
            assert(tmp == 0) else $error("register at address 6 should not have changed with a write to address 4");
        end

        //write to register 5 and checking all other registers
        for(idx = 4294967195; idx < 4294967295; idx = idx + 1) begin
            avalon_write (5, 15, idx);
            avalon_read (3, tmp);
            assert(tmp == 4294967294) else $error("register at address 3 should not have changed with a write to address 5");
            avalon_read (4, tmp);
            assert(tmp == 4294967294) else $error("register at address 4 should not have changed with a write to address 5");
            avalon_read (5, tmp);
            assert(tmp == idx) else $error("register at address 5 has the wrong value which is %d instead of %d", tmp, idx);
            avalon_read (6, tmp);
            assert(tmp == 0) else $error("register at address 6 should not have changed with a write to address 5");
        end

        //write to register 6 and checking all other registers
        for(idx = 4294967195; idx < 4294967295; idx = idx + 1) begin
            avalon_write (6, 15, idx);
            avalon_read (3, tmp);
            assert(tmp == 4294967294) else $error("register at address 3 should not have changed with a write to address 6");
            avalon_read (4, tmp);
            assert(tmp == 4294967294) else $error("register at address 4 should not have changed with a write to address 6");
            avalon_read (5, tmp);
            assert(tmp == 4294967294) else $error("register at address 5 should not have changed with a write to address 6");
            avalon_read (6, tmp);
            assert(tmp == idx) else $error("register at address 6 has the wrong value which is %d instead of %d", tmp, idx);
        end

        //some standard values ===================================================================================
    
        //reset all registers
        for(idx = 3; idx < 7; idx = idx + 1) begin
            avalon_write(idx, 15, 0);
            avalon_read(idx, tmp);
            assert(tmp == 0) else $error("register at address %d has the wrong value at reset", idx); 
        end 
        
        //write to register 3 and checking all other registers
        for(idx = 0; idx < 1000000; idx = idx + 100) begin
            avalon_write (3, 15, idx);
            avalon_read (3, tmp);
            assert(tmp == idx) else $error("register at address 3 has the wrong value which is %d instead of %d", tmp, idx);
            avalon_read (4, tmp);
            assert(tmp == 0) else $error("register at address 4 should not have changed with a write to address 3");
            avalon_read (5, tmp);
            assert(tmp == 0) else $error("register at address 5 should not have changed with a write to address 3");
            avalon_read (6, tmp);
            assert(tmp == 0) else $error("register at address 6 should not have changed with a write to address 3");
        end

        //write to register 4 and checking all other registers
        for(idx = 0; idx < 1000000; idx = idx + 100) begin
            avalon_write (4, 15, idx);
            avalon_read (3, tmp);
            assert(tmp == 999900) else $error("register at address 3 should not have changed with a write to address 4");
            avalon_read (4, tmp);
            assert(tmp == idx) else $error("register at address 4 has the wrong value which is %d instead of %d", tmp, idx);
            avalon_read (5, tmp);
            assert(tmp == 0) else $error("register at address 5 should not have changed with a write to address 4");
            avalon_read (6, tmp);
            assert(tmp == 0) else $error("register at address 6 should not have changed with a write to address 4");
        end

        //write to register 5 and checking all other registers
        for(idx = 0; idx < 1000000; idx = idx + 100) begin
            avalon_write (5, 15, idx);
            avalon_read (3, tmp);
            assert(tmp == 999900) else $error("register at address 3 should not have changed with a write to address 5");
            avalon_read (4, tmp);
            assert(tmp == 999900) else $error("register at address 4 should not have changed with a write to address 5");
            avalon_read (5, tmp);
            assert(tmp == idx) else $error("register at address 5 has the wrong value which is %d instead of %d", tmp, idx);
            avalon_read (6, tmp);
            assert(tmp == 0) else $error("register at address 6 should not have changed with a write to address 5");
        end

        //write to register 6 and checking all other registers
        for(idx = 0; idx < 1000000; idx = idx + 100) begin
            avalon_write (6, 15, idx);
            avalon_read (3, tmp);
            assert(tmp == 999900) else $error("register at address 3 should not have changed with a write to address 6");
            avalon_read (4, tmp);
            assert(tmp == 999900) else $error("register at address 4 should not have changed with a write to address 6");
            avalon_read (5, tmp);
            assert(tmp == 999900) else $error("register at address 5 should not have changed with a write to address 6");
            avalon_read (6, tmp);
            assert(tmp == idx) else $error("register at address 6 has the wrong value which is %d instead of %d", tmp, idx);
        end

        // BYTE ENABLE TESTING ========================================================================  
        $display("Testing byte enables");

        //reset all registers
        for(idx = 3; idx < 7; idx = idx + 1) begin
            avalon_write(idx, 15, 0);
            avalon_read(idx, tmp);
            assert(tmp == 0) else $error("register at address %d has the wrong value at reset", idx); 
        end

        //write 0xFFFFFFFF to the 4 registers with a byte enable of 1

        for(idx = 3; idx < 7; idx = idx + 1) begin
            avalon_write(idx, 1, 'hffffffff);
            avalon_read(idx, tmp);
            assert(tmp == 'hff) else $error("register at address %d has the wrong value which is %d instead of %d", idx, tmp, 'hff);
        end

        //reset all registers
        for(idx = 3; idx < 7; idx = idx + 1) begin
            avalon_write(idx, 15, 0);
            avalon_read(idx, tmp);
            assert(tmp == 0) else $error("register at address %d has the wrong value at reset", idx); 
        end

        //write 0xFFFFFFFF to the 4 registers with a byte enable of 2
        for(idx = 3; idx < 7; idx = idx + 1) begin
            avalon_write(idx, 2, 'hffffffff);
            avalon_read(idx, tmp);
            assert(tmp == 'hff00) else $error("register at address %d has the wrong value which is %d instead of %d", idx, tmp, 'hff00);
        end

        //reset all registers
        for(idx = 3; idx < 7; idx = idx + 1) begin
            avalon_write(idx, 15, 0);
            avalon_read(idx, tmp);
            assert(tmp == 0) else $error("register at address %d has the wrong value at reset", idx); 
        end

        //write 0xFFFFFFFF to the 4 registers with a byte enable of 4
        for(idx = 3; idx < 7; idx = idx + 1) begin
            avalon_write(idx, 4, 'hffffffff);
            avalon_read(idx, tmp);
            assert(tmp == 'hff0000) else $error("register at address %d has the wrong value which is %d instead of %d", idx, tmp, 'hff0000);
        end

        //reset all registers
        for(idx = 3; idx < 7; idx = idx + 1) begin
            avalon_write(idx, 15, 0);
            avalon_read(idx, tmp);
            assert(tmp == 0) else $error("register at address %d has the wrong value at reset", idx); 
        end

        //write 0xFFFFFFFF to the 4 registers with a byte enable of 8
        for(idx = 3; idx < 7; idx = idx + 1) begin
            avalon_write(idx, 8, 'hffffffff);
            avalon_read(idx, tmp);
            assert(tmp == 'hff000000) else $error("register at address %d has the wrong value which is %d instead of %d", idx, tmp, 'hff000000);
        end

        //reset all registers
        for(idx = 3; idx < 7; idx = idx + 1) begin
            avalon_write(idx, 15, 0);
            avalon_read(idx, tmp);
            assert(tmp == 0) else $error("register at address %d has the wrong value at reset", idx); 
        end

        //write 0xFFFFFFFF to the 4 registers with a byte enable of 3
        for(idx = 3; idx < 7; idx = idx + 1) begin
            avalon_write(idx, 3, 'hffffffff);
            avalon_read(idx, tmp);
            assert(tmp == 'hffff) else $error("register at address %d has the wrong value which is %d instead of %d", idx, tmp, 'hffff);
        end

        //reset all registers
        for(idx = 3; idx < 7; idx = idx + 1) begin
            avalon_write(idx, 15, 0);
            avalon_read(idx, tmp);
            assert(tmp == 0) else $error("register at address %d has the wrong value at reset", idx); 
        end

        //write 0xFFFFFFFF to the 4 registers with a byte enable of 12 (0xC)
        for(idx = 3; idx < 7; idx = idx + 1) begin
            avalon_write(idx, 12, 'hffffffff);
            avalon_read(idx, tmp);
            assert(tmp == 'hffff0000) else $error("register at address %d has the wrong value which is %d instead of %d", idx, tmp, 'hffff0000);
        end

        //ajouter des combinaisons de mots?? TODO

        // COUNTER TESTING ====================================================================================================  
        $display("Testing counter");

        avalon_write(2, 15, 1);
        avalon_read(1, tmp);
        assert(tmp == 0) else $error("counter value should be 0 after reset");

        for(idx = 1; idx < 1000000; idx = idx + 100) begin
            avalon_write(2, 15, 2);
            avalon_read(1, tmp);
            assert(tmp == idx) else $error("counter value is %d instead of %d", tmp, idx);
        end
        
        avalon_write(2, 15, 1);
        avalon_read(1, tmp);
        assert(tmp == 0) else $error("counter value should be 0 after reset");

        // testing some bad inputs on register at address 2
        for(idx = 0; idx < 1000; idx = idx + 5) begin
            avalon_write(2, 15, idx);
            avalon_read(1, tmp);
            assert(tmp == 0) else $error("counter value should not have changed with a bad value on controle register");
        end

        $finish;
    end

endmodule
