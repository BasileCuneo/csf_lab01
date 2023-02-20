library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.avalon_types_pkg.all;
use work.project_logger_pkg.all;
use work.common_pkg.all;

package avalon_bfm_pkg is

    --| Constants |------------------------------------------------------------
    constant CLK_PERIOD : time := 1 us;

    -- Used to check waitrequest and readdatavalid. If they don't rise or fall
    -- For TIMEOUT after a request -> error.
    constant TIMEOUT : time := 20 * CLK_PERIOD;

    -- BFM for an avalon write request
    procedure avalon_write(variable val : in integer := 0;
    variable address : in integer := 0;
    variable byteenable : in std_logic_vector(1 downto 0);
    signal clk : in std_logic;
    signal observed : in avalon_slave_out_t;
    signal stimulus : out avalon_slave_in_t);

    -- BFM for an avalon read request
    procedure avalon_read(variable address : in integer := 0;
    variable readdata : out integer;
    signal clk : in std_logic;
    signal observed : in avalon_slave_out_t;
    signal stimulus : out avalon_slave_in_t;
    variable byteenable : in std_logic_vector(1 downto 0) := "11");

end avalon_bfm_pkg;

package body avalon_bfm_pkg is
    -- BFM for an avalon write request
    procedure avalon_write(variable val : in integer := 0;
    variable address : in integer := 0;
    variable byteenable : in std_logic_vector(1 downto 0);
    signal clk : in std_logic;
    signal observed : in avalon_slave_out_t;
    signal stimulus : out avalon_slave_in_t) is
    variable stimulus_v : avalon_slave_in_t(address(stimulus.address'range));
begin

    -- std_logic_vector to integer conversion
    stimulus_v.address := std_logic_vector(to_unsigned(address, stimulus.address'length));
    stimulus_v.byteenable := byteenable;
    stimulus_v.read := '0';
    stimulus_v.write := '1';
    stimulus_v.writedata := std_logic_vector(to_unsigned(val, stimulus.writedata'length));

    stimulus <= stimulus_v;

    wait until observed.waitrequest = '1' for TIMEOUT;
    wait until observed.waitrequest = '0' for TIMEOUT;

    stimulus_v.write := '0';
    stimulus <= stimulus_v;

end avalon_write;

-- BFM for an avalon read request
procedure avalon_read(variable address : in integer := 0;
variable readdata : out integer;
signal clk : in std_logic;
signal observed : in avalon_slave_out_t;
signal stimulus : out avalon_slave_in_t;
variable byteenable : in std_logic_vector(1 downto 0) := "11") is
variable stimulus_v : avalon_slave_in_t(address(stimulus.address'range));
begin

    stimulus_v.address := std_logic_vector(to_unsigned(address, stimulus.address'length));
    stimulus_v.byteenable := byteenable;
    stimulus_v.read := '1';
    stimulus_v.write := '0';
    
    stimulus <= stimulus_v;

    wait until observed.readdatavalid = '1' for TIMEOUT;

    -- std_logic_vector to integer conversion
    readdata := to_integer(unsigned(observed.readdata));

    wait until observed.readdatavalid = '0' for TIMEOUT;

    stimulus_v.read := '0';
    stimulus <= stimulus_v;

end avalon_read;



end avalon_bfm_pkg;