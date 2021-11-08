----------------------------------------------------------------------------------
-- Company:        Walla Walla University
-- Engineer:       E.Walsh
-- 
-- Create Date:    16:34 11/7/2021 
-- Design Name:     
-- Module Name:    stop_light_fsm - Behavioral 
-- Project Name:   ENGR 433 HW 6
-- Target Devices: Aritix-7 
-- Tool versions:  
-- Description:    A state machine that represents a stop light at a street intersection. Based off of code by L.Aamodt
--
-- Dependencies:  
--
-- Revision: 
-- Revision 1.0 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity stop_light_fsm is
    Port ( S1 : in  STD_LOGIC; -- The street running east to west
           S2 : in  STD_LOGIC; -- The street running north to  south
           G1: out  STD_LOGIC;
           Y1 : out  STD_LOGIC;
           R1 : out  STD_LOGIC; -- The signals for street 1
           G2: out  STD_LOGIC;
           Y2 : out  STD_LOGIC;
           R2 : out  STD_LOGIC;  -- The signals for street 2
           mclk : in  STD_LOGIC);
end stop_light_fsm;

architecture Behavioral of stop_light_fsm is
	type state_type is (A, B, C, D);
	signal state_reg, next_state : state_type;
	signal x,y : std_logic;
begin
	x <= S1;
	y <= S2;
		----------- State machine memory ------------
	process(mclk) 
	begin
		if (mclk'event and mclk='1') then
			state_reg <= next_state;
		end if;
	end process;
	   ----------- Next state logic ----------------
	process(x,y,state_reg)
            constant COUNT: integer:= 10000000; --Clock is 1 MHz, so counting to 10^6 should be equal to 1 second
	begin
		case state_reg is
			when A =>
				if (y = '0') then --Holds when S2 is low
					next_state <= A;
				else
					next_state <= B;
				end if;
			when B =>
				for i in (COUNT - 1) downto 0 loop --Counts to one second then goes into the next state
                    next_state <= B;
                end loop;
                    next_state <= C;
			when C =>
				if (x = '0') then --Holds when S1 is low
					next_state <= C;
				else
					next_state <= D;
				end if;
            when D =>
                for i in (COUNT - 1) downto 0 loop --Counts to one second then goes into the next state
                    next_state <= D;
                end loop;
                    next_state <= A;
		end case;
	end process;
		----------- Output logic --------------------
	process(state_reg)
	begin
		G1 <= '0';	-- default value
		Y1 <= '0';	-- default value
		R1 <= '0';	-- default value
        G2 <= '0';	-- default value
		Y2 <= '0';	-- default value
		R2 <= '0';	-- default value

		case state_reg is
			when A =>
				G1 <= '1';
                R2 <= '1';
			when B =>
				Y1 <= '1';
                R2 <= '1';
			when C =>
				R1 <= '1';
				G2 <= '1';
            when D =>
                R1 <= '1';
                Y2 <= '1';
		end case;
	end process;	
end Behavioral;

