----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    15:35:14 12/12/2021 
-- Design Name: 
-- Module Name:    Seg7Driver - BasedOnLab5 
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

entity Seg7Driver is
	port(	mclk : in std_logic;
			p1_score, p2_score : in unsigned(3 downto 0);
			to_anode2, to_anode4 : out std_logic;
			to_cathode : out std_logic_vector(7 downto 0)	);
end Seg7Driver;

architecture BasedOnLab5 of Seg7Driver is
	--10kHz TFF used to toggle between 2 anodes
	signal cnt_reg, cnt_next : unsigned(12 downto 0);	--2^13=8192
	signal t_reg, t_next : std_logic;
	
	--Routing
	signal binary_under_1001 : std_logic_vector(3 downto 0);
	
	--Components
		component bcd2_7seg
			port (	data : in  STD_LOGIC_VECTOR (3 downto 0);
						cath_out : out  STD_LOGIC_VECTOR (7 downto 0)	);
		end component;
begin
	--1 bit counter
		--Register
		process(mclk)
		begin
			if (mclk'event and mclk='1') then
				cnt_reg <= cnt_next;
				t_reg <= t_next; 
			end if;
		end process;

		--NS Logic
		cnt_next <= (others=>'0') when (cnt_reg=2499) else (cnt_reg+1);
		t_next <= (not t_reg) when (cnt_reg=2499) else t_reg;			--10kHz
		
	--Generate to_cathode
		binary_under_1001 <= std_logic_vector(p1_score) when (t_reg='1') else std_logic_vector(p2_score);
		bcdTo7SegDecoder: bcd2_7seg port map (binary_under_1001,to_cathode);
		
	--Generate to_anode
		to_anode2 <= t_reg;			--p2, pulled down to 0(activated) when cnt_reg=0which selects p2_score
		to_anode4 <= not t_reg;		--p1, pulled down to 0(activated) when cnt_reg=1 which selects p1_score
	
end BasedOnLab5;

