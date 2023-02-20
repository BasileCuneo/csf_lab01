

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.common_pkg.all;
use work.avalon_types_pkg.all;
use work.avalon_bfm_pkg.all;
use work.project_logger_pkg.all;

package test_computing_pkg is

    procedure test_computing(constant N : in integer;
    signal clk : in std_logic;
    signal observed : in  avalon_slave_out_t;
    signal stimulus : out avalon_slave_in_t);

    procedure test_datasize(constant DATASIZE : in integer;
    constant N : in integer;
    signal clk : in std_logic;
    signal observed : in  avalon_slave_out_t;
    signal stimulus : out avalon_slave_in_t);

    procedure test_overflow(constant DATASIZE : in integer;
    constant N : in integer;
    signal clk : in std_logic;
    signal observed : in  avalon_slave_out_t;
    signal stimulus : out avalon_slave_in_t);

    procedure test_n(constant N : in integer;
    signal clk : in std_logic;
    signal observed : in  avalon_slave_out_t;
    signal stimulus : out avalon_slave_in_t);

end test_computing_pkg;

package body test_computing_pkg is

    
    procedure test_computing(constant N : in integer;
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
        logger.log_note("test_computing...");       

        -- Write 1 to address 0 (value a)
        val_v := 1;
        address_v := 0;
        byteenable_v := "11";
        avalon_write(val_v, address_v, byteenable_v, clk, observed, stimulus);

        -- Write 2 to address 1 (value b)
        val_v := 2;
        address_v := 1;
        byteenable_v := "11";
        avalon_write(val_v, address_v, byteenable_v, clk, observed, stimulus);

        -- Write 3 to address 2 (value c)
        val_v := 3;
        address_v := 2;
        byteenable_v := "11";
        avalon_write(val_v, address_v, byteenable_v, clk, observed, stimulus);

        -- Run the computation
        val_v := 1;
        address_v := 4;
        byteenable_v := "11";
        avalon_write(val_v, address_v, byteenable_v, clk, observed, stimulus);

        wait for TIMEOUT;

        -- Check calculus has ended
        address_v := 5;
        avalon_read(address_v, readdata_v, clk, observed, stimulus);

        if (readdata_v mod 2) = 0 then
            logger.log_error("test_computing: computation has not ended");
        end if;

        address_v := 3;
        avalon_read(address_v, readdata_v, clk, observed, stimulus);

        if readdata_v /= 7 then
            logger.log_error("test_computing: wrong result");
        end if;

        cycle(clk, 1);

    end test_computing;



procedure test_datasize(constant DATASIZE : in integer;
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
        logger.log_note("test_datasize...");

        -- Write (2 ** DATASIZE) + 1 to address 0 (value a)
        val_v := (2 ** DATASIZE) + 1;
        address_v := 0;
        byteenable_v := "11";
        avalon_write(val_v, address_v, byteenable_v, clk, observed, stimulus);

        -- Write (2 ** DATASIZE) + 1 to address 1 (value b)
        val_v := (2 ** DATASIZE) + 1;
        address_v := 1;
        byteenable_v := "11";
        avalon_write(val_v, address_v, byteenable_v, clk, observed, stimulus);

        -- Write (2 ** DATASIZE) + 1 to address 2 (value c)
        val_v := (2 ** DATASIZE) + 1;
        address_v := 2;
        byteenable_v := "11";
        avalon_write(val_v, address_v, byteenable_v, clk, observed, stimulus);

        -- Run the computation
        val_v := 1;
        address_v := 4;
        byteenable_v := "11";
        avalon_write(val_v, address_v, byteenable_v, clk, observed, stimulus);

        wait for TIMEOUT;

        -- Check calculus has ended
        address_v := 5;
        avalon_read(address_v, readdata_v, clk, observed, stimulus);

        if (readdata_v mod 2) = 0 then
            logger.log_error("test_datasize: computation has not ended");
        end if;

        address_v := 3;
        avalon_read(address_v, readdata_v, clk, observed, stimulus);

        if readdata_v /= 2 then
            logger.log_error("test_datasize: wrong result");
        end if;

        cycle(clk, 1);


    end test_datasize;


    procedure test_overflow(constant DATASIZE : in integer;
                            constant N : in integer;
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
        logger.log_note("test_overflow...");

        -- Write 1 to address 0 (value a)
        val_v := 1;
        address_v := 0;
        byteenable_v := "11";
        avalon_write(val_v, address_v, byteenable_v, clk, observed, stimulus);

        -- Write 2 to address 1 (value b)
        val_v := 2;
        address_v := 1;
        byteenable_v := "11";
        avalon_write(val_v, address_v, byteenable_v, clk, observed, stimulus);

        -- Write 2 ** (DATASIZE - 1) to address 2 (value c)
        val_v := 2 ** (DATASIZE - 1);
        address_v := 2;
        byteenable_v := "11";
        avalon_write(val_v, address_v, byteenable_v, clk, observed, stimulus);

        -- Run the computation
        val_v := 1;
        address_v := 4;
        byteenable_v := "11";
        avalon_write(val_v, address_v, byteenable_v, clk, observed, stimulus);

        -- Check calculus has ended
        address_v := 5;
        current_try := 0;
        loop
            wait for TIMEOUT;
            
            avalon_read(address_v, readdata_v, clk, observed, stimulus);
            if (readdata_v mod 2) = 1 then
                exit;
            end if;
            if (current_try = MAX_TRY) then
                logger.log_error("test_overflow: computation has not ended, max try reached");
                exit;
            end if;
            current_try := current_try + 1;
        end loop;

        address_v := 3;
        avalon_read(address_v, readdata_v, clk, observed, stimulus);

        if readdata_v /= 1 then
            logger.log_error("test_overflow: wrong result");
        end if;

        cycle(clk, 1);


    end test_overflow;


    procedure test_n(       constant N : in integer;
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
        logger.log_note("test_n...");

        -- Write 2 to address 0 (value a)
        val_v := 2;
        address_v := 0;
        byteenable_v := "11";
        avalon_write(val_v, address_v, byteenable_v, clk, observed, stimulus);

        -- Write 0 to address 1 (value b)
        val_v := 0;
        address_v := 1;
        byteenable_v := "11";
        avalon_write(val_v, address_v, byteenable_v, clk, observed, stimulus);

        -- Write 0 to address 2 (value c)
        val_v := 0;
        address_v := 2;
        byteenable_v := "11";
        avalon_write(val_v, address_v, byteenable_v, clk, observed, stimulus);

        -- Run the computation
        val_v := 1;
        address_v := 4;
        byteenable_v := "11";
        avalon_write(val_v, address_v, byteenable_v, clk, observed, stimulus);

        -- Check calculus has ended
        address_v := 5;
        current_try := 0;
        loop
            wait for TIMEOUT;
            
            avalon_read(address_v, readdata_v, clk, observed, stimulus);
            if (readdata_v mod 2) = 1 then
                exit;
            end if;
            if (current_try = MAX_TRY) then
                logger.log_error("test_n: computation has not ended, max try reached");
                exit;
            end if;
            current_try := current_try + 1;
        end loop;
            

        address_v := 3;
        avalon_read(address_v, readdata_v, clk, observed, stimulus);

        if readdata_v /= (2**N) then
            logger.log_error("test_n: wrong result");
        end if;

        cycle(clk, 1);


    end test_n;


end test_computing_pkg;
