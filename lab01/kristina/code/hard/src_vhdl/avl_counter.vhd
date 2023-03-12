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
-- Author               : Kristina Greco
-- Date                 : 04.03.2023
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
-- Ver    Date        Engineer
-- 0.1    10.03.2023  Kristina Greco
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
    avl_clk : in std_logic;
    avl_reset : in std_logic;
    avl_address : in std_logic_vector(2 downto 0);
    avl_writedata : in std_logic_vector(31 downto 0);
    avl_write : in std_logic;
    avl_read : in std_logic;
    avl_byteenable : in std_logic_vector(3 downto 0);
    avl_waitrequest : out std_logic;
    avl_readdatavalid : out std_logic;
    avl_readdata : out std_logic_vector(31 downto 0)
);
end avl_counter;




architecture behave of avl_counter is

constant AVL_CSTE : std_logic_vector := x"D0D0C5F0";
constant STATE_WRITE : integer := 0;
constant STATE_READ : integer := 1;
constant STATE_NO_WRITE_READ : integer := 2;

signal state_s : integer;
signal avl_waitrequest_s : std_logic;
signal avl_readdatavalid_s : std_logic;
signal avl_readdata_s : std_logic_vector(31 downto 0);
signal avl_reg1_s : std_logic_vector(31 downto 0);
signal avl_reg2_s : std_logic_vector(31 downto 0);
signal avl_reg3_s : std_logic_vector(31 downto 0);
signal avl_reg4_s : std_logic_vector(31 downto 0);
signal avl_en_r1_s : std_logic;
signal avl_en_r2_s : std_logic;
signal avl_en_r3_s : std_logic;
signal avl_en_r4_s : std_logic;
signal avl_data_masked_s : std_logic_vector(31 downto 0);
signal avl_control_cpt_s : std_logic;
signal avl_control_cpt_old_s : std_logic;
signal avl_cpt_s : std_logic_vector(31 downto 0);

begin

avl_data_masked_s(7 downto 0) <= avl_writedata(7 downto 0) when avl_byteenable(0) = '1' else avl_readdata_s(7 downto 0);
avl_data_masked_s(15 downto 8) <= avl_writedata(15 downto 8) when avl_byteenable(1) = '1' else avl_readdata_s(15 downto 8);
avl_data_masked_s(23 downto 16) <= avl_writedata(23 downto 16) when avl_byteenable(2) = '1' else avl_readdata_s(23 downto 16);
avl_data_masked_s(31 downto 24) <= avl_writedata(31 downto 24) when avl_byteenable(3) = '1' else avl_readdata_s(31 downto 24);


--Gestion du wait_request et du readdatavalid
--on part du principe que read et write ne sont jamais actifs au meme temps
process(avl_reset, avl_clk)
begin
    if(avl_reset = '1') then
        state_s <= STATE_NO_WRITE_READ;
    elsif rising_edge(avl_clk) then
        case state_s is
            when STATE_NO_WRITE_READ =>
                if avl_write = '1' then
                    state_s <= STATE_WRITE;
                elsif avl_read = '1' then
                    state_s <= STATE_READ;
                end if;
            when STATE_WRITE =>
                if avl_write = '0' then
                    state_s <= STATE_NO_WRITE_READ;
                end if;
            when STATE_READ =>
                if avl_read = '0' then
                    state_s <= STATE_NO_WRITE_READ;
                end if;
            when others =>
                    null;
        end case;
    end if;
end process;


--Gestion de readdata grace a l'adresse
process(avl_reset, avl_clk)
begin
    if(avl_reset = '1') then
        avl_readdata_s <= (others => '0');
    elsif rising_edge(avl_clk) then
        if(avl_read = '1') then
            case to_integer(unsigned(avl_address)) is
                when 0 =>
                    avl_readdata_s <= AVL_CSTE;
                when 1 => 
                    avl_readdata_s <= avl_cpt_s;
                when 2 =>
                    null;
                when 3 => 
                    avl_readdata_s <= avl_reg1_s;
                when 4 =>
                    avl_readdata_s <= avl_reg2_s;
                when 5 => 
                    avl_readdata_s <= avl_reg3_s;
                when 6 => 
                    avl_readdata_s <= avl_reg4_s;
                when others =>
                    null;
            end case;
        end if;
    end if;
end process;


process (avl_reset, avl_clk)
begin
    if(avl_reset = '1') then
        avl_control_cpt_s <= '0';
        avl_en_r1_s <= '0';
        avl_en_r2_s <= '0';
        avl_en_r3_s <= '0';
        avl_en_r4_s <= '0';
    elsif rising_edge(avl_clk) then
        avl_control_cpt_s <= '0';
        avl_en_r1_s <= '0';
        avl_en_r2_s <= '0';
        avl_en_r3_s <= '0';
        avl_en_r4_s <= '0';

        if(avl_write = '1') then
            case avl_address is
                when "000" => null;
                when "001" => null;
                when "010" => avl_control_cpt_s <= '1';
                when "011" => avl_en_r1_s <= '1';  --activation du registre 1
                when "100" => avl_en_r2_s <= '1';
                when "101" => avl_en_r3_s <= '1';
                when "110" => avl_en_r4_s <= '1';
                when others => null;
            end case;
        end if;
    end if;
end process;



-- Gestion des 4 registres
process (avl_reset, avl_clk)
begin
    if(avl_reset = '1') then
        avl_reg1_s <= (others => '0');
        avl_reg2_s <= (others => '0');
        avl_reg3_s <= (others => '0');
        avl_reg4_s <= (others => '0');
    elsif rising_edge(avl_clk) then
        if(avl_en_r1_s = '1') then
            avl_reg1_s <= avl_data_masked_s;
        end if;
        if(avl_en_r2_s = '1') then
            avl_reg2_s <= avl_data_masked_s;
        end if;
        if(avl_en_r3_s = '1') then
            avl_reg3_s <= avl_data_masked_s;
        end if;
        if(avl_en_r4_s = '1') then
            avl_reg4_s <= avl_data_masked_s;
        end if;
    end if;
end process;


-- Gestion de la partie controle du compteur
process (avl_reset, avl_clk)
begin
    if(avl_reset = '1') then
        avl_control_cpt_old_s <= '0';
    elsif rising_edge(avl_clk) then
        avl_control_cpt_old_s <= avl_control_cpt_s;
    end if;
end process;


process (avl_reset, avl_clk)
begin
    if(avl_reset = '1') then
        avl_cpt_s <= (others => '0');
    elsif rising_edge(avl_clk) then
        if(avl_control_cpt_s = '1') then
            case to_integer(unsigned(avl_data_masked_s)) is
                when 1 =>
                    avl_cpt_s <= (others => '0');
                when 2 =>
                    if(avl_control_cpt_old_s = '0') then
                        avl_cpt_s <= std_logic_vector(unsigned(avl_cpt_s) + 1);
                    end if;
                when others =>
                    null;
            end case;
        end if;
    end if;
end process;

avl_waitrequest_s <= '1' when (state_s = STATE_NO_WRITE_READ and (avl_read = '1' or avl_write = '1')) else '0';
avl_readdatavalid_s <= '1' when (avl_read ='1' and state_s = STATE_READ) else '0';

avl_readdata <= avl_readdata_s;
avl_waitrequest <= avl_waitrequest_s;
avl_readdatavalid <= avl_readdatavalid_s;

end behave;

