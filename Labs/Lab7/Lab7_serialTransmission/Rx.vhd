----------------------------------------------------------------------------------
-- Company: Walla Walla University
-- Engineer: Eric Walsh & Nicholas Zimmerman
-- 
-- Create Date:    14:32:51 11/09/2021 
-- Design Name: 
-- Module Name:    Rx - Structural 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity Rx is
	port(	data1: in std_logic;
			Start: in std_logic; 
			clock_in: in std_logic;
			
			led_out: out std_logic_vector(7 downto 0) );
end Rx;

architecture Structural of Rx is

	signal rShift, CE, TC : std_logic;
	
	--Control FSM
	type state_type is (Store, Shift);
	signal control_next, control_reg : state_type;
	
	--Data line
	signal data_next, data_reg: std_logic_vector(7 downto 0);
	
	--Component declarations
		--counter
		component counter3bitCycle is
			port(	clk : in std_logic;
					CE : in std_logic;
					TC : out std_logic );
		end component;
begin
	-----------------------------------------------------------------
	--Control FSM
	-----------------------------------------------------------------
	process(clock_in)
	begin
		if(clock_in'event and clock_in='1') then
			control_reg <= control_next;
		end if;
	end process;
	
	--NS Logic
	process(control_reg, Start, TC)
	begin
		case control_reg is
			when Store =>
				if (Start='1') then
					control_next <= Shift;
				else 
					control_next <= Store;
				end if;
			when Shift =>
				if (TC='1') then
					control_next <= Store;
				else
					control_next <= Shift;
				end if;
		end case;
	end process;
	
	--Output Logic
	process(control_reg)
	begin
		rShift <= '0';
		CE <= '0';
	
		case control_reg is
			when Store =>
			when Shift =>
				rShift <= '1';
				CE <= '1';
		end case;
	end process;
	-----------------------------------------------------------------
	--Counter
	-----------------------------------------------------------------
	counter: counter3bitCycle
		port map(	clk => clock_in,
						CE => CE,
						TC =>  TC );
	-----------------------------------------------------------------
	--Data line
	-----------------------------------------------------------------
	--DFF
	process(clock_in)
	begin
		if (clock_in'event and clock_in='1') then
			data_reg <= data_next;
		end if;
	end process;
	
	--N.S. Logic
	data_next <= data1 & data_reg(7 downto 1) when rShift='1' else data_reg;
	
	--Output Logic
	led_out <= data_reg;		--LED values change while shifting
	-----------------------------------------------------------------

end Structural;

