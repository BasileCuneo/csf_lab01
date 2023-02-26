module avl_counter_tb#(int TESTCASE=0);

    logic avl_clk = 0;
    logic avl_reset;
    logic [2:0] avl_address;
    logic avl_write;
    logic [31:0] avl_writedata;
    logic avl_read;
    logic avl_readdatavalid;
    logic [31:0] avl_readdata;
    logic [3:0] avl_byteenable;
    logic avl_waitrequest;

    avl_counter#(0) avl(
        .avl_clk(avl_clk),
        .avl_reset(avl_reset),
        .avl_address(avl_address),
        .avl_write(avl_write),
        .avl_writedata(avl_writedata),
        .avl_read(avl_read),
        .avl_readdatavalid(avl_readdatavalid),
        .avl_readdata(avl_readdata),
        .avl_byteenable(avl_byteenable),
        .avl_waitrequest(avl_waitrequest)
    );

    
    // clock generation
    always #5 avl_clk = ~avl_clk;

    task wait_for(input logic signal, input int value, input int timeout, output int is_successfull);
        automatic int i = 0;
        is_successfull = 1;
        do begin
            @(posedge avl_clk);
            i = i + 1;
            assert (i < timeout)
                else begin 
                    $error("Error : timeout when waiting for signal");
                    is_successfull = 0;
                    break;
                end
        end while(signal == value);
        i = 0;
    endtask

    // Function read on avalon bus
    task read(input int address, input int byteenable, output int result);
        begin
            automatic int is_successfull;
            avl_address = address;
            avl_byteenable = byteenable;
            avl_read = 1;
            avl_write = 0;

            wait_for(avl_readdatavalid, 1, 20, is_successfull);
            if(is_successfull != 1)
                $error("Error : read failed on address %h, readdatavalid not raised up", address);

            result = avl_readdata;

            wait_for(avl_readdatavalid, 0, 20, is_successfull);
            if(is_successfull != 1)
                $error("Error : read failed on address %h, readdatavalid not raised down", address);

            avl_read = 0;
            @(posedge avl_clk);
        end        
    endtask

    // Function write on avalon bus
    task write(input int address, input int byteenable, input int data);
        begin
            automatic int is_successfull;
            avl_address = address;
            avl_byteenable = byteenable;
            avl_writedata = data;
            avl_read = 0;
            avl_write = 1;

            wait_for(avl_waitrequest, 1, 20, is_successfull);
            if(is_successfull != 1)
                $error("Error : write failed on address %h, waitrequest not raised down", address);

            wait_for(avl_waitrequest, 0, 20, is_successfull);
            if(is_successfull != 1)
                $error("Error : write failed on address %h, waitrequest not raised up", address);

            avl_write = 0;
            @(posedge avl_clk);
        end
    endtask

    initial begin
        int result;
        $display("Starting testbench");

        // Reset
        $display("Reset");
        @(posedge avl_clk);
        avl_reset = 1;
        @(posedge avl_clk);
        @(posedge avl_clk);
        avl_reset = 0;
        @(posedge avl_clk);
        @(posedge avl_clk);

        // Read constant
        $display("Read constant");
        
        read(0, 15, result);
        assert (result == 'hC5F02023)
            else $error("Error : read constant is %h instead of %h", result, 'hC5F02023);


        // Counter test
        $display("Counter test");

        // Reset counter
        write(2, 15, 1);

        // Check if counter is 0
        read(1, 15, result);
        assert (result == 0)
            else $error("Error : counter is %h instead of 0 after reset", result);

        // Increment counter
        for(int i = 0; i < 10; i = i + 1) begin
            write(2, 15, 2);
            read(1, 15, result);
            assert (result == i + 1)
                else $error("Error : counter is %h instead of %h after increment", result, i + 1);
        end

        // Reset counter
        write(2, 15, 1);

        // Check if counter is 0
        read(1, 15, result);
        assert (result == 0)
            else $error("Error : counter is %h instead of 0 after reset", result);

        // Check if other read/write registers work with byteenable
        /*
        $display("Check if other read/write registers work with byteenable");
        for(int r = 3; r < 7; r = r + 1) begin
            for(int i = 0; i < 4; i = i + 1) begin
                write(r, 1 << i, i);
                read(r, 15, result);
                assert (result == i)
                    else $error("Error : register %h is %h instead of %h after write", r, result, i);
            end
        end
        */




        $finish;
    end

endmodule
