-- composant muxsonout
-- date de création : 1° octobre 2007
-- version : 1.0 for Quartus 7.1
-- by J.Y. Parey, repris par Y. Geerebaert
-- date de révsion : 15 Octobre 2007
-- version : 1.1 Amélioration du case dans muxseqdatinout
-- date de révsion : 20 Octobre 2007
-- version : 1.2 Remplacement du TRI d'Altéra par inout générique
-- date de révsion : 26 Novembre 2007
-- version : 1.3 Modification du nom de la ROM pour éviter les incompatibilités
-- avec la gestion du clavier

-- version : 2.0 Réorganisation complète du code : Ajout du package_son_out,
--           suppression des composants spécifique Altera (lpm_rom)
-- date de révsion : 01/01/2010

-- Utilisation du codec WM8731 en sortie uniquement
-- Les données échangées avec le codec sont sur 16 bits signés en complément à 2
-- clk: horloge à 50 Mhz
-- Echantillonnage à 48 Khz (Clock_50 divisé par 1024)
-- Les données todac sont multiplexées (voie droite et gauche sur un même bus)
-- 2 signaux de contrôle "wrLeft" et "wrRight" permettent la synchronisation :
-- Sur le front descendant, la donnée présente sur le bus todac est échantillonnée et envoyée
-- vers le convertisseur.
-- Cette donnée ne doit pas changer lorsque les deux signaux de synchronisation sont à 0.

library IEEE;
use IEEE.std_logic_1164.all;
--use IEEE.std_logic_arith.all;
--use IEEE.std_logic_unsigned.all;
--use IEEE.std_logic_signed.all;
use work.package_son_out.all;

entity muxsonout is
port(
     -- signaux coté utilisateurs
     clk         : in std_logic;                      -- CLOCK_50 (50MHz)
     todac       : in std_logic_vector (15 downto 0); -- donnee son (signed)
     wrLeft      : out std_logic;   -- canal gauche sur le bus todac
     wrRight     : out std_logic;   -- canal droit  sur le bus todac
     -- signaux d'interface avec le CODEC WM8731
     I2C_SCLK    : out std_logic;   -- horloge du bus I²C
     I2C_SDAT    : inout std_logic; -- donnée  du bus I²C
     AUD_DACDAT  : out std_logic;   -- DAC donnée audio
     AUD_DACLRCK : out std_logic;   -- DAC horloge Gauche/Droite
     AUD_XCK     : out std_logic;   -- horloge du codec
     AUD_BCLK    : out std_logic    -- ADC/DAC horloge bit
     );
end muxsonout;

architecture muxsonout_arch of muxsonout is

component seqdata
    port (clk:in std_logic; clkdivun : out integer range 0 to 3;
          clkdivdeu : out integer range 0 to 255; mclk : out std_logic );
end component;

component regofcodec is
    port (clk : in std_logic;I2C_SCLK : out std_logic; I2C_SDAT : inout std_logic);
end component;

component muxseqdatout is
    port (clk : in std_logic; valin :in std_logic_vector (15 downto 0);
    divun : in integer range 0 to 3; divdeu : in integer range 0 to 255;
    AUD_DACDAT, AUD_DACLRCK, wrLeft, wrRight : out std_logic );
end component;

signal sckun        : integer range 0 to 3;
signal sckdeu       : integer range 0 to 255;
signal mclktmp      : std_logic;
signal audiclktmp   : std_logic;

begin
seqdata_inst : component seqdata port map
    (clk        => clk,
     clkdivun   => sckun,
     clkdivdeu  => sckdeu,
     mclk       => mclktmp
     );

regofcodec_inst : component regofcodec port map
     (clk       => clk,
      I2C_SCLK  => I2C_SCLK,
      I2C_SDAT  => I2C_SDAT
      );

muxseqdatout_inst : component muxseqdatout port map
     (clk           => clk,
      divun         => sckun,
      valin         => todac ,
      AUD_DACDAT    => AUD_DACDAT ,
      AUD_DACLRCK   => audiclktmp ,
      divdeu        => sckdeu,
      wrLeft        => wrLeft,
      wrRight       => wrRight
      );

AUD_DACLRCK <= audiclktmp;
AUD_XCK     <= mclktmp;
AUD_BCLK    <= mclktmp;

end muxsonout_arch;