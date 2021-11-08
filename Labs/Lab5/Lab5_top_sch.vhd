----------------------------------------------------------------------------------
-- Company: Walla Walla University
-- Engineer: 
-- 
-- Create Date:    14:02:46 10/26/2021 
-- Design Name: 
-- Module Name:    Lab5_top_sch - Structural 
-- Project Name: 
-- Target Devices: Artix-7 Xilinx ISE
-- Tool versions: 
-- Description: Multiplies two 4-digit values entered with switches and outputs
--						the result on a 7-segment display.
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
library unisim;
use UNISIM.VComponents.all;

entity Lab5_top_sch is
	port(
		sw: in std_logic_vector (7 downto 0);
		mclk: in std_logic;
		
		anode: out std_logic_vector (5 downto 1);		--rightmost 3 digits are anodes 4 downto 2
		cath: out std_logic_vector (7 downto 0)		-- a-g
	);
end Lab5_top_sch;

architecture Structural of Lab5_top_sch is
	--Data line
	signal product: std_logic_vector (7 downto 0);
	signal hundreds, tens, ones: std_logic_vector (3 downto 0);
	signal bcd: std_logic_vector (3 downto 0);

	--COMPONENTS--
	--clock_gen
	signal clk_next, clk_reg : unsigned(16 downto 0);
	signal t_next, t_reg : std_logic;
	signal slow_clk: std_logic;
	
	--counter
	signal cnt_next, cnt_reg : unsigned(1 downto 0);
	
	component lab4_solution_top
		port( A : in std_logic_vector (3 downto 0);
				B : in std_logic_vector (3 downto 0);
				r : out std_logic_vector (7 downto 0));
	end component;
	
	component bin2bcd_top 
		 port (b0,b1,b2,b3,b4,b5,b6,b7 : in  STD_LOGIC;
				 grp0 : out  STD_LOGIC_VECTOR (3 downto 0); --ones
				 grp1 : out  STD_LOGIC_VECTOR (3 downto 0); --tens
				 grp2 : out  STD_LOGIC_VECTOR (3 downto 0)); --hundreds
	end component;

	component bcd2_7seg
		port (data : in  STD_LOGIC_VECTOR (3 downto 0);
				  cath_out : out  STD_LOGIC_VECTOR (7 downto 0));
	end component;

begin

	----------------------------------------------------------------------------
	--
	--      Derived Clock generator.  Generates square waves
	--      L.Aamodt
	--      As shown, if mclk is 50 Mhz, t_reg and slowclk are 500 Hz
	--
	---------------- clock generator -------------------------------------------

	process(mclk)
	begin
		 if (mclk'event and mclk='1') then
			  clk_reg <= clk_next;
			  t_reg <= t_next;	           --  T-f/f register
		 end if;
	end process;

	clk_next <= (others=>'0') when clk_reg=49999 else clk_reg+1;
	t_next <= (not t_reg) when clk_reg = 49999 else t_reg;

	Clk_Buffer: BUFG                   -- Put t_reg on a buffered clock line
		 port map ( I => t_reg, O => slow_clk);
		 -- use slowclk to run flip/flops and counters;
		 -- slowclk is a square wave with 500 Hz frequency

	----------------------------------------------------------------------------
	--      Counter - counts 0,1,2,3 and then starts over at 0      L.Aamodt
	----------------------------------------------------------------------------

	process(slow_clk)
	begin
		 if (slow_clk'event and slow_clk='1') then
			  cnt_reg <= cnt_next;
		 end if;
	end process;

	cnt_next <= cnt_reg+1;

	--  Note: cnt_reg is the output you need to drive the mux and 2:4 decoder
	--  but you may need to type cast it back to std_logic_vector

	----------------------------------------------------------------------------
	
	multiplier: lab4_solution_top port map(	A => sw(7 downto 4),
															B => sw(3 downto 0),
															r => product );

	dec_tobcd: bin2bcd_top port map (	b0 => product(0),
													b1 => product(1),
													b2 => product(2),
													b3 => product(3),
													b4 => product(4),
													b5 => product(5),
													b6 => product(6),
													b7 => product(7),
													grp0 => ones,
													grp1 => tens,
													grp2 => hundreds );
	bcd <= 	hundreds when (cnt_reg="00") else
				tens when (cnt_reg="01") else
				ones;	--2 clk cycles
	dec_to7seg: bcd2_7seg port map(	data => bcd,
												cath_out => cath ); --cathode 7 always set to '1' in the block
	with cnt_reg select
		anode(4 downto 2) <= "110" when "00", --anode 2
									"101" when "01", --anode 3
									"011" when "10", --anode 4
									"111" when others;
	anode(1) <= '1'; --Leftmost digit unused
	anode(5) <= '1'; --Colon unused
end Structural;

