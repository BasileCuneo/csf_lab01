

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.project_logger_pkg.all;
use work.common_pkg.all;
use work.avalon_types_pkg.all;
use work.avalon_bfm_pkg.all;

package test_avalon_pkg is

    procedure test_waitrequest_read(signal clk : in std_logic;
    signal observed : in avalon_slave_out_t;
    signal stimulus : out avalon_slave_in_t);

    procedure test_waitrequest_write(signal clk : in std_logic;
    signal observed : in avalon_slave_out_t;
    signal stimulus : out avalon_slave_in_t);

    procedure test_readdatavalid_read(signal clk : in std_logic;
    signal observed : in avalon_slave_out_t;
    signal stimulus : out avalon_slave_in_t);

    procedure test_readdatavalid_write(signal clk : in std_logic;
    signal observed : in avalon_slave_out_t;
    signal stimulus : out avalon_slave_in_t);

    procedure test_byteenable(constant DATASIZE : in integer;
    signal clk : in std_logic;
    signal observed : in avalon_slave_out_t;
    signal stimulus : out avalon_slave_in_t);

end test_avalon_pkg;

package body test_avalon_pkg is
    procedure test_waitrequest_read(signal clk : in std_logic;
    signal observed : in avalon_slave_out_t;
    signal stimulus : out avalon_slave_in_t) is
    variable stimulus_v : avalon_slave_in_t(address(stimulus.address'range));
begin
    cycle(clk, 1);

    stimulus_v.address := (others => '0');
    stimulus_v.byteenable := "11";
    stimulus_v.read := '1';
    stimulus_v.write := '0';
    stimulus_v.writedata := std_logic_vector(to_unsigned(4, stimulus_v.writedata'length));
    stimulus <= stimulus_v;
    logger.log_note("test_waitrequest_read...");

    -- Be sure that the waitrequest is low
    if (observed.waitrequest = '1') then
        logger.log_error("test_waitrequest_read: Waitrequest is init to 1");
    end if;

    -- Wait for waitrequest to rise
    wait until observed.waitrequest = '1' for CLK_PERIOD;
    if (observed.waitrequest = '0') then
        logger.log_error("test_waitrequest_read: Timeout on waitrequest. Waitrequest not rising when reading");
    end if;

    -- Wait for waitrequest to fall
    wait until observed.waitrequest = '0' for TIMEOUT;
    if (observed.waitrequest = '1') then
        logger.log_error("test_waitrequest_read: Timeout on waitrequest. Waitrequest not falling when reading");
    end if;
    -- Wait for readdatavalid to rise
    wait until observed.readdatavalid = '1' for CLK_PERIOD;
    if (observed.readdatavalid = '0') then
        logger.log_error("test_waitrequest_read: Timeout on readdatavalid. readdatavalid not rising when reading");
    end if;

    -- Wait for readdatavalid to fall
    wait until observed.readdatavalid = '0' for CLK_PERIOD;
    if (observed.readdatavalid = '1') then
        logger.log_error("test_waitrequest_read: Timeout on readdatavalid. readdatavalid not falling when stop reading");
    end if;

    stimulus_v.read := '0';
    stimulus <= stimulus_v;

    cycle(clk, 1);

end test_waitrequest_read;

procedure test_waitrequest_write(signal clk : in std_logic;
    signal observed : in avalon_slave_out_t;
    signal stimulus : out avalon_slave_in_t) is
    variable stimulus_v : avalon_slave_in_t(address(stimulus.address'range));
    begin
        cycle(clk, 1);

        -- Stimulus affectation for write a 4 on the reg at the adress 0
        stimulus_v.address := (others => '0');
        stimulus_v.byteenable := "11";
        stimulus_v.read := '0';
        stimulus_v.write := '1';
        stimulus_v.writedata := std_logic_vector(to_unsigned(4, stimulus_v.writedata 'length));

        stimulus <= stimulus_v;

        logger.log_note("test_waitrequest_write..");

        -- Be sure that the waitrequest is low
        if (observed.waitrequest = '1') then
            logger.log_error("test_waitrequest_write: Waitrequest is init to 1");
        end if;

        -- Wait for waitrequest to rise
        wait until observed.waitrequest = '1' for CLK_PERIOD;
        if (observed.waitrequest = '0') then
            logger.log_error("test_waitrequest_write: Timeout on waitrequest. Waitrequest not rising after write");
        end if;
        -- Wait for waitrequest to fall
        wait until observed.waitrequest = '0' for TIMEOUT;
        if (observed.waitrequest = '1') then
            logger.log_error("test_waitrequest_write: Timeout on waitrequest. Waitrequest not falling after write");
        end if;
        stimulus_v.write := '0';
        stimulus <= stimulus_v;
        cycle(clk, 1);

    end test_waitrequest_write;

procedure test_readdatavalid_read(signal clk : in std_logic;
    signal observed : in avalon_slave_out_t;
    signal stimulus : out avalon_slave_in_t) is
    variable stimulus_v : avalon_slave_in_t(address(stimulus.address'range));
    begin
        cycle(clk, 1);

        -- Stimulus affectation for read a 4 on the reg at the adress 0
        stimulus_v.address := (others => '0');
        stimulus_v.byteenable := "11";
        stimulus_v.read := '1';
        stimulus_v.write := '0';
        stimulus_v.writedata := std_logic_vector(to_unsigned(4, stimulus_v.writedata'length));
        stimulus <= stimulus_v;

        logger.log_note("test_readdatavalid_read...");

        -- Be sure that the readdatavalid is low
        if (observed.readdatavalid = '1') then
            logger.log_error("test_readdatavalid_read: readdatavalid is init to 1");
        end if;

        wait until observed.readdatavalid = '1' for TIMEOUT;
        wait until observed.readdatavalid = '0' for TIMEOUT;

        if (observed.waitrequest = '1') then
            logger.log_error("test_readdatavalid_read: Timeout on waitrequest. Waitrequest is not low when readdatavalid is high");
        end if;

        stimulus_v.read := '0';
        stimulus <= stimulus_v;
        cycle(clk, 1);

    end test_readdatavalid_read;

procedure test_readdatavalid_write(signal clk : in std_logic;
    signal observed : in avalon_slave_out_t;
    signal stimulus : out avalon_slave_in_t) is
    variable stimulus_v : avalon_slave_in_t(address(stimulus.address'range));
    begin
        cycle(clk, 1);

        -- Stimulus affectation for write a 4 on the reg at the adress 0
        stimulus_v.address := (others => '0');
        stimulus_v.byteenable := "11";
        stimulus_v.read := '0';
        stimulus_v.write := '1';
        stimulus_v.writedata := std_logic_vector(to_unsigned(4, stimulus_v.writedata'length));

        stimulus <= stimulus_v;

        logger.log_note("test_readdatavalid_write..");

        -- Be sure that the readdatavalid is low
        if (observed.readdatavalid = '1') then
            logger.log_error("test_readdatavalid_write: readdatavalid is init to 1");
        end if;

        wait until observed.waitrequest = '1' for TIMEOUT;

        if (observed.readdatavalid = '1') then
            logger.log_error("test_readdatavalid_write: readdatavalid is high when write");
        end if;

        wait until observed.waitrequest = '0' for TIMEOUT;

        stimulus_v.write := '0';
        stimulus <= stimulus_v;
        cycle(clk, 1);

    end test_readdatavalid_write;

procedure test_byteenable(constant DATASIZE : in integer;
        signal clk : in std_logic;
        signal observed : in avalon_slave_out_t;
        signal stimulus : out avalon_slave_in_t) is
        variable stimulus_v : avalon_slave_in_t(address(stimulus.address'range));
        variable readdata_v : integer;
        variable val_v : integer;
        variable address_v : integer;
        variable byteenable_v : std_logic_vector(1 downto 0);
    begin
        cycle(clk, 1);

        -- Stimulus affectation for write a 4 on the reg at the adress 0
        stimulus_v.address := (others => '0');
        stimulus_v.byteenable := "11";
        stimulus_v.read := '0';
        stimulus_v.write := '1';
        stimulus_v.writedata := std_logic_vector(to_unsigned(4, stimulus_v.writedata'length));

        stimulus <= stimulus_v;

        logger.log_note("test_byteenable..");

        -- Write 0xFF to address 0 (value a)
        val_v := (2 ** DATASIZE) - 1;
        address_v := 0;
        byteenable_v := "11";
        avalon_write(val_v, address_v, byteenable_v, clk, observed, stimulus);

        cycle(clk, 1);

        avalon_read(address_v, readdata_v, clk, observed, stimulus, byteenable_v);

        check(val_v, readdata_v);

        cycle(clk, 1);

        val_v := 0;
        address_v := 0;
        byteenable_v := "10";
        avalon_write(val_v, address_v, byteenable_v, clk, observed,     stimulus);

        cycle(clk, 1);

        avalon_read(address_v, readdata_v, clk, observed, stimulus);

        val_v := 255;

        check(val_v, readdata_v);


        cycle(clk, 1);
        wait for TIMEOUT;

    end test_byteenable;

end test_avalon_pkg;