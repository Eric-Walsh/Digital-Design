----------------------------------------------------------------------------------
-- Company: Walla Walla University
-- Engineer: Eric Walsh & Nicholas Zimmerman
-- 
-- Create Date:    14:32:32 11/09/2021 
-- Design Name: 
-- Module Name:    Tx - Structural 
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

entity Tx is
	port(	data_in: in std_logic_vector(7 downto 0);
			Go: in std_logic; 
			clock_in: in std_logic;
			
			data1: out std_logic;
			Start: out std_logic;
			clock_out: out std_logic; 	--data clock
			
			--debugging
			led_out: out std_logic_vector(7 downto 0) );
end Tx;

architecture Structural of Tx is
	signal rShift, CE, TC : std_logic;
	
	--Control FSM
	type state_type is (Load, StartTransmit, FinishTransmit);
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
	--Output clock inversion to run the receiver on 
	--the falling clock edge
	-----------------------------------------------------------------
	clock_out <= not clock_in;
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
	process(control_reg, Go, TC)
	begin
		case control_reg is
			when Load =>
				if (Go='1') then
					control_next <= StartTransmit;
				else 
					control_next <= Load;
				end if;
			when StartTransmit =>
				control_next <= FinishTransmit;
			when FinishTransmit =>
				if (TC='1') then
					control_next <= Load;
				else 
					control_next <= FinishTransmit;
				end if;
		end case;
	end process;
	
	--Output Logic
	process(control_reg)
	begin
		Start <= '0';
		rShift <= '0';
		CE <= '0';
	
		case control_reg is
			when Load =>
			when StartTransmit =>
				Start <= '1';
			when FinishTransmit =>
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
		if (clock_in'event and clock_in='1') then	--send data on the falling edge
			data_reg <= data_next;
		end if;
	end process;
	
	--N.S. Logic
	data_next <= '0' & data_reg(7 downto 1) when rShift='1' else data_in;
	
	--Output Logic
	data1 <= data_reg(0);
	led_out <= data_reg;		--for degugging
	-----------------------------------------------------------------
	
end Structural;

