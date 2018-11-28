library IEEE;
use IEEE.std_logic_1164.all;
use work.int_array.all;

entity Environment is
    Port ( CLOCK     : in  std_logic;                             -- Clock 50 Mhz
           pos_x: out array_of_int_5 := (80, 560, 320, 80, 560);		-- x coordinates of each block
			  pos_y: out array_of_int_5 := (160, 160, 240, 320, 320);		-- y coordinates of each block
			  size_x: out array_of_int_5 := (160, 160, 320, 160, 160);		-- x size of each block
			  size_y: out array_of_int_5 := (20, 20, 20, 20, 20);		-- y size of each block
			  array_size: out integer := 5
           );
end Environment;

architecture Environment_arch of Environment is
	

begin

  process (CLOCK)
  begin
 
  end process;

end Environment_arch;