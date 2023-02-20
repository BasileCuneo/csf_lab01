------------------------------------------------------------------------------------------
-- HEIG-VD
-- Haute Ecole d'Ingenerie et de Gestion du Canton de Vaud
-- School of Business and Engineering in Canton de Vaud
------------------------------------------------------------------------------------------
-- REDS Institute
-- Reconfigurable Embedded Digital Systems
------------------------------------------------------------------------------------------
--
-- File                 : avl_counter.vhd
-- Author               : ...
-- Date                 : ...
--
-- Context              : Simple Avalon counter component
--
------------------------------------------------------------------------------------------
-- Description :
--
------------------------------------------------------------------------------------------
-- Dependencies :
--
------------------------------------------------------------------------------------------
-- Modifications :
-- Ver    Date        Engineer    Comments
-- 0.1    See header  ...         Initial version

------------------------------------------------------------------------------------------

library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

entity avl_counter is
    generic (
        -- configurable processing time
        PROC_TIME : integer range 0 to 15 := 0
    );
    port(
        -- Avalon bus
        avl_clk             : in  std_logic;
        avl_reset           : in  std_logic;
        avl_address         : in  std_logic_vector(2 downto 0);
        avl_write           : in  std_logic;
        avl_writedata       : in  std_logic_vector(31 downto 0);
        avl_read            : in  std_logic;
        avl_readdatavalid   : out std_logic;
        avl_readdata        : out std_logic_vector(31 downto 0);
        avl_byteenable		: in  std_logic_vector(3 downto 0);
        avl_waitrequest     : out std_logic
  );
end avl_counter;

architecture behave of avl_counter is

    --| Constants declarations |--------------------------------------------------------------


    --| Signals declarations   |--------------------------------------------------------------


    --| Components declaration |--------------------------------------------------------------


begin

end behave;
