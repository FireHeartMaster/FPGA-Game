
-- Exemple de bouclage de l'entr�e son sur la sortie son

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_signed.all;

entity son is
    port (
     CLOCK_50    : in std_logic;
     KEY         : in std_logic_vector ( 3 downto 0); -- reset on key(1)
     SW          : in std_logic_vector (17 downto 0);
     I2C_SCLK    : out std_logic;   -- horloge du bus I�C
     I2C_SDAT    : inout std_logic; -- donn�e  du bus I�C
     AUD_DACDAT  : out std_logic;   -- DAC donn�e audio
     AUD_ADCLRCK : out std_logic;   -- ADC horloge Gauche/Droite
     AUD_ADCDAT  : in std_logic;    -- ADC donn�e audio
     AUD_DACLRCK : out std_logic;   -- DAC horloge Gauche/Droite
     AUD_XCK     : out std_logic;   -- horloge du codec
     AUD_BCLK    : out std_logic    -- ADC/DAC horloge bit
    );
end son;


architecture loop_back_arch of son is

component muxsoninout is
port(
     -- signaux cot� utilisateurs
     clk     : in std_logic;                       -- CLOCK_50 (50MHz)
     reset   : in std_logic;                       -- reset (active high)
     todac   : in std_logic_vector (15 downto 0);  -- donnee HP (signed)
     fromadc : out std_logic_vector (15 downto 0); -- donnee ligne (signed)
     rdRwrL  : out std_logic; -- Lecture droite, ecriture gauche
     rdLwrR  : out std_logic; -- Lecture gauche, ecriture droite
     -- signaux d'interface avec le CODEC WM8731
     I2C_SCLK    : out std_logic;   -- horloge du bus I�C
     I2C_SDAT    : inout std_logic; -- donn�e  du bus I�C
     AUD_DACDAT  : out std_logic;   -- DAC donn�e audio
     AUD_ADCLRCK : out std_logic;   -- ADC horloge Gauche/Droite
     AUD_ADCDAT  : in std_logic;    -- ADC donn�e audio
     AUD_DACLRCK : out std_logic;   -- DAC horloge Gauche/Droite
     AUD_XCK     : out std_logic;   -- horloge du codec
     AUD_BCLK    : out std_logic;   -- ADC/DAC horloge bit
     SW          : in std_logic_vector (17 downto 0) -- debug
     );
end component;

signal reset  : std_logic;
signal rdRwrL : std_logic; -- Lecture droite, ecriture gauche
signal rdLwrR : std_logic; -- Lecture gauche, ecriture droite

signal ADC_Right : std_logic_vector(15 downto 0) := "0000000000000000";
signal ADC_Left  : std_logic_vector(15 downto 0) := "0000000000000000";

signal DAC_Right : std_logic_vector(15 downto 0) := "0000000000000000";
signal DAC_Left  : std_logic_vector(15 downto 0) := "0000000000000000";

signal todac    : std_logic_vector(15 downto 0) := "0000000000000000";
signal fromadc  : std_logic_vector(15 downto 0) := "0000000000000000";

begin

reset <= not KEY(1);

Process(CLOCK_50)
begin
    if rising_edge(CLOCK_50) then
        if    rdRwrL = '1' then ADC_Right <= fromadc;
                                todac     <= DAC_Left;
        elsif rdLwrR = '1' then ADC_Left  <= fromadc;
                                todac     <= DAC_Right;
        end if;
    end if;
end process;

-- loop_back
DAC_Left  <= ADC_Left;
DAC_Right <= ADC_Right;

u_muxsoninout : muxsoninout
port map(
     -- signaux cot� utilisateurs
     clk        => CLOCK_50,
     reset      => reset,
     todac      => todac,
     fromadc    => fromadc, -- donnee ligne (signed)
     rdRwrL     => rdRwrL, -- Lecture droite, ecriture gauche
     rdLwrR     => rdLwrR, -- Lecture gauche, ecriture droite
     -- signaux d'interface avec le CODEC WM8731
     I2C_SCLK=>I2C_SCLK, -- horloge du bus I�C
     I2C_SDAT=>I2C_SDAT, -- donn�e  du bus I�C
     AUD_DACDAT => AUD_DACDAT, -- DAC donn�e audio
     AUD_ADCLRCK => AUD_ADCLRCK,  -- ADC horloge Gauche/Droite
     AUD_ADCDAT => AUD_ADCDAT,    -- ADC donn�e audio
     AUD_DACLRCK => AUD_DACLRCK,   -- DAC horloge Gauche/Droite
     AUD_XCK => AUD_XCK,   -- horloge du codec
     AUD_BCLK => AUD_BCLK,    -- ADC/DAC horloge bit
     SW       => SW
);

end loop_back_arch;
