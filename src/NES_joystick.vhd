library IEEE;
use IEEE.std_logic_1164.all;

entity NES_joystick is
    Port ( CLOCK     : in  std_logic;                             -- Clock 50 Mhz
           Data_reg  : out std_logic_vector(7 downto 0) := x"FF"; -- = '0' if button pressed
           ready     : out std_logic := '0';                      -- Data ready
           -- joystick connexions
           Data_from_NS : in  std_logic;        -- data line from Joystick Nintendo
           PS_to_NS     : out std_logic := '0'; -- Parallel/Serial to Joystick Nintendo
           CLK_to_NS    : out std_logic := '1'  -- Clock to Joystick Nintendo
           );
end NES_joystick;

architecture NES_joystick_arch of NES_joystick is

signal CLOCK_ena     : std_logic := '0';
signal count_div_clk : integer range 0 to   81 := 0;
signal count_trame   : integer range 0 to 5492 := 0;

signal Data_reg_int  : std_logic_vector(7 downto 0) := (others => '1');

begin

-- Generate a 609 KHz clock_ena pulse
process(CLOCK)
begin
if rising_edge(CLOCK) then
    if count_div_clk = 81 then      -- 0 to 81 --> 82 x 20ns --> period 1.64 µs/ freq 609 kHz if clock = 50 Mhz
        CLOCK_ena <= '1';
        count_div_clk <= 0 ;
    else
        count_div_clk <= count_div_clk + 1;
        CLOCK_ena <= '0';
    end if;
end if;
end process;

-- generate a pulse period for latch signal (PS)
process(CLOCK)
begin
if rising_edge(CLOCK) then
	if CLOCK_ena = '1' then
    	if count_trame = 5492 then count_trame <=  0 ;
    	else
    	    count_trame <= count_trame + 1;
    	end if;
  	end if;
end if;
end process;

-- generate pulses on latch (PS) and clock to Nintendo
process(CLOCK)
begin
if rising_edge(CLOCK) then
	if CLOCK_ena = '1' then
    case (count_trame) is
        when 1|2 =>
                    PS_to_NS  <= '1';
                    CLK_to_NS <= '1';
                    ready     <= '0';
        when 4|6|8|10|12|14|16|18 =>
                    PS_to_NS  <= '0';
                    CLK_to_NS <= '0';
                    ready     <= '0';
        when 20 =>
                    PS_to_NS  <= '0';
                    CLK_to_NS <= '1';
                    ready     <= '1';
        when others =>
                    PS_to_NS  <= '0';
                    CLK_to_NS <= '1';
                    ready     <= '0';
        end case;
    end if;
end if;
end process;

-- Readout Data from Nintendo (refresh at 111 Hz)
process(CLOCK)
begin
if rising_edge(CLOCK) then
	if CLOCK_ena = '1' then
    case (count_trame) is
        when 5      => Data_reg_int(0) <= Data_from_NS;
        when 7      => Data_reg_int(1) <= Data_from_NS;
        when 9      => Data_reg_int(2) <= Data_from_NS;
        when 11     => Data_reg_int(3) <= Data_from_NS;
        when 13     => Data_reg_int(4) <= Data_from_NS;
        when 15     => Data_reg_int(5) <= Data_from_NS;
        when 17     => Data_reg_int(6) <= Data_from_NS;
        when 19     => Data_reg_int(7) <= Data_from_NS;
        when others => Data_reg_int    <= Data_reg_int;
        end case;
    end if;
end if;
end process;

Data_reg <= Data_reg_int;

end NES_joystick_arch;


