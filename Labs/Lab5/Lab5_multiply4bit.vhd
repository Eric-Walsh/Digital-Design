----------------------------------------------------------------------------------
-- Company: Walla Walla University
-- Engineer: Eric Walsh & Nicholas Zimmmeran
-- 
-- Create Date:    16:37:18 10/26/2021 
-- Design Name: 
-- Module Name:    Multiplier - Behavioral 
-- Project Name:   Digital Design Lab 5
-- Target Devices: Artix-7 (Xilinx ISE)
-- Tool versions: 
-- Description: Multiplies two 4-bit inputs and produces an 8-bit output. Switches are inputs and outputs are signals.
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

entity adder_type1 is
	port(j1,j2,k1,k2,Cin : in std_logic;
			Cout, sum: out std_logic);
end adder_type1;

architecture Behavioral of adder_type1 is
	signal u, v, uXORv : std_logic;
begin
	u <= j1 and j2;
	v <= k1 and k2;
	
	--Full-adder
	uXORv <= u xor v;
	sum <= uXORv xor Cin;
	Cout <= (u and v) or (uXORv and Cin);

end Behavioral;
------------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity adder_type2 is
	port(j1,j2,k,Cin : in std_logic;
			Cout, sum: out std_logic);
end adder_type2;

architecture Behavioral of adder_type2 is
	signal u, uXORk : std_logic;
begin
	u <= j1 and j2;
	
	--Full-adder
	uXORk <= u xor k;
	sum <= uXORk xor Cin;
	Cout <= (u and k) or (uXORk and Cin);

end Behavioral;
------------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity lab4_solution_top is
	port( A : in std_logic_vector (3 downto 0);
			B : in std_logic_vector (3 downto 0);
			r : out std_logic_vector (7 downto 0));
end lab4_solution_top;

architecture Behavioral of lab4_solution_top is
	
	component adder_type1
		port(j1,j2,k1,k2,Cin : in std_logic;
			Cout, sum: out std_logic);
	end component;
	
	component adder_type2
		port(j1,j2,k, Cin : in std_logic;
			Cout, sum: out std_logic);
	end component;
	
	signal C: std_logic_vector (12 downto 1);
	signal S2, S3, S4, S6, S7, S8: std_logic;
begin
	r(0) <= A(0) and B(0);
	add1: adder_type1 port map(A(0),B(1),A(1),B(0),'0',C(1),r(1));
	add2: adder_type1 port map(A(1),B(1),A(2),B(0),C(1),C(2),S2);
	add3: adder_type1 port map(A(2),B(1),A(3),B(0),C(2),C(3),S3);
	add4: adder_type2 port map(A(3),B(1),'0',C(3),C(4),S4);
	add5: adder_type2 port map(A(0),B(2),S2,'0',C(5),r(2));
	add6: adder_type2 port map(A(1),B(2),S3,C(5),C(6),S6);
	add7: adder_type2 port map(A(2),B(2),S4,C(6),C(7),S7);
	add8: adder_type2 port map(A(3),B(2),C(4),C(7),C(8),S8);
	add9: adder_type2 port map(A(0),B(3),S6,'0',C(9),r(3));
	add10: adder_type2 port map(A(1),B(3),S7,C(9),C(10),r(4));
	add11: adder_type2 port map(A(2),B(3),S8,C(10),C(11),r(5));
	add12: adder_type2 port map(A(3),B(3),C(8),C(11),r(7),r(6));
end Behavioral;
