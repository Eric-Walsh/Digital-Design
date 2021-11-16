----------------------------------------------------------------------------------
-- Company: Walla Walla University
-- Engineer: Eric Walsh & Nicholas Zimmerman
-- 
-- Create Date:    14:06:01 11/09/2021 
-- Design Name: 
-- Module Name:    Lab7_top_sch - Behavioral 
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

entity counter3bitCycle is
	port(	clk : in std_logic;	
			CE : in std_logic;	--CE triggers the full counting sequence
			TC : out std_logic );
end counter3bitCycle;

architecture Behavioral of counter3bitCycle is
	signal cnt_next, cnt_reg : unsigned(2 downto 0);
begin
	--DFF
	process(clk)
	begin
		if (clk'event and clk='1') then
			cnt_reg <= cnt_next;
		end if;
	end process;
	
	--N.S. Logic
		cnt_next <= cnt_reg+1 when (cnt_reg=0 nand CE='0') else cnt_reg;
	
	--Output Logic
		TC <= '1' when cnt_reg=7 else '0';
	
end Behavioral;
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library UNISIM;
use UNISIM.VComponents.all;

entity Lab7_top_sch is
	port(	--Clock
			mclk: in std_logic;
			
			--Transmitter
			sw: in std_logic_vector(7 downto 0);
			btn2: in std_logic;
			extout: out std_logic_vector(2 downto 0);

			--Receiver
			extin: in std_logic_vector(2 downto 0);
			led: out std_logic_vector(15 downto 0) );
end Lab7_top_sch;

architecture Structural of Lab7_top_sch is
	signal slow_clock: std_logic;
	--clock_gen
	signal clk_next, clk_reg : unsigned(14 downto 0);	--2^15=32768
	signal t_next, t_reg : std_logic;
	--Between Tx and Rx
	signal data1: std_logic;
	signal Start: std_logic;
	signal data_clock: std_logic;
	
	--Component declarations
		--Tx
		component Tx
			port(	data_in: in std_logic_vector(7 downto 0);
					Go: in std_logic; 
					clock_in: in std_logic;
					
					data1: out std_logic;
					Start: out std_logic;
					clock_out: out std_logic;
					--debugging
					led_out: out std_logic_vector(7 downto 0) );	--leds for debugging
		end component;
		--Rx
		component Rx
			port(	data1: in std_logic;
					Start: in std_logic;
					clock_in: in std_logic;
					
					led_out: out std_logic_vector(7 downto 0) );
		end component;
begin
	-----------------------------------------------------------------------------
	--Clock_gen	(50 MHz to 1 kHz)
	-----------------------------------------------------------------------------
	process(mclk)
	begin
		if (mclk'event and mclk='1') then
			clk_reg <= clk_next;
			t_reg <= t_next;		--TFF
		end if;
	end process;
	
	clk_next <= (others=>'0') when clk_reg=24999 else clk_reg+1;
	t_next <= (not(t_reg)) when clk_reg=24999 else t_reg;
	
	Clk_Buffer: BUFG                   -- Buffered clock line
	port map ( I => t_reg, O => slow_clock);
	-----------------------------------------------------------------------------
	
	Transmitter: Tx
		port map (	--inputs
						data_in => sw,
						Go => not btn2,	--Buttons are high on logic low so need inverting
						clock_in => slow_clock,
						--outputs
						data1 => extout(2),
						Start => extout(1),
						clock_out => extout(0),
						led_out => led(15 downto 8) );
	Receiver: Rx
		port map (	--inputs
						data1 => extin(2),
						Start => extin(1), 
						clock_in => extin(0),
						--outputs
						led_out => led(7 downto 0) );

end Structural;