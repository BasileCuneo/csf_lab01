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
-- Author               : Jérémy Vonlanthen
-- Date                 : 03.03.2023
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
-- 0.1    See header  JVN         Initial version

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
        avl_byteenable      : in  std_logic_vector(3 downto 0);
        avl_waitrequest     : out std_logic
  );
end avl_counter;

architecture behave of avl_counter is

    --| Constants declarations |--------------------------------------------------------------
    constant AVL_CSTE : std_logic_vector := x"D0D0C5F0";

    --| Signals declarations   |--------------------------------------------------------------
    signal avl_en_reg1_s      : std_logic;
    signal avl_en_reg2_s      : std_logic;
    signal avl_en_reg3_s      : std_logic;
    signal avl_en_reg4_s      : std_logic;
    signal avl_ctrl_cpt_s     : std_logic;
    signal avl_ctrl_cpt_old_s : std_logic;
    
    signal avl_write_reg_s    : std_logic;
    signal avl_read_reg_s     : std_logic;
    signal avl_waitrequest_s  : std_logic;
    signal avl_readdatavalid_s: std_logic;
    
    signal avl_data_masked_s  : std_logic_vector(31 downto 0);
    signal avl_readdata_s     : std_logic_vector(31 downto 0);
    signal avl_reg1_pres_s    : std_logic_vector(31 downto 0);
    signal avl_reg2_pres_s    : std_logic_vector(31 downto 0);
    signal avl_reg3_pres_s    : std_logic_vector(31 downto 0);
    signal avl_reg4_pres_s    : std_logic_vector(31 downto 0);
    signal avl_cpt_pres_s     : std_logic_vector(31 downto 0);
    
    signal state_s            : integer;
    
    --| Components declaration |--------------------------------------------------------------


begin

avl_data_masked_s(7 downto 0) <= avl_writedata(7 downto 0) when avl_byteenable(0) = '1' else avl_readdata_s(7 downto 0);
avl_data_masked_s(15 downto 8) <= avl_writedata(15 downto 8) when avl_byteenable(1) = '1' else avl_readdata_s(15 downto 8);
avl_data_masked_s(23 downto 16) <= avl_writedata(23 downto 16) when avl_byteenable(2) = '1' else avl_readdata_s(23 downto 16);
avl_data_masked_s(31 downto 24) <= avl_writedata(31 downto 24) when avl_byteenable(3) = '1' else avl_readdata_s(31 downto 24);

process (avl_clk, avl_reset) begin 
    if(avl_reset = '1') then
        state_s <= 0;
        
    -- MSS pour waitrequest et readdatavalid 
    elsif(rising_edge(avl_clk)) then
        case state_s is
            when 0 =>
                if(avl_read = '1') then
                    state_s <= 1;
                end if;
                if(avl_write = '1') then
                    state_s <= 2;
                end if;
            when 1 => 
                if(avl_read = '0') then
                    state_s <= 0;
                end if;
            when 2 =>
                if(avl_write = '0') then
                    state_s <= 0;
                end if;
            when others => null;
        end case;
    end if;
end process;

avl_waitrequest_s <= '1' when state_s = 0 and (avl_read = '1' or avl_write = '1') else '0';
avl_readdatavalid_s <= '1' when (state_s = 1 and avl_read = '1') else '0';

process (avl_clk, avl_reset) begin --décodage read
    if(avl_reset = '1') then
        avl_readdata_s <= (others => '0');
        
    elsif(rising_edge(avl_clk)) then
        if(avl_read = '1') then
            case to_integer(unsigned(avl_address)) is
                when 0 => 
                    avl_readdata_s <= AVL_CSTE;
                when 1 =>
                    avl_readdata_s <= avl_cpt_pres_s;
                when 2 =>
                    null;
                when 3 =>
                    avl_readdata_s <= avl_reg1_pres_s;
                when 4 =>
                    avl_readdata_s <= avl_reg2_pres_s;
                when 5 =>
                    avl_readdata_s <= avl_reg3_pres_s;
                when 6 =>
                    avl_readdata_s <= avl_reg4_pres_s;
                when others =>
                    null;
            end case;
        end if;
    end if;
        
end process;

process (avl_clk, avl_reset) begin --décodage write 
    if(avl_reset = '1') then
        avl_ctrl_cpt_s <= '0';
        avl_en_reg1_s <= '0';
        avl_en_reg2_s <= '0';
        avl_en_reg3_s <= '0';
        avl_en_reg4_s <= '0';
        
    elsif(rising_edge(avl_clk)) then
        --valeur par défaut
        avl_ctrl_cpt_s <= '0';
        avl_en_reg1_s <= '0';
        avl_en_reg2_s <= '0';
        avl_en_reg3_s <= '0';
        avl_en_reg4_s <= '0';
        
        if(avl_write = '1') then
            case to_integer(unsigned(avl_address)) is --registres enable
                when 0 to 1 => 
                    null;
                when 2 =>
                    avl_ctrl_cpt_s <= '1';
                when 3 =>
                    avl_en_reg1_s <= '1';
                when 4 =>
                    avl_en_reg2_s <= '1';
                when 5 =>
                    avl_en_reg3_s <= '1';
                when 6 =>
                    avl_en_reg4_s <= '1';
                when others =>
                    null;
            end case;
        end if;
    end if;
end process;

process (avl_clk, avl_reset) begin --registres reg1 à 4
    if(avl_reset = '1') then
        avl_reg1_pres_s <= (others => '0');
        avl_reg2_pres_s <= (others => '0');
        avl_reg3_pres_s <= (others => '0');
        avl_reg4_pres_s <= (others => '0');
        
    elsif(rising_edge(avl_clk)) then --mise à jour des registres
        if(avl_en_reg1_s = '1') then
            avl_reg1_pres_s <= avl_data_masked_s;
        elsif(avl_en_reg2_s = '1') then
            avl_reg2_pres_s <= avl_data_masked_s;
        elsif(avl_en_reg3_s = '1') then
            avl_reg3_pres_s <= avl_data_masked_s;
        elsif(avl_en_reg4_s = '1') then
            avl_reg4_pres_s <= avl_data_masked_s;
        end if;
    end if;
end process;

process (avl_clk, avl_reset) begin
    if(avl_reset = '1') then
        avl_ctrl_cpt_old_s <= '0';
    elsif(rising_edge(avl_clk)) then
        avl_ctrl_cpt_old_s <= avl_ctrl_cpt_s;
    end if;
end process;

process (avl_clk, avl_reset) begin --compteur
    if(avl_reset = '1') then
        avl_cpt_pres_s <= (others => '0');
        
    elsif(rising_edge(avl_clk)) then
        if(avl_ctrl_cpt_s = '1') then
            case to_integer(unsigned(avl_data_masked_s)) is
                when 1 =>
                    avl_cpt_pres_s <= (others => '0');
                when 2 =>
                    if(avl_ctrl_cpt_old_s = '0') then --edge detection
                        avl_cpt_pres_s <= std_logic_vector(unsigned(avl_cpt_pres_s) +1);
                    end if;
                when others =>
                    null;
            end case;  
        end if;
    end if;
end process;

--affectation des signaux aux sorties
avl_readdatavalid <= avl_readdatavalid_s;
avl_waitrequest <= avl_waitrequest_s;
avl_readdata <= avl_readdata_s;

end behave;
