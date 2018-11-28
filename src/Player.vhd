library IEEE;
use IEEE.std_logic_1164.all;
use work.int_array.all;

entity Player is
    Port ( CLOCK     : in  std_logic;                             -- Clock 50 Mhz
--         blocks_pos_x: in array_of_int_7;		-- x coordinates of each block
--			  blocks_pos_y: in array_of_int_7;		-- y coordinates of each block
--			  blocks_size_x: in array_of_int_7;		-- x size of each block
--			  blocks_size_y: in array_of_int_7;		-- y size of each block
			  
			  input_x_left: in std_logic;
			  input_x_right: in std_logic;
			  input_jump: in std_logic;
			  
			  player_pos_x: out integer := 30;
			  player_pos_y: out integer := 30;
			  player_speed_y: out integer := 0;
			  
			  player_size_x: out integer := 20;
			  player_size_y: out integer := 20
           );
end Player;

architecture Player_arch of Player is

component Environment is
    Port ( CLOCK     : in  std_logic;                             -- Clock 50 Mhz
           pos_x: out array_of_int_7 := (80, 560, 320, 80, 560, 320, 320);		-- x coordinates of each block
			  pos_y: out array_of_int_7 := (160, 160, 240, 320, 320, 400, 480);		-- y coordinates of each block
			  size_x: out array_of_int_7 := (160, 160, 320, 160, 160, 320, 640);		-- x size of each block
			  size_y: out array_of_int_7 := (20, 20, 20, 20, 20, 20, 20);		-- y size of each block
			  array_size: out integer := 7
           );
end component;

	signal blocks_pos_x: array_of_int_7;		-- x coordinates of each block
	signal blocks_pos_y: array_of_int_7;		-- y coordinates of each block
	signal blocks_size_x: array_of_int_7;		-- x size of each block
	signal blocks_size_y: array_of_int_7;		-- y size of each block
	signal blocks_array_size: integer;
	
	signal m_player_pos_x: integer := 30;
	signal m_player_pos_y: integer := 30;
	signal m_player_speed_y: integer := 0;
	
	signal m_player_jump_speed: integer := 10;
			  
	signal m_player_size_x: integer := 20;
	signal m_player_size_y: integer := 20;
	
	signal grounded : std_logic := '0';
	signal touching : std_logic := '0';
	
	signal gravity : integer := 1;
	signal period : integer := 10;
	
	signal count : integer := 0;
	signal countMax : integer := 12800;

begin
	
	Environment_inst: Environment
	port map (
			CLOCK				=> CLOCK,
			pos_x				=> blocks_pos_x,
			pos_y				=> blocks_pos_y,
			size_x			=> blocks_size_x,
			size_y			=> blocks_size_y,
			array_size		=> blocks_array_size
			);

	process (CLOCK)
	begin
	
	--horizontal colisions
		IF (count = countMAX) THEN
			count <= 0;
		
			FOR I IN 0 to 6 LOOP
				IF (abs(blocks_pos_y(I) - m_player_pos_y) < blocks_size_y(I) + (m_player_size_y/2)) THEN
					IF (blocks_pos_x(I) - m_player_pos_x <= ((blocks_size_x(I) + m_player_size_x)/2) AND (input_x_right = '1' AND input_x_left = '0')) THEN
						m_player_pos_x <= blocks_pos_x(I) - ((blocks_size_x(I) + m_player_size_x)/2);
					ELSIF (m_player_pos_x - blocks_pos_x(I) <= ((blocks_size_x(I) + m_player_size_x)/2) AND (input_x_right  = '0' AND input_x_left  = '1')) THEN
						m_player_pos_x <= blocks_pos_x(I) + ((blocks_size_x(I) + m_player_size_x)/2);
					
					
					END IF;
				END IF;
			END LOOP;
			
			grounded <= '0';
			touching <= '0';
			FOR I IN 0 to 6 LOOP
				IF (abs(blocks_pos_x(I) - m_player_pos_x) < blocks_size_x(I) + (m_player_size_x/2)) THEN
					IF (m_player_pos_y - blocks_pos_y(I) <= ((blocks_size_y(I) + m_player_size_y)/2) AND (m_player_speed_y < 0)) THEN
						m_player_speed_y <= 0;
						m_player_pos_y <= blocks_pos_y(I) + ((blocks_size_y(I) + m_player_size_y)/2);
					ELSIF (blocks_pos_y(I) - m_player_pos_y <= ((blocks_size_y(I) + m_player_size_y)/2) AND (m_player_speed_y >= 0)) THEN
						m_player_speed_y <= 0;
						m_player_pos_y <= blocks_pos_y(I) - ((blocks_size_y(I) + m_player_size_y)/2);
						grounded <= '1';
						touching <= '1';
					END IF;
				END IF;
			END LOOP;
			
			IF (touching = '0') THEN
				m_player_speed_y <= m_player_speed_y + gravity*period;
			END IF;
			
			IF (grounded = '1' AND input_jump = '1') THEN
				m_player_speed_y <= m_player_jump_speed;
			END IF;
			
			m_player_pos_y <= m_player_pos_y + m_player_speed_y*period;
		
		ELSE
			count <= count + 1;
		END IF;
		
	end process;

end Player_arch;