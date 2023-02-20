library ieee;
use ieee.std_logic_1164.all;

package avalon_types_pkg is

      --| Types |-----------------------------------------------------------------
      type avalon_slave_in_t is record
          address    : std_logic_vector;
          byteenable : std_logic_vector(1 downto 0);
          read       : std_logic;
          write      : std_logic;
          writedata  : std_logic_vector(15 downto 0);
      end record;

      type avalon_slave_out_t is record
          waitrequest   : std_logic;
          readdatavalid : std_logic;
          readdata      : std_logic_vector(15 downto 0);
      end record;

end avalon_types_pkg;
