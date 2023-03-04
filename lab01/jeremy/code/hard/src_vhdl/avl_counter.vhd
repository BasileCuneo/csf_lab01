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
        avl_clk_i             : in  std_logic;
        avl_reset_i           : in  std_logic;
        avl_address_i         : in  std_logic_vector(2 downto 0);
        avl_write_i           : in  std_logic;
        avl_writedata_i       : in  std_logic_vector(31 downto 0);
        avl_read_i            : in  std_logic;
        avl_readdatavalid_o   : out std_logic;
        avl_readdata_o        : out std_logic_vector(31 downto 0);
        avl_byteenable_i      : in  std_logic_vector(3 downto 0);
        avl_waitrequest_o     : out std_logic
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
    signal avl_cpt_fut_s      : std_logic_vector(31 downto 0);
    signal avl_old_data_s     : std_logic_vector(31 downto 0);
    
    --| Components declaration |--------------------------------------------------------------


begin

process (all) is --masquage des entrées
begin
    if(avl_byteenable_i(0) = '1') then
        avl_data_masked_s(7 downto 0) <= avl_writedata_i(7 downto 0);
    else
        avl_data_masked_s(7 downto 0) <= avl_old_data_s(7 downto 0);
    end if;
    
    if(avl_byteenable_i(1) = '1') then
        avl_data_masked_s(15 downto 8) <= avl_writedata_i(15 downto 8);
    else
        avl_data_masked_s(15 downto 8) <= avl_old_data_s(15 downto 8);
    end if;
    
    if(avl_byteenable_i(2) = '1') then
        avl_data_masked_s(23 downto 16) <= avl_writedata_i(23 downto 16);
    else
        avl_data_masked_s(23 downto 16) <= avl_old_data_s(23 downto 16);
    end if;
    
    if(avl_byteenable_i(3) = '1') then
        avl_data_masked_s(31 downto 24) <= avl_writedata_i(31 downto 24);
    else
        avl_data_masked_s(31 downto 24) <= avl_old_data_s(31 downto 24);
    end if;
end process;

process (all) is --enable en écriture
begin
    if(avl_address_i = "010") then
        avl_ctrl_cpt_s <= avl_write_i;
    elsif(avl_address_i = "011") then
        avl_en_reg1_s <= avl_write_i;
    elsif(avl_address_i = "100") then
        avl_en_reg2_s <= avl_write_i;
    elsif(avl_address_i = "101") then
        avl_en_reg3_s <= avl_write_i;
    elsif(avl_address_i = "110") then
        avl_en_reg4_s <= avl_write_i;
    end if;
end process;

process (all) is --waitrequest et readdatavalid
begin
    if(avl_reset_i = '1') then
        avl_write_reg_s <= '0';
        avl_read_reg_s <= '0';
    elsif(rising_edge(avl_clk_i)) then
        avl_write_reg_s <= avl_write_i;
        avl_read_reg_s <= avl_read_i;
    end if;
end process;

process (all) is --décodage de sortie
begin
    if(avl_address_i = "000") then
        avl_old_data_s <= AVL_CSTE;
    elsif(avl_address_i = "001") then
        avl_old_data_s <= avl_cpt_pres_s;
    elsif(avl_address_i = "010") then
        avl_old_data_s <= x"0000";
    elsif(avl_address_i = "011") then
        avl_old_data_s <= avl_reg1_pres_s;
    elsif(avl_address_i = "100") then
        avl_old_data_s <= avl_reg2_pres_s;
    elsif(avl_address_i = "101") then
        avl_old_data_s <= avl_reg3_pres_s;
    elsif(avl_address_i = "110") then
        avl_old_data_s <= avl_reg4_pres_s;
    elsif(avl_address_i = "111") then
        avl_old_data_s <= x"0000";
    end if;
    
    if(avl_reset_i = '1') then
        avl_readdata_s = x"00000000";
    elsif(rising_edge(avl_clk_i) and avl_readdatavalid_s = '1') then
        avl_readdata_s <= avl_old_data_s;

end process;

process (all) is --registres reg1 à 4
begin
    if(avl_reset_i = '1') then
        avl_reg1_pres_s <= x"00000000";
        avl_reg2_pres_s <= x"00000000";
        avl_reg3_pres_s <= x"00000000";
        avl_reg4_pres_s <= x"00000000";
        
    elsif(rising_edge(avl_clk_i)) then
        if(avl_en_reg1_s = '1') then
            avl_reg1_pres_s <= avl_writedata_i;
        elsif(avl_en_reg2_s = '1') then
            avl_reg2_pres_s <= avl_writedata_i;
        elsif(avl_en_reg3_s = '1') then
            avl_reg3_pres_s <= avl_writedata_i;
        elsif(avl_en_reg4_s = '1') then
            avl_reg4_pres_s <= avl_writedata_i;
        end if;
    end if;
end process;

process (all) is --compteur
begin
    if(avl_data_masked_s = x"00000001") then
        avl_cpt_fut_s <= x"00000000";
    else
        if(avl_data_masked_s = x"00000002") then
            avl_cpt_fut_s <= std_logic_vector((avl_cpt_pres_s) +1);
        else
            avl_cpt_fut_s <= avl_cpt_pres_s;
        end if;
    end if;
        
    if(avl_reset_i = '1') then
        avl_cpt_pres_s <= x"00000000";
        
    elsif(rising_edge(avl_clk_i) and avl_ctrl_cpt_s = '1') then
        avl_cpt_pres_s <= avl_cpt_fut_s;
    end if;
end process;

avl_waitrequest_s <= ((not avl_write_reg_s) and avl_write_i) or ((not avl_read_reg_s) and avl_read_i);
avl_readdatavalid_s <= (not avl_waitrequest_s) and avl_read_i;

avl_readdatavalid_o <= avl_readdatavalid_s;
avl_readdata_o <= avl_readdata_s;
avl_waitrequest_o <= avl_waitrequest_s;

end behave;
