
library ieee;
use ieee.std_logic_1164.all;

use work.project_logger_pkg.all;

package common_pkg is

        --| Procedures |-----------------------------------------------------------
        -- simulator cycle
        procedure cycle(signal clk : in std_logic; nb_cycle : integer := 1);

            -- BFM for an avalon read request
            procedure check(variable val_write : in integer;
                            variable val_read  : in integer);

end common_pkg;

package body common_pkg is

      -- BFM for an avalon read request
      procedure check(variable val_write : in integer;
                      variable val_read  : in integer) is
      begin
         -- CHECK
         if(val_write /= val_read) then
              logger.log_error("Error : val write = " & integer'image(val_write)
                               & " /= " & integer'image(val_read) & " = val read");
         end if;
      end check;

        --| Procedures |-----------------------------------------------------------
        -- simulator cycle
        procedure cycle(signal clk : in std_logic; nb_cycle : integer := 1) is
        begin
            for i in 1 to nb_cycle loop
                wait until falling_edge(clk);
                wait for 2 ns;
            end loop;
        end cycle;

end common_pkg;
