----------------------------------------------------------------------------------
-- Company: 
-- Engineer: Eric Walsh & Nicholas Zimmerman
-- 
-- Create Date:    14:29:41 11/02/2021 
-- Design Name: 
-- Module Name:    Lab6_top_sch - Behavioral 
-- Project Name:	Digital Design Lab 6
-- Target Devices: Aritix-7 (Xilinx ISE)
-- Tool versions: 
-- Description: Generates multiple signals from a 50 MHz clock derived from a 50 GHz master clock
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

library UNISIM;
use UNISIM.VComponents.all;

entity Lab6_top_sch is
	port(	mclk : in std_logic;
			sw0 : in std_logic;
			Extout : out std_logic_vector(7 downto 0); --using 6 bits out of 8 bits
			TEK1 : out std_logic_vector(7 downto 0);	--using 6 bits out of 8 bits
			TEK5 : out std_logic );
end Lab6_top_sch;

architecture Structural of Lab6_top_sch is
	--slow_clock generator
	signal clk_next, clk_reg : unsigned(9 downto 0); --2^9=512
	signal t_next, t_reg : std_logic;
	signal slow_clk : std_logic;
	
	--FSM
	signal q,d : unsigned(2 downto 0);
	
	--Generated signals
	signal sync, data1, data2, data3 : std_logic;
begin
	-----------------------------------------------------------------------------------
		-- slow_clock generator			E.Welch & N. Zimmerman
		--
		-- Based on L.Aamodt's derived clock generator
	-----------------------------------------------------------------------------------
	process(mclk) 
		begin
			 if (mclk'event and mclk='1') then
				  clk_reg <= clk_next;
				  t_reg <= t_next;	           --  T-f/f register
			 end if;
		end process;

		clk_next <= (others=>'0') when clk_reg=499 else clk_reg+1;
		t_next <= (not t_reg) when clk_reg = 499 else t_reg; --Switch every 500, divide by 1000

		Clk_Buffer: BUFG 	-- Put t_reg on a buffered clock line
			 port map ( I => t_reg, O => slow_clk);
			 -- slowclk is a square wave with 50 kHz frequency
			 
	-----------------------------------------------------------------------------------
		-- Top-level structural architecture			E.Welch & N.Zimmerman
	-----------------------------------------------------------------------------------
	--DFF
	process(slow_clk, sw0)
	begin 
		if (slow_clk'event and slow_clk='1') then
			q <= d;
		end if;
	end process;
	--N.S. Logic
	d <= (others=>'0') when q=7 else q+1;
	 
	--Output Logic (could have used a process with a case statement [type-casting?])
		sync <= sw0 and not(q(0)) and not(q(1)) and not(q(2));
		data1 <= sw0 and q(0) and (q(2) xor q(1));
		data2 <= sw0 and (q(2) or q(1));
		data3 <= sw0 and q(1) and (not(q(2)) or q(0));
	
	--Output signals
	Extout(0) <= sync;
	TEK1(0) <= sync;
	
	Extout(1) <= data1;
	TEK1(1) <= data1;

	Extout(2) <= data2;
	TEK1(2) <= data2;
	
	Extout(3) <= data3;
	TEK1(3) <= data3;
	
	Extout(4) <= slow_clk;
	TEK1(4) <= slow_clk;
	
	Extout(7) <= mclk;
	TEK1(7) <= mclk;
	TEK5 <= mclk;
	
	--Unused outputs

	Extout(5) <= '0';
	Extout(6) <= '0';
	TEK1(5) <= '0';
	TEK1(6) <= '0';


end Structural;

