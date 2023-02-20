
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.common_pkg.all;
use work.avalon_types_pkg.all;
use work.avalon_bfm_pkg.all;
use work.project_logger_pkg.all;

package test_control_pkg is

    procedure test_status(constant N : in integer;
        signal clk : in std_logic;
        signal observed : in  avalon_slave_out_t;
        signal stimulus : out avalon_slave_in_t);

    procedure test_read_after_write(constant N : in integer;
        signal clk : in std_logic;
        signal observed : in  avalon_slave_out_t;
        signal stimulus : out avalon_slave_in_t);

    procedure test_values(constant DATASIZE : in integer;
        constant N : in integer;
        signal clk : in std_logic;
        signal observed : in  avalon_slave_out_t;
        signal stimulus : out avalon_slave_in_t);

end test_control_pkg;

package body test_control_pkg is 

procedure test_status(constant N : in integer;
                                 signal clk : in std_logic;
                                 signal observed : in  avalon_slave_out_t;
                                 signal stimulus : out avalon_slave_in_t) is


    variable stimulus_v : avalon_slave_in_t(address(stimulus.address'range));
    variable readdata_v : integer;
    variable val_v : integer;
    variable address_v : integer;
    variable byteenable_v : std_logic_vector(1 downto 0);
    constant MAX_TRY : integer := 20;
    variable current_try : integer := 0;
                                
    begin


        stimulus_v.address := std_logic_vector(to_unsigned(4, stimulus.address'length));
        stimulus_v.byteenable := "11";
        stimulus_v.read := '0';
        stimulus_v.write := '0';
        stimulus_v.writedata := std_logic_vector(to_unsigned(1, stimulus.writedata'length));
        stimulus <= stimulus_v;


        logger.log_note("test_status...");

        -- Check calculus has ended
        address_v := 5;
        current_try := 0;
        loop
            wait for TIMEOUT;
            
            avalon_read(address_v, readdata_v, clk, observed, stimulus);
            if (readdata_v mod 2) = 0 then
                exit;
            end if;
            if (current_try = MAX_TRY) then
                logger.log_error("test_n: status is not to 0, max try reached");
                exit;
            end if;
            current_try := current_try + 1;
        end loop;

        -- Write 0x1 to address 0x4
        val_v := 1;
        address_v := 4;
        byteenable_v := "11";
        avalon_write(val_v, address_v, byteenable_v, clk, observed, stimulus);

        -- Read from address 0x5 to readdata_v
        address_v := 5;
        avalon_read(address_v, readdata_v, clk, observed, stimulus);

        -- if readdata_v does not equal 0x0, then log an error
        if (readdata_v mod 2) = 1 then
            logger.log_error("test_status: status is not 0 during calculation");
        end if;

        -- wait for TIMEOUT so the calcul has enough time to end
        wait for TIMEOUT;

        -- Read from address 0x5 to readdata_v
        address_v := 5;
        avalon_read(address_v, readdata_v, clk, observed, stimulus);

        -- if readdata_v does not equal 0x1, then log an error
        if (readdata_v mod 2) = 0 then
            logger.log_error("test_status: status is not 1 after calculation");
        end if;

        cycle(clk, 1);

    end test_status;


procedure test_read_after_write(constant N : in integer;
                                 signal clk : in std_logic;
                                 signal observed : in  avalon_slave_out_t;
                                 signal stimulus : out avalon_slave_in_t) is


    variable stimulus_v : avalon_slave_in_t(address(stimulus.address'range));
    variable readdata_v : integer;
    variable val_v : integer;
    variable address_v : integer;
    variable byteenable_v : std_logic_vector(1 downto 0);

    begin

        stimulus_v.address := std_logic_vector(to_unsigned(4, stimulus.address'length));
        stimulus_v.byteenable := "11";
        stimulus_v.read := '0';
        stimulus_v.write := '0';
        stimulus_v.writedata := std_logic_vector(to_unsigned(1, stimulus.writedata'length));
        stimulus <= stimulus_v;        

        -- Write 1 to address 0 (value a)
        val_v := 1;
        address_v := 0;
        byteenable_v := "11";
        avalon_write(val_v, address_v, byteenable_v, clk, observed, stimulus);

        cycle(clk, 1);

        avalon_read(address_v, readdata_v, clk, observed, stimulus);
        check(val_v, readdata_v);

        -- Write 2 to address 1 (value b)
        val_v := 2;
        address_v := 1;
        byteenable_v := "11";
        avalon_write(val_v, address_v, byteenable_v, clk, observed, stimulus);

        cycle(clk, 1);

        avalon_read(address_v, readdata_v, clk, observed, stimulus);
        check(val_v, readdata_v);


        -- Write 3 to address 2 (value c)
        val_v := 3;
        address_v := 2;
        byteenable_v := "11";
        avalon_write(val_v, address_v, byteenable_v, clk, observed, stimulus);

        cycle(clk, 1);

        avalon_read(address_v, readdata_v, clk, observed, stimulus);
        check(val_v, readdata_v);

        cycle(clk, 1);

    end test_read_after_write;

procedure test_values(constant DATASIZE : in integer;
                            constant N : in integer;
                            signal clk : in std_logic;
                            signal observed : in  avalon_slave_out_t;
                            signal stimulus : out avalon_slave_in_t) is


    variable stimulus_v : avalon_slave_in_t(address(stimulus.address'range));
    variable readdata_v : integer;
    variable val_v : integer;
    variable address_v : integer;
    variable byteenable_v : std_logic_vector(1 downto 0);

    begin

        stimulus_v.address := std_logic_vector(to_unsigned(4, stimulus.address'length));
        stimulus_v.byteenable := "11";
        stimulus_v.read := '0';
        stimulus_v.write := '0';
        stimulus_v.writedata := std_logic_vector(to_unsigned(1, stimulus.writedata'length));
        stimulus <= stimulus_v;
        logger.log_note("test_values...");
    
        cycle(clk, 1);

        byteenable_v := "11";

        for a in 0 to 2 loop
            address_v := a;

            for i in 0 to 20 loop
                
                val_v := i;
                avalon_write(val_v, address_v, byteenable_v, clk, observed, stimulus);
        
                cycle(clk, 1);
        
                avalon_read(address_v, readdata_v, clk, observed, stimulus);

                check(val_v, readdata_v);

                cycle(clk, 1);
            end loop;

            for i in (2 ** DATASIZE) - 20 to (2 ** DATASIZE) - 1 loop
                
                val_v := i;
                avalon_write(val_v, address_v, byteenable_v, clk, observed, stimulus);
        
                cycle(clk, 1);
        
                avalon_read(address_v, readdata_v, clk, observed, stimulus);

                check(val_v, readdata_v);

                cycle(clk, 1);
            end loop;

        end loop;





    end test_values;

end test_control_pkg;
