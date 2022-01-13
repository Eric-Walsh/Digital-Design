----------------------------------------------------------------------------------
-- Company: Walla Walla University
-- Engineer: Eric Walsh and Nicholas Zimmerman
-- 
-- Create Date:    15:50:34 11/16/2021 
-- Design Name: 
-- Module Name:    Lab8_top_sch - Behavioral
-- Project Name: 	Pong_1d
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

library UNISIM;
use UNISIM.VComponents.all;

entity Lab8_top_sch is
	port(	mclk : in std_logic;
			btn1, btn2, btn3 : in std_logic;
			led : out std_logic_vector(15 downto 0);
				--7-segment display
				cath : out std_logic_vector(7 downto 0);
				anode : out std_logic_vector(5 downto 1);	--We must include unused anodes and drive them to '1'
			extout : out std_logic_vector(8 downto 0);
			tek4 : out std_logic_vector(1 downto 0);
			tek1 : out std_logic_vector(7 downto 0);
			tek5 : out std_logic);
end Lab8_top_sch;

architecture SingleFSM of Lab8_top_sch is
	----signals should be grouped by block of signal origin----
		signal R : std_logic;	--An alias for btn2
	--next_game_f_gen
			--signal c : unsigned(3 downto 0);	--Allows 15 frequencies, 1 to 15 
		signal sHit_cnt_next, sHit_cnt_reg, sHit_cnt_next_en : unsigned(1 downto 0);	--2 bit counter of successful hits, should be 1 bit TFF
		signal select_f_next, select_f_reg, select_f_notMax : unsigned(2 downto 0); --:= (others=>'0');	--attempting RAM of 8 predetermined frequencies
		signal m : unsigned(25 downto 0); --:= to_unsigned(50000000,26);	--26 bit unsigned value,
		signal select_f_forOutput_next, select_f_forOutput_reg : std_logic_vector(7 downto 0); --:= (others=>'0');
	--game_f_gen	--generates constant sys_clk and variable game_pulse which counts in units of sys_clk
		signal clk_reg, clk_next, clk_next_check : unsigned(25 downto 0);	--2^26 = 67,108,864 > 50E6; 32 bits to compare with m
		--signal clk_overflow : std_logic;
		--signal t_reg, t_next: std_logic;
		--signal game_clk : std_logic;
		signal game_pulse : std_logic;
	--control_FSM
		type control_state_type is (init_c,	lSh,lHit_zone,rPt,rWin,l_sHit,		--Seems to initialize to 1st state in list
														rSh,rHit_zone,lPt,lWin,r_sHit	);		
		signal control_state_reg, control_state_next : control_state_type;
		signal rHit,lHit : std_logic;	--Logical high of btn3,btn1 respectively
		signal sHit : std_logic;	--Successful hit by either player
		signal p1_pt, p2_pt : std_logic; --Increment score counter
		signal dir,shift	: std_logic;	--dir: 0 shifts left, 1 shifts right
		signal DATA : std_logic_vector(7 downto 0);
		signal WE : std_logic;
	--score_counter
		signal p1_score_reg, p1_score_next, p2_score_reg, p2_score_next: unsigned(3 downto 0);	--Seems to initialize to 0
		signal rW, lW : std_logic;	--Win condition met
	--ball_movement_FSM
		type ball_state_type is (init_b1, init_b2, holdBall, removeBall, addBall);	
		signal ball_state_reg, ball_state_next : ball_state_type;
		signal incr_addr : std_logic;
		signal reset_addr : std_logic;
	--address_incrementer
		signal addr_reg : unsigned(3 downto 0); --:= to_unsigned(15,4);	--Point to the rightmost part of the screen
		signal addr_next, enabled_addr_next, overwritten_addr_next : unsigned(3 downto 0);
		signal ADDR : std_logic_vector(3 downto 0);	--std_logic_vector data type
	---Components---
		--seg7Driver
		component Seg7Driver
			port(	mclk : in std_logic;
					p1_score, p2_score : in unsigned(3 downto 0);
					to_anode2, to_anode4 : out std_logic;
					to_cathode : out std_logic_vector(7 downto 0)	);
		end component;

		--dot_matrix_driver
		component led_8x16_driver
			port(	mclk:					in  STD_LOGIC;    -- 50 Mhz clock
					sys_clk:				in  STD_LOGIC;    -- clock from game
					we:					in  STD_LOGIC;    -- write enable
					data_in:				in  STD_LOGIC_VECTOR(7 downto 0);
					wrt_addr:			in  STD_LOGIC_VECTOR(3 downto 0);
					out_to_display:	out STD_LOGIC_VECTOR(7 downto 0) );
		end component;
begin
	-----------------------------------------------------------------------------
	--Next_game_f_gen	(50 MHz to 1 Hz) (not yet resettable)
	-----------------------------------------------------------------------------
	--Successful Hit counter
		process(mclk)
		begin
			if (mclk'event and mclk='1') then
				if(R='1') then
					select_f_reg <= (others=>'0');
					select_f_forOutput_reg <= (others=>'0');
				else
--					sHit_cnt_reg <= sHit_cnt_next;	--For counting number of successful hits
					select_f_reg <= select_f_next;
					select_f_forOutput_reg <= select_f_forOutput_next;
				end if;
			end if;
		end process;
		
		--NS Logic
--		sHit_cnt_next <= sHit_cnt_next_en when (sHit='1') else sHit_cnt_reg;	--enable
--		sHit_cnt_next_en <= (others => '0') when (sHit_cnt_reg=3) else (sHit_cnt_reg+1);
		
			--Update the frequency every 4 non-consecutive successful hits
--			select_f_next <= (select_f_reg+1) when (sHit='1' and sHit_cnt_reg=3) else select_f_reg;
		select_f_next <= select_f_reg when (select_f_reg=7) else select_f_notMax;	--Hold value instead of cycling back to 0
		select_f_notMax <= (select_f_reg+1) when (sHit='1') else select_f_reg;
		
		--Output Logic
		
			--RAM for m			--tried a case statement earlier
				with select_f_reg select 
					m <= 	to_unsigned(25000000,26) when "000",				--2Hz
							to_unsigned(16666666,26) when "001",				--3Hz
							to_unsigned(12500000,26) when "010",				--4Hz
							to_unsigned(10000000,26) when "011",				--5Hz
							to_unsigned(8333333,26) when "100",					--6Hz
							to_unsigned(7142857,26) when "101",					--7Hz
							to_unsigned(6250000,26) when "110",					--8Hz
							to_unsigned(5555555,26) when others; --111		--9Hz
			
			--c generation 	--unused
				--c <= to_unsigned(1,4);	--Magic number for now
			
		select_f_forOutput_next <= ('1' & select_f_forOutput_reg(7 downto 1)) when (sHit='1') else select_f_forOutput_reg;
	-----------------------------------------------------------------------------
	--Game_f_gen	(50 MHz to 1 Hz) (not yet resettable)
	-----------------------------------------------------------------------------
	process(mclk)
	begin
		if (mclk'event and mclk='1') then
			clk_reg <= clk_next;
		end if;
	end process;
	
	--NS Logic
		--clk_overflow <= '1' when (clk_reg >= 24999999) else '0';
		--clk_next <= (others=>'0') when (clk_overflow='1') else (clk_reg + c);	--Possible timing hazard with c on overflow, so we won't use it
		--t_reg <= (not t_reg) when (clk_overflow='1') else t_reg;
	
	clk_next_check <= (others=>'0') when (clk_reg = 49999999) else clk_next;	--make sure clk_reg is reset when m is changed
	clk_next <= (others=>'0') when (clk_reg = (m-1)) else (clk_reg + 1);
	
	--Output Logic
	--Clk_Buffer: BUFG 	-- Put t_reg on a buffered clock line
	--		 port map ( I => t_reg, O => game_clk);
	
	--game_pulse <= '1' when (clk_overflow='1' and t_reg='1') else '0';
	game_pulse <= '1' when (clk_reg = (m-1)) else '0';		--comparison of 26 bit unsigned values
	--It would be a good idea to buffer the above signal signal from glitches
	
	--Note: There will need a comparator for variable c but not for variable m
	-----------------------------------------------------------------------------
	--Score_counter
	-----------------------------------------------------------------------------
	process(mclk)
	begin
		if (mclk'event and mclk='1') then
			if(R='1') then
				p1_score_reg <= (others=>'0');
				p2_score_reg <= (others=>'0');
			else
				p1_score_reg <= p1_score_next;
				p2_score_reg <= p2_score_next;
			end if;
		end if;
	end process;
	
	--NS Logic
	p1_score_next <= p1_score_reg+1 when (p1_pt='1') else p1_score_reg;
	p2_score_next <= p2_score_reg+1 when (p2_pt='1') else p2_score_reg;
		
	--Out Logic
	rW <= '1' when (p1_score_reg=8) else '0';	--right player wins, should win on 9... but timing
	lW <= '1' when (p2_score_reg=8) else '0';	--left player wins, should win on 9... but timing
	
	-----------------------------------------------------------------------------
	--Control_FSM
	-----------------------------------------------------------------------------
	process(mclk)
	begin
		--if (R='1') then		--asynchronous reset?
			--control_state_reg <= init;
		--end if?? else?
			if (mclk'event and mclk='1') then
				if (R='1') then		--synchronous reset
					control_state_reg <= init_c;
				else
					control_state_reg <= control_state_next;
				end if;
			end if;
		--end if??
	end process;
	
	--NS Logic
	process(control_state_reg)
	begin
		case control_state_reg is 
			when init_c =>
				if (rHit='1') then
					control_state_next <= lSh;
				else
					control_state_next <= init_c;
				end if;
			when lSh =>
				if (addr_reg /= 0) then 
					control_state_next <= lSh;
				else	--addr_reg=0
					if (lHit='1') then
						control_state_next <= rPt;
					else
						control_state_next <= lHit_zone;
					end if;
				end if;
			when lHit_zone =>
				if (lHit='1') then
					control_state_next <= l_sHit;
				else	--lHit='0'
					if (game_pulse='1') then 
						control_state_next <= rPt;
					else
						control_state_next <= lHit_zone;
					end if;
				end if;
			when rPt =>
				if (rW='1') then
					control_state_next <= rWin;
				else
					control_state_next <= rSh;
				end if;
			when rWin =>
			when l_sHit => 
				control_state_next <= rSh;
			when rSh =>
				if (addr_reg /= 15) then 
					control_state_next <= rSh;
				else	--addr_reg=15
					if (rHit='1') then
						control_state_next <= lPt;
					else
						control_state_next <= rHit_zone;
					end if;
				end if;
			when rHit_zone =>
				if (rHit='1') then
					control_state_next <= r_sHit;
				else	--lHit='0'
					if (game_pulse='1') then 
						control_state_next <= lPt;
					else
						control_state_next <= rHit_zone;
					end if;
				end if;
			when lPt =>
				if (lW='1') then
					control_state_next <= lWin;
				else
					control_state_next <= lSh;
				end if;
			when lWin =>
			when r_sHit => 
				control_state_next <= lSh;
		end case;
	end process;
	
	--Out Logic
	process(control_state_reg)
	begin
		shift	<= '0';
		dir	<= '0';
		p1_pt	<= '0';
		p2_pt	<= '0';
		sHit <= '0';		--Leaving this out was a beginner's mistake! It broke the clock.
		case control_state_reg is 
			when init_c =>
			when lSh =>
				shift <= '1';
				--dir <= '0';
			when lHit_zone =>
			when rPt =>
				p1_pt <= '1';
			when rWin =>
			when l_sHit => 
				sHit <= '1';
			when rSh =>
				shift <= '1';
				dir <= '1';
			when rHit_zone =>
			when lPt =>
				p2_pt	<= '1';
			when lWin =>
			when r_sHit => 
				sHit <= '1';
		end case;
	end process;
	-----------------------------------------------------------------------------
	--Ball_Movement_FSM
	-----------------------------------------------------------------------------
	process(mclk)
	begin
		if (mclk'event and mclk='1') then
				if (R='1') then		--synchronous reset
					ball_state_reg <= init_b1;
				else
					ball_state_reg <= ball_state_next;
				end if;
		end if;
	end process;
	
	--NS Logic
	process(ball_state_reg)	--We're choosing not to have game_pulse in the sensitivity list because glitches
	begin 
		case ball_state_reg is 
			when init_b1 =>
				ball_state_next <= init_b2;
			when init_b2 => 
				ball_state_next <= holdBall;
			when holdBall =>
				if (shift='1' and game_pulse='1') then 
					ball_state_next <= removeBall;
				else 
					ball_state_next <= holdBall;
				end if; 
			when removeBall =>
				ball_state_next <= addBall;
			when addBall =>
				ball_state_next <= holdBall;
		end case;
	end process;

	--Out Logic
	process(ball_state_reg)
	begin
		incr_addr <= '0';
		DATA <= "10101010";
		WE <= '0';
		reset_addr <= '0';
		case ball_state_reg is 
			when init_b1 =>
				--Change the next address 
				reset_addr <= '1';	--Change the next address
				--Write in the the current addressed location
				DATA <= (others=>'0');	--Set the currently addressed column
				WE <= '1';
			when init_b2 =>
				DATA <= "00000001";
				WE <= '1';
			when holdBall =>
			when removeBall =>
				incr_addr <= '1';
				DATA <= (others=>'0');	--Redundant statement?
				WE <= '1';
				--Wait longer to write value? (use a counter)
			when addBall =>
				DATA <= "00000001";
				WE <= '1';
				--Wait longer to write value? (use a counter)
		end case;
	end process;
	
-----------------------------------------------------------------------------
	--Address_incrementer
	-----------------------------------------------------------------------------
	process(mclk)
	begin
			if (mclk'event and mclk='1') then
					addr_reg <= addr_next;
			end if;
	end process;
	
	--NS Logic
		overwritten_addr_next <= to_unsigned(15,4) when (reset_addr ='1') else addr_next;	--override
		addr_next <= (enabled_addr_next) when (incr_addr='1') else addr_reg;		--enable
		enabled_addr_next <= (addr_reg+1) when (dir='1') else (addr_reg-1);
		
	--Output Logic
	ADDR <= std_logic_vector(addr_reg);
	
	-----------------------------------------------------------------------------
	--Top level code
	-----------------------------------------------------------------------------
	rHit <= not btn3;	--player 1
	lHit <= not btn1;	--player 2
	R <= not btn2;	--Initialize/Reset
	
	Seg7Driver_1: Seg7Driver port map(	mclk => mclk,
													p1_score => p1_score_reg,
													p2_score => p2_score_reg,
													to_anode2 => anode(2),
													to_anode4 => anode(4),
													to_cathode => cath 		);
	anode(1) <= '1';	--unused
	anode(3) <= '1';	--unused
	anode(5) <= '1';	--unused
	
	dotMatrixDriver : led_8x16_driver
		port map (	mclk => mclk,
						sys_clk => mclk,
						we => WE,
						data_in => DATA,
						wrt_addr => ADDR,
						out_to_display => extout(7 downto 0) );
						
		--Score
		led(7 downto 0) <= std_logic_vector(p2_score_reg) & std_logic_vector(p1_score_reg);
		--led(15 downto 8) <= std_logic_vector(m(15 downto 8));
		led(15 downto 8) <= lW & "000000" & rW;
		--led(15 downto 8) <= select_f_forOutput_reg;

	tek4(0) <= WE;
	tek1(0) <= WE;
	tek4(1) <= game_pulse;	--was DATA(0)
	tek1(1) <= game_pulse;	--was DATA(0)
	tek1(2) <= game_pulse;
	extout(8) <= mclk;
	tek1(7) <= mclk;
	tek5 <= mclk;
	
end SingleFSM;

