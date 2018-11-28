library IEEE;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.all;
use work.int_array.all;
use IEEE.std_logic_signed.all;

-- sélectionner les bibliothèques dont vous aurez besoin
-- use IEEE.numeric_std.all;
-- use IEEE.std_logic_unsigned.all;
-- use IEEE.std_logic_signed.all;

entity VGA is

	GENERIC(
		H_pulse 	:	INTEGER := 96;    	--horiztonal sync pulse width in pixels
		H_bp	 	:	INTEGER := 44;		--horiztonal back porch width in pixels
		H_pixels	:	INTEGER := 640;		--horiztonal display width in pixels
		H_fp	 	:	INTEGER := 16;		--horiztonal front porch width in pixels
		H_pol		:	STD_LOGIC := '1';		--horizontal sync pulse polarity (1 = positive, 0 = negative)
		V_pulse 	:	INTEGER := 2;			--vertical sync pulse width in rows
		V_bp	 	:	INTEGER := 33;			--vertical back porch width in rows
		V_pixels	:	INTEGER := 480;		--vertical display width in rows
		V_fp	 	:	INTEGER := 10;			--vertical front porch width in rows
		V_pol		:	STD_LOGIC := '1';
		P_size : INTEGER := 20;
		speed : INTEGER := 51200;
		speedEnemy : INTEGER := 100000;
		maxVerticalSpeed : INTEGER := 51200;
		maxJump: INTEGER := 100;
		number : INTEGER := 3
		);

    port (

-- liste des entrées sorties

-- name : mode type ;
	CLOCK_50 : in std_logic;
	VGA_HS : out std_logic;
	VGA_VS : out std_logic;
	VGA_R : out std_logic_vector(7 downto 0) := "00000000";
	VGA_G : out std_logic_vector(7 downto 0) := "00000000";
	VGA_B : out std_logic_vector(7 downto 0) := "00000000";
	VGA_CLK : out std_logic;
	VGA_BLANK_N : out std_logic;
	VGA_SYNC_N : out std_logic := '0';
	SW : in std_logic_vector(0 downto 0);
	KEY : in std_logic_vector(3 downto 0);
	I2C_SCLK : out std_logic;
	I2C_SDAT : inout std_logic;
	AUD_DACDAT : out std_logic;
	AUD_DACLRCK : out std_logic;
	AUD_XCK : out std_logic;
	AUD_BCLK : out  std_logic;
	
	
   -- joystick connexions
	Data_from_NS1 : in  std_logic;        -- data line from Joystick 1 Nintendo
   Data_from_NS2 : in  std_logic;        -- data line from Joystick 2 Nintendo
   PS_to_NS1     : out std_logic := '0'; -- Parallel/Serial to Joystick 1 Nintendo
   PS_to_NS2     : out std_logic := '0'; -- Parallel/Serial to Joystick 2 Nintendo
   CLK_to_NS1    : out std_logic := '1'; -- Clock to Joystick 1 Nintendo
   CLK_to_NS2    : out std_logic := '1'  -- Clock to Joystick 2 Nintendo
	
    );
end VGA;

architecture myfile_arch of VGA is

component pll25 IS
	PORT
	(
		inclk0		: IN STD_LOGIC  := '0';
		c0		: OUT STD_LOGIC 
	);
END component;

component NES_joystick is
    Port ( CLOCK     : in  std_logic;                             -- Clock 50 Mhz or 27 Mhz
           Data_reg  : out std_logic_vector(7 downto 0) := x"FF"; -- = '0' if button pressed
           ready     : out std_logic := '0';                      -- Data ready
           -- joystick connexions
           Data_from_NS : in  std_logic;        -- data line from Joystick Nintendo
           PS_to_NS     : out std_logic := '0'; -- Parallel/Serial to Joystick Nintendo
           CLK_to_NS    : out std_logic := '1'  -- Clock to Joystick Nintendo
           );
end component;
--ROM
component character_rom is
	Port ( clk : in std_logic;
			 addr : in unsigned(8 DOWNTO 0);
			 dout : out unsigned(3 DOWNTO 0)
			 );
end component;
component character_rom2 is
	Port ( clk : in std_logic;
			 addr : in unsigned(8 DOWNTO 0);
			 dout : out unsigned(3 DOWNTO 0)
			 );
end component;

component block_rom is
	Port ( clk : in std_logic;
			 addr : in unsigned(8 DOWNTO 0);
			 dout : out unsigned(3 DOWNTO 0)
			 );
end component; 

component Environment is
    Port ( CLOCK     : in  std_logic;                             -- Clock 50 Mhz
           pos_x: out array_of_int_5 := (80, 560, 320, 80, 560);		-- x coordinates of each block
			  pos_y: out array_of_int_5 := (160, 160, 240, 320, 320);		-- y coordinates of each block
			  size_x: out array_of_int_5 := (160, 160, 320, 160, 160);		-- x size of each block
			  size_y: out array_of_int_5 := (20, 20, 20, 20, 20);		-- y size of each block
			  array_size: out integer := 5
           );
end component;
-- INTENTO """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

component muxsonout is
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
end component;

signal wrLeft : std_logic :='0';
signal wrRight : std_logic :='1';

signal todac    : std_logic_vector(15 downto 0) := "0000000000000000";

-- FIN INTENTO """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

-- signal declaration
-- signal  name : type  := valeur initiale;
CONSTANT	h_period	:	INTEGER := H_pulse + H_bp + H_pixels + H_fp;
CONSTANT	v_period	:	INTEGER := V_pulse + V_bp + V_pixels + V_fp;
signal CLOCK_25 : std_logic;
signal REG_JOYSTICK_1      : std_logic_vector(17 downto 0) := "00" & x"00FF";
signal REG_JOYSTICK_2      : std_logic_vector( 7 downto 0) := x"FF";
-- ROM
signal PIXEL_VAL				: unsigned(3 DOWNTO 0);
signal ADDRESS 				: unsigned(8 DOWNTO 0) := "000000000";
signal PIXEL_VAL2				: unsigned(3 DOWNTO 0);
signal ADDRESS2 				: unsigned(8 DOWNTO 0) := "000000000";
signal PIXEL_VAL3				: unsigned(3 DOWNTO 0);
signal ADDRESS3 				: unsigned(8 DOWNTO 0) := "000000000";
signal cicle : INTEGER RANGE 0 TO 15 := 0;

signal PIXEL_VAL_Enemy		: unsigned(3 DOWNTO 0);
signal ADDRESS_Enemy 		: unsigned(8 DOWNTO 0) := "000000000";
signal PIXEL_VAL2_Enemy		: unsigned(3 DOWNTO 0);
signal ADDRESS2_Enemy 		: unsigned(8 DOWNTO 0) := "000000000";
signal cicleEnemy : INTEGER RANGE 0 TO 15 := 0;

signal VGA_pos_x : array_of_int_5;
signal VGA_pos_y : array_of_int_5;
signal VGA_size_x : array_of_int_5;
signal VGA_size_y : array_of_int_5;
signal VGA_array_size : integer;

begin
 
 pll25_inst : pll25 PORT MAP (
		inclk0	 => CLOCK_50,
		c0	 => CLOCK_25
	);
VGA_CLK <= CLOCK_25;


--****************************************************************************
-- Joystick 1
NES_joystick1_inst: NES_joystick
port map (
      CLOCK         => CLOCK_50,
      Data_reg      => REG_JOYSTICK_1(7 downto 0),
      ready         => REG_JOYSTICK_1(17),
      Data_from_NS  => Data_from_NS1,
      PS_to_NS      => PS_to_NS1,
      CLK_to_NS     => CLK_to_NS1
      );

--****************************************************************************
-- Joystick 2
NES_joystick2_inst: NES_joystick
port map (
      CLOCK         => CLOCK_50,
      Data_reg      => REG_JOYSTICK_2(7 downto 0),
      ready         => REG_JOYSTICK_1(16),
      Data_from_NS  => Data_from_NS2,
      PS_to_NS      => PS_to_NS2,
      CLK_to_NS     => CLK_to_NS2
      );
character_rom_inst: character_rom
port map (
		addr			  => ADDRESS,
		clk			  => CLOCK_25,
		dout			  => PIXEL_VAL
		);
character_rom2_inst: character_rom2
port map (
		addr			  => ADDRESS2,
		clk			  => CLOCK_25,
		dout			  => PIXEL_VAL2
		);
block_rom_inst: block_rom
port map (
		addr			  => ADDRESS3,
		clk			  => CLOCK_25,
		dout			  => PIXEL_VAL3
		);
		
Environment_inst: Environment
port map (
		CLOCK				=> CLOCK_25,
		pos_x				=> VGA_pos_x,
		pos_y				=> VGA_pos_y,
		size_x			=> VGA_size_x,
		size_y			=> VGA_size_y,
		array_size		=> VGA_array_size
		);
--INTENTO """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
u_muxsonout : muxsonout
port map(
	  -- signaux cot� utilisateurs
     clk         =>CLOCK_50,                      -- CLOCK_50 (50MHz)
     todac       =>todac, -- donnee son (signed)
     wrLeft      =>wrLeft,   -- canal gauche sur le bus todac
     wrRight     =>wrRight,   -- canal droit  sur le bus todac
     -- signaux d'interface avec le CODEC WM8731
     I2C_SCLK    =>I2C_SCLK,   -- horloge du bus I�C
     I2C_SDAT    =>I2C_SDAT, -- donn�e  du bus I�C
     AUD_DACDAT  =>AUD_DACDAT,   -- DAC donn�e audio
     AUD_DACLRCK =>AUD_DACLRCK,   -- DAC horloge Gauche/Droite
     AUD_XCK     =>AUD_XCK,   -- horloge du codec
     AUD_BCLK    =>AUD_BCLK    -- ADC/DAC horloge bit
);
-- FIN INTENTO """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

character_rom_instEnemy: character_rom
port map (
		addr			  => ADDRESS_Enemy,
		clk			  => CLOCK_25,
		dout			  => PIXEL_VAL_Enemy
		);
character_rom2_instEnemy: character_rom2
port map (
		addr			  => ADDRESS2_Enemy,
		clk			  => CLOCK_25,
		dout			  => PIXEL_VAL2_Enemy
		); 
 
 
process (CLOCK_25)
	VARIABLE h_count	:	INTEGER RANGE 0 TO h_period - 1 := 0;
	VARIABLE v_count	:	INTEGER RANGE 0 TO v_period - 1 := 0;
	VARIABLE Cnt : INTEGER RANGE 0 TO speed := 0;
	VARIABLE jump: INTEGER RANGE 0 TO maxJump := maxJump;
	
	VARIABLE px : INTEGER RANGE 0 TO H_pixels-1 := 0;
	VARIABLE py : INTEGER RANGE 0 TO V_pixels-1 := 0;
	VARIABLE pxEnemy : INTEGER RANGE 0 TO H_pixels-1 := 600;
	VARIABLE pyenemy : INTEGER RANGE 0 TO V_pixels-1 := 0;
	VARIABLE verticalSpeed : INTEGER RANGE -maxVerticalSpeed TO maxVerticalSpeed:= 0;
	
	VARIABLE CntEnemy : INTEGER RANGE 0 TO speedEnemy := 0;
	VARIABLE pxEnemyAux : INTEGER;
	VARIABLE pyEnemyAux : INTEGER;
	VARIABLE distance : INTEGER := 0;

	begin
		IF rising_edge(CLOCK_25) THEN
			IF(Cnt MOD 2 = 0) THEN
				IF(wrLeft = '1') THEN
					wrLeft <= '0';
					wrRight <= '1';
				ELSE
					wrLeft <= '1';
					wrRight <= '0';
				END IF;
			END IF;
			
			IF(CntEnemy < speedEnemy-1) THEN
				CntEnemy := CntEnemy+1;
			ELSE
				CntEnemy := 0;
				
--				IF ( (pxEnemy - px) < (pyEnemy - py) ) THEN
--					distance := (pyEnemy - py) + ( (pxEnemy - px)*(pxEnemy - px)/(2*(pyEnemy - py)));
--				ELSE
--					distance := (pxEnemy - px) + ( (pyEnemy - py)*(pyEnemy - py)/(2*(pxEnemy - px)));
--				END IF;
--				
--				distance := (pxEnemy - px)*(pxEnemy - px) + (pyEnemy - py)*(pyEnemy - py);
--				
--				pxEnemyAux := 

				pxEnemyAux := pxEnemy - px;
				pyEnemyAux := pyEnemy - py;
				
				IF ((pxEnemyAux < 20 AND pxEnemyAux > -20) AND (pyEnemyAux < 20 AND pyEnemyAux > -20)) THEN
					pxEnemy := 600;
					pyEnemy := 0;
					
					px := 0;
					py := 0;
				END IF;
				
				IF (pyEnemyAux > pxEnemyAux) THEN
					IF (pyEnemyAux > -pxEnemyAux) THEN
						pyEnemy := pyEnemy - 1;
					ELSIF (pyEnemyAux < -pxEnemyAux) THEN
						pxEnemy := pxEnemy + 1;
					ELSE
						pxEnemy := pxEnemy + 1;
						pyEnemy := pyEnemy + 1;
					END IF;
				ELSIF (pyEnemyAux < pxEnemyAux) THEN
					IF (pyEnemyAux > -pxEnemyAux) THEN
						pxEnemy := pxEnemy - 1;
					ELSIF (pyEnemyAux < -pxEnemyAux) THEN
						pyEnemy := pyEnemy + 1;
					ELSE
						pxEnemy := pxEnemy - 1;
						pyEnemy := pyEnemy - 1;
					END IF;
				ELSE
					IF (pxEnemyAux >= 0) THEN
						pxEnemy := pxEnemy - 1;
						pyEnemy := pyEnemy + 1;
					ELSE
						pxEnemy := pxEnemy + 1;
						pyEnemy := pyEnemy - 1;
					END IF;
				END IF;
			
			END IF;
			
			IF(Cnt < speed-1) THEN
				Cnt := Cnt+1;
				IF(todac = "1111111111111111") THEN
					todac <= todac-"0000000000000001";
				ELSIF(todac = "0000000000000000") THEN
					todac <= todac+"0000000000000001";
				END IF;
			ELSE
				Cnt := 0;
				todac <= "0000000000000000";
				
				--enemy mouvement
				
				
				
				IF(REG_JOYSTICK_1(7) = '0' and REG_JOYSTICK_1(6) = '1' and  px<H_pixels-P_size) THEN
					px := px + 1;
				ELSIF(REG_JOYSTICK_1(7) = '1' and REG_JOYSTICK_1(6) = '0' and  px>=1) THEN
					px := px - 1;
				END IF;
				IF(REG_JOYSTICK_1(5) = '0' and REG_JOYSTICK_1(4) = '1' and  py<V_pixels-P_size) THEN
					py := py + 1;
				ELSIF(REG_JOYSTICK_1(5) = '1' and (REG_JOYSTICK_1(4) = '0' OR REG_JOYSTICK_1(1) = '0') and  py>=1 and jump = maxJump) THEN
					py := py - 1;
					jump := jump -1;
				END IF;
				IF(jump < maxJump and jump>1 and py>0) THEN
					py := py - 1;
					jump := jump - 1;
				-- add cases when it falls --
				ELSIF(VGA_pos_x(3)-VGA_size_x(3)/2<=px and px<=VGA_pos_x(3)+VGA_size_x(3)/2 and VGA_pos_y(3)-VGA_size_y(3)/2=py + P_size) THEN
					jump := maxJump;
					
				ELSIF(VGA_pos_x(4)-VGA_size_x(4)/2<=px and px<=VGA_pos_x(4)+VGA_size_x(4)/2 and VGA_pos_y(4)-VGA_size_y(4)/2=py + P_size) THEN
					jump := maxJump;
					
				ELSIF(VGA_pos_x(0)-VGA_size_x(0)/2<=px and px<=VGA_pos_x(0)+VGA_size_x(0)/2 and VGA_pos_y(0)-VGA_size_y(0)/2=py + P_size) THEN
					jump := maxJump;
					
				ELSIF(VGA_pos_x(1)-VGA_size_x(1)/2<=px and px<=VGA_pos_x(1)+VGA_size_x(1)/2 and VGA_pos_y(1)-VGA_size_y(1)/2=py + P_size) THEN
					jump := maxJump;
				
				ELSIF(VGA_pos_x(2)-VGA_size_x(2)/2<=px and px<=VGA_pos_x(2)+VGA_size_x(2)/2 and VGA_pos_y(2)-VGA_size_y(2)/2=py + P_size) THEN
					jump := maxJump;
				
				ELSIF(py<4*V_pixels/5-P_size-1) THEN
					py := py + 1;
					
				-- add cases when it reaches a support --
				ELSE
					jump := maxJump;
				END IF;
			END IF;
			
			
			IF(h_count < h_period - 1) THEN
				h_count := h_count + 1;
			ELSE
				h_count := 0;
				IF(v_count < v_period - 1) THEN
					v_count := v_count + 1;
				ELSE
					v_count := 0;
				END IF;
			END IF;
			
			--horizontal sync signal
			IF(h_count < H_pixels + H_fp OR H_count >= H_pixels + H_fp + H_pulse) THEN
				VGA_HS <= H_pol;		--deassert horiztonal sync pulse
			ELSE
				VGA_HS <= NOT H_pol;			--assert horiztonal sync pulse
			END IF;
			
			--vertical sync signal
			IF(v_count < V_pixels + V_fp OR v_count >= V_pixels + V_fp + V_pulse) THEN
				VGA_VS <= V_pol;		--deassert vertical sync pulse
			ELSE
				VGA_VS <= NOT V_pol;			--assert vertical sync pulse
			END IF;
			
			IF(v_count < 4*V_pixels/5) THEN  	--horiztonal display time
				VGA_B <= "11011010";
				VGA_G <= "10011110";
				VGA_R <= "00011001";
			ELSE
				VGA_B <= "00101101";
				VGA_G <= "01010010";
				VGA_R <= "10100000";
			END IF;
			
			-- phantom --
			
			IF(H_count=px+P_size and V_count=py+P_size) THEN
				ADDRESS <= "000000000";
				ADDRESS2 <= "000000000";
				IF cicle=15 THEN
					cicle<= 0;
				ELSE
					cicle<= cicle+1;
				END IF;
			END IF;
			
			IF(H_count=pxEnemy+P_size and V_count=pyEnemy+P_size) THEN
				ADDRESS_Enemy <= "000000000";
				ADDRESS2_Enemy <= "000000000";
				IF cicleEnemy=15 THEN
					cicleEnemy<= 0;
				ELSE
					cicleEnemy<= cicleEnemy+1;
				END IF;
			END IF;
			
			FOR I IN 0 to 4 LOOP
				IF(H_count>= VGA_pos_x(I) - VGA_size_x(I)/2 and H_count< VGA_pos_x(I) + VGA_size_x(I)/2 and V_count >= VGA_pos_y(I) - VGA_size_y(I)/2 and V_count < VGA_pos_y(I) + VGA_size_y(I)/2) THEN					
					--ADDRESS3 <= ((H_count-VGA_pos_x(I)+VGA_size_x(I)/2)+((H_count-VGA_pos_x(I)+VGA_size_x(I)/2)/20)*20+20*(V_count - VGA_pos_y(I) + VGA_size_y(I)/2));
					ADDRESS3 <= to_unsigned(((H_count-VGA_pos_x(I)+VGA_size_x(I)/2) MOD 20)+20*(V_count - VGA_pos_y(I) + VGA_size_y(I)/2), 9);
					VGA_B <= "00000000";
					VGA_G <= std_logic_vector(PIXEL_VAL3) & "0000";
					VGA_R <= std_logic_vector(PIXEL_VAL3+PIXEL_VAL3) & "0000";
				END IF;
			END LOOP;
			
			IF(H_count>=px and H_count<px+P_size and V_count>=py and V_count<py+P_size) THEN
				IF(PIXEL_VAL /= "0000" and cicle<=8) THEN
					VGA_R <= std_logic_vector(PIXEL_VAL) & "0000";
					VGA_G <= std_logic_vector(PIXEL_VAL) & "0000";
					VGA_B <= std_logic_vector(PIXEL_VAL) & "0000";
				ELSIF(PIXEL_VAL2 /= "0000" and cicle>8) THEN
					VGA_R <= std_logic_vector(PIXEL_VAL2) & "0000";
					VGA_G <= std_logic_vector(PIXEL_VAL2) & "0000";
					VGA_B <= std_logic_vector(PIXEL_VAL2) & "0000";
				END IF;
				ADDRESS <= ADDRESS+"000000001";
				ADDRESS2 <= ADDRESS2+"000000001";
			END IF;
			
			IF(H_count>=pxEnemy and H_count<pxEnemy+P_size and V_count>=pyEnemy and V_count<pyEnemy+P_size) THEN
				IF(PIXEL_VAL_Enemy /= "0000" and cicleEnemy<=8) THEN
					VGA_R <= "1100" & std_logic_vector(PIXEL_VAL_Enemy);
					VGA_G <= "1100" & std_logic_vector(PIXEL_VAL_Enemy);
					VGA_B <= "1100" & std_logic_vector(PIXEL_VAL_Enemy);
				ELSIF(PIXEL_VAL2_Enemy /= "0000" and cicleEnemy>8) THEN
					VGA_R <= "1100" & std_logic_vector(PIXEL_VAL2_Enemy);
					VGA_G <= "1100" & std_logic_vector(PIXEL_VAL2_Enemy);
					VGA_B <= "1100" & std_logic_vector(PIXEL_VAL2_Enemy);
				END IF;
				ADDRESS_Enemy <= ADDRESS_Enemy+"000000001";
				ADDRESS2_Enemy <= ADDRESS2_Enemy+"000000001";
			END IF;
			
			
			
			
--			--set pixel coordinates
			IF(h_count < H_pixels) THEN  	--horiztonal display time
				VGA_BLANK_N <= H_pol;
			ELSE
				VGA_BLANK_N <= NOT H_pol;
			END IF;
			
			IF(v_count > V_pixels) THEN	--vertical display time
				VGA_BLANK_N <= NOT H_pol;			--set vertical pixel coordinate
			END IF;

		END IF;
	end process;	


end myfile_arch;
