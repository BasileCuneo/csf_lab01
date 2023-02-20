-------------------------------------------------------------------------------
-- HEIG-VD, Haute Ecole d'Ingenierie et de Gestion du canton de Vaud
-- Institut REDS, Reconfigurable & Embedded Digital Systems
--
-- Fichier      : avalon_computer_tb.vhd
--
-- Description  : Sequential testbench for a calculator on an avalon mm slave.
--                This testbench consist of one sim process who run some test
--                procedure. The check are done directly on the test procedure.
--
--                There is X test procedure :
--                - ...
--
-- Auteur       : ...
-- Date         : ...
-- Version      : 1.0
--
-- Utilisé dans : Laboratoire de  VSE
--
--| Modifications |------------------------------------------------------------
-- Version   Auteur      Date               Description
-- 1.0       ...         see header         First version.
-------------------------------------------------------------------------------

--| Librarys |-----------------------------------------------------------------
library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.project_logger_pkg.all;
use work.common_pkg.all;
use work.avalon_types_pkg.all;
use work.avalon_bfm_pkg.all;
use work.test_avalon_pkg.all;
use work.test_control_pkg.all;
use work.test_computing_pkg.all;
-------------------------------------------------------------------------------

--| Entity |-------------------------------------------------------------------
entity avalon_computer_tb is
    generic (
        N        : integer := 3;
        ADDRSIZE : integer := 8;
        DATASIZE : integer := 16;
        ERRNO    : integer := 0;
        TESTCASE : integer := 0
    );
end avalon_computer_tb;
-------------------------------------------------------------------------------

--| Architecture |-------------------------------------------------------------
architecture testbench of avalon_computer_tb is


      --| Constants |------------------------------------------------------------
      constant CLK_PERIOD  : time := 1 us;
    -- Used to check waitrequest and readdatavalid. If they don't rise or fall
    -- For TIMEOUT after a request -> error.
    constant TIMEOUT : time := 50 * CLK_PERIOD;
    ---------------------------------------------------------------------------

    --| Signals|---------------------------------------------------------------
    -- Tests
    signal stimulus_sti : avalon_slave_in_t(address(ADDRSIZE - 1 downto 0));
    signal clk_sti      : std_logic;
    signal rst_sti      : std_logic;
    signal observed_obs : avalon_slave_out_t;

    -- Simulation
    signal sim_end_s : boolean := false;
    ---------------------------------------------------------------------------

    --| Components |-----------------------------------------------------------
    -- DUT
    component avalon_computer
        generic (
            N        : integer := 3;
            ADDRSIZE : integer := 8;
            DATASIZE : integer := 16;
            ERRNO    : integer := 0
        );
        port (
            clk_i           : in  std_logic;
            rst_i           : in  std_logic;
            address_i       : in  std_logic_vector(ADDRSIZE-1 downto 0);
            byteenable_i    : in  std_logic_vector(1 downto 0);
            read_i          : in  std_logic;
            write_i         : in  std_logic;
            waitrequest_o   : out std_logic;
            readdatavalid_o : out std_logic;
            readdata_o      : out std_logic_vector(15 downto 0);
            writedata_i     : in  std_logic_vector(15 downto 0)
        );
    end component avalon_computer;
    for all : avalon_computer use entity work.avalon_computer(struct);
    ---------------------------------------------------------------------------

begin

    --| Components instanciation |---------------------------------------------
    DUT : avalon_computer
    generic map (
        N        => N,
        ADDRSIZE => ADDRSIZE,
        DATASIZE => DATASIZE,
        ERRNO    => ERRNO
    )
    port map (
        clk_i           => clk_sti,
        rst_i           => rst_sti,
        address_i       => stimulus_sti.address,
        byteenable_i    => stimulus_sti.byteenable,
        read_i          => stimulus_sti.read,
        write_i         => stimulus_sti.write,
        waitrequest_o   => observed_obs.waitrequest,
        readdatavalid_o => observed_obs.readdatavalid,
        readdata_o      => observed_obs.readdata,
        writedata_i     => stimulus_sti.writedata
    );
    ---------------------------------------------------------------------------

    --| Clock generation process |---------------------------------------------
    clk_gen : process is
    begin
        while not(sim_end_s) loop
            clk_sti <= '0', '1' after CLK_PERIOD/2;
            wait for CLK_PERIOD;
        end loop;
        wait;
    end process clk_gen;
    ---------------------------------------------------------------------------

    --| Simulation process |---------------------------------------------------
    sim_proc : process is

        --| Reset sequence |---------------------------------------------------
        procedure reset_seq(signal reset    : out std_logic;
                            signal stimulus : out avalon_slave_in_t) is
        begin
            reset               <= '1';
            stimulus.address    <= std_logic_vector(to_unsigned(0, stimulus.address'length));
            stimulus.write      <= '0';
            stimulus.read       <= '0';
            stimulus.byteenable <= (others => '0');
            stimulus.writedata  <= (others => '0');
            cycle(clk_sti, 1);
            reset               <= '0';
            cycle(clk_sti, 1);
        end reset_seq;
        -----------------------------------------------------------------------


    begin

        -- user notification
        logger.log_note("Start of simulation");

        -- Reset system at the beginning
        reset_seq(rst_sti, stimulus_sti);

        case TESTCASE is
            when 0 => -- run all tests
                test_waitrequest_read(clk_sti, observed_obs, stimulus_sti);
                test_waitrequest_write(clk_sti, observed_obs, stimulus_sti);
                test_readdatavalid_read(clk_sti, observed_obs, stimulus_sti);
                test_readdatavalid_write(clk_sti, observed_obs, stimulus_sti);
                test_byteenable(DATASIZE, clk_sti, observed_obs, stimulus_sti);   
                             

                test_status(N, clk_sti, observed_obs, stimulus_sti);
                test_read_after_write(N, clk_sti, observed_obs, stimulus_sti);
                test_values(DATASIZE, N, clk_sti, observed_obs, stimulus_sti);

                test_computing(N, clk_sti, observed_obs, stimulus_sti);
                test_datasize(DATASIZE, N, clk_sti, observed_obs, stimulus_sti);
                test_overflow(DATASIZE, N, clk_sti, observed_obs, stimulus_sti);
                test_n(N, clk_sti, observed_obs, stimulus_sti);
                

            when 1 => -- test avalon
                test_waitrequest_read(clk_sti, observed_obs, stimulus_sti);
                test_waitrequest_write(clk_sti, observed_obs, stimulus_sti);
                test_readdatavalid_read(clk_sti, observed_obs, stimulus_sti);
                test_readdatavalid_write(clk_sti, observed_obs, stimulus_sti);
                test_byteenable(DATASIZE, clk_sti, observed_obs, stimulus_sti);   

            when 2 => -- test control
                test_status(N, clk_sti, observed_obs, stimulus_sti);
                test_read_after_write(N, clk_sti, observed_obs, stimulus_sti);
                test_values(DATASIZE, N, clk_sti, observed_obs, stimulus_sti);

            when 3 => -- test computing
                test_computing(N, clk_sti, observed_obs, stimulus_sti);
                test_datasize(DATASIZE, N, clk_sti, observed_obs, stimulus_sti);
                test_overflow(DATASIZE, N, clk_sti, observed_obs, stimulus_sti);
                test_n(N, clk_sti, observed_obs, stimulus_sti);
                
 
            when others =>
                null;
        end case;

        -- Allow to store results in an HTML file
        logger.enable_log_to_file("results.html");

        logger.final_report;

        sim_end_s <= true;
        wait;
    end process sim_proc;
    ---------------------------------------------------------------------------

end testbench;
-------------------------------------------------------------------------------
