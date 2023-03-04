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
    signal avl_old_data_s     : std_logic_vector(31 downto 0);
    
    signal state_s            : integer;
    
    --| Components declaration |--------------------------------------------------------------


begin

process (avl_clk_i, avl_reset_i) begin --masquage des entrées
    if(avl_reset_i = '1') then
        avl_data_masked_s <= (others => '0');
        
    elsif(rising_edge(avl_clk_i)) then
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
    end if;
end process;

process (avl_clk_i, avl_reset_i) begin 
    if(avl_reset_i = '1') then
        state_s <= 0;
        avl_readdatavalid_s <= '0';
        avl_waitrequest_s <= '0';
        
    elsif(rising_edge(avl_clk_i)) then
        avl_readdatavalid_s <= '0';
        avl_waitrequest_s <= '0';
        
        case state_s is
            when 0 =>
                if(avl_read_i = '1') then
                    state_s <= 1;
                end if;
                if(avl_write_i = '1') then
                    state_s <= 3;
                end if;
            when 1 => 
                avl_waitrequest_s <= '1';
                state_s <= 2;
            when 2 =>
                avl_readdatavalid_s <= '1';
                if(avl_read_i = '0') then
                    state_s <= 0;
                end if;
            when 3 => 
                avl_waitrequest_s <= '1';
                state_s <= 4;
            when 4 =>
                if(avl_write_i = '0') then
                    state_s <= 0;
                end if;
            when others => null;
        end case;
    end if;
    
end process;

process (avl_clk_i, avl_reset_i) begin --décodage read
    if(avl_reset_i = '1') then
        avl_old_data_s <= (others => '0');
        
    elsif(rising_edge(avl_clk_i)) then
        if(avl_read_i = '1') then
            case to_integer(unsigned(avl_address_i)) is
                when 0 => 
                    avl_old_data_s <= AVL_CSTE;
                when 1 =>
                    avl_old_data_s <= avl_cpt_pres_s;
                when 2 =>
                    null;
                when 3 =>
                    avl_old_data_s <= avl_reg1_pres_s;
                when 4 =>
                    avl_old_data_s <= avl_reg2_pres_s;
                when 5 =>
                    avl_old_data_s <= avl_reg3_pres_s;
                when 6 =>
                    avl_old_data_s <= avl_reg4_pres_s;
                when others =>
                    null;
            end case;
        end if;
    end if;
        
end process;

process (avl_clk_i, avl_reset_i) begin --old_data to readdata 
    if(avl_reset_i = '1') then
        avl_readdata_s <= (others => '0');
        
    elsif(rising_edge(avl_clk_i)) then
        if(avl_readdatavalid_s = '1') then
            avl_readdata_s <= avl_old_data_s;
        end if;
    end if;
end process;

process (avl_clk_i, avl_reset_i) begin --décodage write 
    if(avl_reset_i = '1') then
        avl_ctrl_cpt_s <= '0';
        avl_en_reg1_s <= '0';
        avl_en_reg2_s <= '0';
        avl_en_reg3_s <= '0';
        avl_en_reg4_s <= '0';
        
    elsif(rising_edge(avl_clk_i)) then
        avl_ctrl_cpt_s <= '0';
        avl_en_reg1_s <= '0';
        avl_en_reg2_s <= '0';
        avl_en_reg3_s <= '0';
        avl_en_reg4_s <= '0';
        
        if(avl_write_i = '1') then
            case to_integer(unsigned(avl_address_i)) is
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

process (avl_clk_i, avl_reset_i) begin --registres reg1 à 4
    if(avl_reset_i = '1') then
        avl_reg1_pres_s <= (others => '0');
        avl_reg2_pres_s <= (others => '0');
        avl_reg3_pres_s <= (others => '0');
        avl_reg4_pres_s <= (others => '0');
        
    elsif(rising_edge(avl_clk_i)) then
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

process (avl_clk_i, avl_reset_i) begin --compteur
    if(avl_reset_i = '1') then
        avl_cpt_pres_s <= (others => '0');
        
    elsif(rising_edge(avl_clk_i)) then
        if(avl_ctrl_cpt_s = '1') then
            case to_integer(unsigned(avl_data_masked_s)) is
                when 1 =>
                    avl_cpt_pres_s <= (others => '0');
                when 2 =>
                    avl_cpt_pres_s <= std_logic_vector(unsigned(avl_cpt_pres_s) +1);
                when others =>
                    null;
            end case;  
        end if;
    end if;
end process;


avl_readdatavalid_o <= avl_readdatavalid_s;
avl_readdata_o <= avl_readdata_s;
avl_waitrequest_o <= avl_waitrequest_s;

end behave;
