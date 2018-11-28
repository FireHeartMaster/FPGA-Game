-- composant muxsonout
-- date de cr�ation : 1� octobre 2007
-- version : 1.0 for Quartus 7.1
-- by J.Y. Parey, repris par Y. Geerebaert
-- date de r�vsion : 15 Octobre 2007
-- version : 1.1 Am�lioration du case dans muxseqdatinout
-- date de r�vsion : 20 Octobre 2007
-- version : 1.2 Remplacement du TRI d'Alt�ra par inout g�n�rique
-- date de r�vsion : 26 Novembre 2007
-- version : 1.3 Modification du nom de la ROM pour �viter les incompatibilit�s
-- avec la gestion du clavier

-- version : 2.0 R�organisation compl�te du code : Ajout du package_son_out,
--           suppression des composants sp�cifique Altera (lpm_rom)
-- date de r�vsion : 01/01/2010

-- Utilisation du codec WM8731 en sortie uniquement
-- Les donn�es �chang�es avec le codec sont sur 16 bits sign�s en compl�ment � 2
-- clk: horloge � 50 Mhz
-- Echantillonnage � 48 Khz (Clock_50 divis� par 1024)
-- Les donn�es todac sont multiplex�es (voie droite et gauche sur un m�me bus)
-- 2 signaux de contr�le "wrLeft" et "wrRight" permettent la synchronisation :
-- Sur le front descendant, la donn�e pr�sente sur le bus todac est �chantillonn�e et envoy�e
-- vers le convertisseur.
-- Cette donn�e ne doit pas changer lorsque les deux signaux de synchronisation sont � 0.

library IEEE;
use IEEE.std_logic_1164.all;
--use IEEE.std_logic_arith.all;
--use IEEE.std_logic_unsigned.all;
--use IEEE.std_logic_signed.all;
use work.package_son_out.all;

entity muxsonout is
port(
     -- signaux cot� utilisateurs
     clk         : in std_logic;                      -- CLOCK_50 (50MHz)
     todac       : in std_logic_vector (15 downto 0); -- donnee son (signed)
     wrLeft      : out std_logic;   -- canal gauche sur le bus todac
     wrRight     : out std_logic;   -- canal droit  sur le bus todac
     -- signaux d'interface avec le CODEC WM8731
     I2C_SCLK    : out std_logic;   -- horloge du bus I�C
     I2C_SDAT    : inout std_logic; -- donn�e  du bus I�C
     AUD_DACDAT  : out std_logic;   -- DAC donn�e audio
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