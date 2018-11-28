-- *****************************************
-- ** Creation des composants spécifiques **
-- *****************************************
library IEEE;
use IEEE.std_logic_1164.all;

package package_son_out is

-- ** Séquencement des données vers le codec **
component muxseqdatout is
port(
     clk        : in std_logic;
     divun      : in integer range 0 to 3;
     divdeu     : in integer range 0 to 255;
     valin      : in std_logic_vector (15 downto 0);

     AUD_DACDAT  : out std_logic;
     AUD_DACLRCK : out std_logic;
     wrLeft      : out std_logic;
     wrRight     : out std_logic
     );
end component;

-- ** ROM contenant les valeurs des registres du codec **
component rommuxsonout IS
PORT(
     address : IN STD_LOGIC_VECTOR (3 DOWNTO 0);
     clock   : IN STD_LOGIC ;
     q       : OUT STD_LOGIC_VECTOR (15 DOWNTO 0)
     );
END component;

-- ** ecriture dans les registres du codec **
component regofcodec is
port(
     clk      : in std_logic;
     I2C_SCLK : out std_logic;
     I2C_SDAT : inout std_logic
     );
end component;

-- ** gestion des horloges de séquencement des opérations **
component seqdata
port(
     clk        : in std_logic;
     clkdivun   : out integer range 0 to 3;
     clkdivdeu  : out integer range 0 to 255;
     mclk       : out std_logic
     );
end component;

end package_son_out;


-- ********************************************
-- ** Séquencement des données vers le codec **
-- ********************************************
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;

entity muxseqdatout is
port(
     clk        : in std_logic;
     divun      : in integer range 0 to 3;
     divdeu     : in integer range 0 to 255;
     valin      : in std_logic_vector (15 downto 0);

     AUD_DACDAT  : out std_logic;
     AUD_DACLRCK : out std_logic;
     wrLeft      : out std_logic := '0';
     wrRight     : out std_logic := '0'
     );
end muxseqdatout;

architecture muxseqdatout_arch of muxseqdatout is
signal  svalin : std_logic_vector (15 downto 0):= "0000000000000000";
signal sense: std_logic := '1';

begin
    process(clk)
        begin
        if clk'event and clk = '1' then

        case (divdeu) is
            when 0 =>
                if divun = 3 then
                svalin <= valin;
                end if;
            when 1 =>
                if divun = 3 then
                sense <= '1';
                end if;
            when 2|3|4|5|6|7|8|9|10|11|12|13|14|15|16 =>
                if divun = 3 then
                    myloopa: for ind in 0 to 14 loop
                        svalin(ind + 1) <= svalin(ind);
                        end loop myloopa;
                end if;
            when 17 =>
                if divun = 3 then
                wrLeft <= '1';
                end if;
            when 126 =>
                if divun = 3 then
                wrLeft <= '0';
                end if;
            when 127 =>
                if divun = 3 then
                svalin <= valin;
                end if;
            when 128 =>
                if divun = 3 then
                    sense <= '0';
                end if;
            when 129|130|131|132|133|134|135|136|137|138|139|140|141|142|143 =>
                if divun = 3 then
                    taloopa: for ind in 0 to 14 loop
                        svalin(ind + 1) <= svalin(ind);
                        svalin(0) <= svalin(15);
                        end loop taloopa;
                end if;
            when 144 =>
                if divun = 3 then
                        wrRight <= '1';
                end if;
            when 255 =>
                if divun = 3 then
                wrRight <= '0';
                end if;
            when others => null;
            end case;
        end if;
    end process;
    AUD_DACDAT <= svalin(15);
    AUD_DACLRCK <= sense;
end muxseqdatout_arch;


-- ***********************************************************
-- **   ROM contenant les valeurs des registres du codec    **
-- ***********************************************************
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;

ENTITY rommuxsonout IS
PORT(
     clock   : in STD_LOGIC ;
     address : IN STD_LOGIC_VECTOR (3 DOWNTO 0);

     q       : OUT STD_LOGIC_VECTOR (15 DOWNTO 0)
     );
END rommuxsonout;

architecture rommuxsonout_arch of rommuxsonout is

type ROM_ARRAY is array(15 downto 0) of std_logic_vector(15 downto 0);
constant Rom_Val : ROM_ARRAY := (
-- format (15)    : inc      (0 ou 1) si 0 alors fin mémoire
--        (14..8) : registre (0 -> x"7F")
--        ( 7..0) : donnée   (0 -> x"FF")

    0  =>    "1001111000000000", -- reset interface
    1  =>    "1001001000000000", -- inactive interface
    2  =>    "1000111000000001", -- MSB first Left justified
    3  =>    "1001001000000001", -- active interface
    4  =>    "1000110001100111", -- Power On pour Device, Line In, Line Out et DAC (on = 0)
    5  =>    "1000101000000001", -- Softmute Off + suppression filtre
    6  =>    "1000100000010010", -- DAC en sortie, Micro muet
    7  =>    "0000010101111001", -- Gain de 0 db sur les deux voies en sortie
    others => (others => '0'));  -- c'est fini

Begin

process(clock)
Begin
  if rising_edge(clock) then
      q <= Rom_Val(conv_integer(unsigned(address)));
  end if;
end process;

end rommuxsonout_arch;
-- ***********************************************************
-- ** Déclaration de l'ecriture dans les registres du codec **
-- ***********************************************************

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;

entity regofcodec is
port(
     clk      : in std_logic;
     I2C_SCLK : out std_logic;
     I2C_SDAT : inout std_logic
     );
end regofcodec;

architecture regofcodec_arch of regofcodec is

-- component work.package_son_out.rommuxsonout IS
-- PORT(
--      address : IN STD_LOGIC_VECTOR (3 DOWNTO 0);
--      clock   : IN STD_LOGIC ;
--      q       : OUT STD_LOGIC_VECTOR (15 DOWNTO 0)
--      );
-- END component;

signal geneck : integer range 0 to 5 := 0;
signal tempo : integer range 0 to 26 := 0;
signal pas : integer range 0 to 33 := 0;
signal another : std_logic := '1';
signal wrone, wrtwo, wrin : std_logic := '0';
signal sbusy :std_logic := '0';
signal sclk, ssclk :std_logic := '1';
signal sdout, dir :std_logic := '0';
signal sdin :std_logic := '1';
signal addmem : std_logic_vector (3 downto 0) := "0000";
signal valmem : std_logic_vector (15 downto 0);

begin

-- Instantiating ROM

rom0 : work.package_son_out.rommuxsonout
PORT MAP (
        address  => addmem,
        clock    => clk,
        q        => valmem
        );

    process(clk)
    begin
      if clk'event and clk = '1' then
         if tempo = 26 then
             tempo <= 0;
             if sbusy = '0' then
                pas <= 0;
                sdout <= '1';
                dir <= '1';
             end if;
            if geneck = 5 then geneck <= 0;
            else geneck <= geneck + 1;
            end if;
            if geneck = 0 then sclk <= '1';
            end if;
            if geneck = 4 then sclk <= '0';
            end if;
            if geneck = 4 then
                wrone <= another;
                wrtwo <= wrone;
                if wrin = '1' then sbusy <= '1';
                end if;
            end if;
            if sbusy = '1' then
                case (pas) is
                    when 0 =>
                        if geneck = 1 then
                        sdout <= '0';
                        pas <= pas + 1;
                        end if;
                    when 1 =>
                        if geneck = 5 then
                        sdout <= '0';
                        pas <= pas + 1;
                        end if;
                    when 2 =>
                        if geneck = 5 then
                        sdout <= '0';
                        pas <= pas + 1;
                        another <= '0';
                        end if;
                    when 3 =>
                        if geneck = 5 then
                        sdout <= '1';
                        pas <= pas + 1;
                        end if;
                    when 4 =>
                        if geneck = 5 then
                        sdout <= '1';
                        pas <= pas + 1;
                        end if;
                    when 5 =>
                        if geneck = 5 then
                        sdout <= '0';
                        pas <= pas + 1;
                        end if;
                    when 6 =>
                        if geneck = 5 then
                        sdout <= '1';
                        pas <= pas + 1;
                        end if;
                    when 7 =>
                        if geneck = 5 then
                        sdout <= '0';
                        pas <= pas + 1;
                        end if;
                    when 8 =>
                        if geneck = 5 then
                        sdout <= '0';
                        pas <= pas + 1;
                        end if;
                    when 9 =>
                        if geneck = 5 then
                        sdout <= '0';
                        dir <= '0';
                        pas <= pas + 1;
                        end if;
                    when 10 =>
                        if geneck = 2 then
                            if sdin = '1' then
                            sbusy <= '0';
                            else
                            pas <= pas + 1;
                            end if;
                        end if;
                    when 11 =>
                        if geneck = 5 then
                        dir <= '1';
                        sdout <= '0';
                        pas <= pas + 1;
                        end if;
                    when 12 =>
                        if geneck = 5 then
                        sdout <= '0';
                        pas <= pas + 1;
                        end if;
                    when 13 =>
                        if geneck = 5 then
                        sdout <= '0';
                        pas <= pas + 1;
                        end if;
                    when 14 =>
                        if geneck = 5 then
                        sdout <= valmem(12);
                        pas <= pas + 1;
                        end if;
                    when 15 =>
                        if geneck = 5 then
                        sdout <= valmem(11);
                        pas <= pas + 1;
                        end if;
                    when 16 =>
                        if geneck = 5 then
                        sdout <= valmem(10);
                        pas <= pas + 1;
                        end if;
                    when 17 =>
                        if geneck = 5 then
                        sdout <= valmem(9);
                        pas <= pas + 1;
                        end if;
                    when 18 =>
                        if geneck = 5 then
                        sdout <= valmem(8);
                        pas <= pas + 1;
                        end if;
                    when 19 =>
                        if geneck = 5 then
                        sdout <= '0';
                        dir <= '0';
                        pas <= pas + 1;
                        end if;
                    when 20 =>
                        if geneck = 2 then
                            if sdin = '1' then
                            sbusy <= '0';
                            else
                            pas <= pas + 1;
                            end if;
                        end if;
                    when 21 =>
                        if geneck = 5 then
                        dir <= '1';
                        sdout <= valmem(7);
                        pas <= pas + 1;
                        end if;
                    when 22 =>
                        if geneck = 5 then
                        sdout <= valmem(6);
                        pas <= pas + 1;
                        end if;
                    when 23 =>
                        if geneck = 5 then
                        sdout <= valmem(5);
                        pas <= pas + 1;
                        end if;
                    when 24 =>
                        if geneck = 5 then
                        sdout <= valmem(4);
                        pas <= pas + 1;
                        end if;
                    when 25 =>
                        if geneck = 5 then
                        sdout <= valmem(3);
                        pas <= pas + 1;
                        end if;
                    when 26 =>
                        if geneck = 5 then
                        sdout <= valmem(2);
                        pas <= pas + 1;
                        end if;
                    when 27 =>
                        if geneck = 5 then
                        sdout <= valmem(1);
                        pas <= pas + 1;
                        end if;
                    when 28 =>
                        if geneck = 5 then
                        sdout <= valmem(0);
                        pas <= pas + 1;
                        end if;
                    when 29 =>
                        if geneck = 5 then
                        sdout <= '0';
                        dir <= '0';
                        pas <= pas + 1;
                        end if;
                    when 30 =>
                        if ((geneck = 2) and (sdin = '1')) then
                         sbusy <= '0';
                        elsif geneck = 5 then
                        pas <= pas + 1;
                        dir <= '1';
                        end if;
                    when 31 =>
                        if geneck = 2 then
                        sdout <= '1';
                            if valmem(15) = '1' then
                            addmem <= addmem + 1;
                            another <= '1';
                            end if;
                        elsif geneck = 5 then
                        pas <= pas + 1;
                        end if;
                    when others =>
                        sbusy <= '0';
                end case;
            end if;
          else tempo <= tempo + 1;
        end if;
     end if;
end process;
sdin <= I2C_SDAT;
with pas select
    I2C_SCLK <= '1' when 0,
                sclk when others;
wrin <= (wrone and (not wrtwo));
    with dir select
        I2C_SDAT <= sdout when '1',
                    'Z' when others;
end regofcodec_arch;

-- ***************************************************************************
-- ** Déclaration de la gestion des horloges de séquencement des opérations **
-- ***************************************************************************
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_signed.all;

entity seqdata is
port(
     clk        : in std_logic;
     clkdivun   : out integer range 0 to 3;
     clkdivdeu  : out integer range 0 to 255;
     mclk       : out std_logic := '0'
     );
end seqdata;

architecture seqdata_arch of seqdata is
signal divun : integer range 0 to 3 := 0;
signal divdeu : integer range 0 to 255 := 0;
begin

-- clk     __     __     __     __     __     __     __
--      __|  |___|  |___|  |___|  |___|  |___|  |___|
--
--divun    |  0   |  1   |   2  |  3   |  0   |  1   |   2
--
-- mclk __                _____________               ___
--        |______________|             |_____________|
--
-- divdeu
--            n          |         n + 1             |


    process(clk)
        begin
        if clk'event and clk = '1' then
            if divun = 3
                then divun <= 0;
                mclk <= '0';
                else divun <= divun + 1;
            end if;
            if divun = 1 then
                mclk <= '1';
                if divdeu = 255
                    then divdeu <= 0;
                    else divdeu <= divdeu + 1;
                end if;
            end if;
        end if;
    end process;
    clkdivun <= divun;
    clkdivdeu <= divdeu;
end seqdata_arch;
