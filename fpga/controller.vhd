----------------------------------------------------------------------------------
-- controller.vhd
--
-- Copyright (C) 2006 Michael Poppitz
-- 
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; either version 2 of the License, or (at
-- your option) any later version.
--
-- This program is distributed in the hope that it will be useful, but
-- WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
-- General Public License for more details.
--
-- You should have received a copy of the GNU General Public License along
-- with this program; if not, write to the Free Software Foundation, Inc.,
-- 51 Franklin St, Fifth Floor, Boston, MA 02110, USA
--
----------------------------------------------------------------------------------
--
-- Details: http://sump.org/projects/analyzer/
--
-- Saves input to external SRAM continuously in normal operation.
-- When the run signal is received, it keeps doing this for fwd * 4
-- samples and then sends bwd * 4 samples to the transmitter.
-- This allows to capture data from before the trigger match which
-- is a nice feature.
-- The 24 bit wide speed register defines the clock divider to get
-- the sampling rate.
--
-- TODO: The memory address increment / clock divider block is pretty
-- slow right now. Needs improvement to get to 100MHz.
--
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity controller is
    Port ( clock : in  STD_LOGIC;
			  reset : in std_logic;
           input : in  STD_LOGIC_VECTOR (31 downto 0);
			  data : in STD_LOGIC_VECTOR (31 downto 0);
			  wrSpeed : in std_logic;
			  wrSize : in std_logic;
			  run : in std_logic;
			  txBusy : in std_logic;

			  send : inout std_logic;
           output : out  STD_LOGIC_VECTOR (31 downto 0);

			  ramA : out  STD_LOGIC_VECTOR (17 downto 0);
           ramWE : out  STD_LOGIC;
           ramOE : out  STD_LOGIC;
           ramIO1 : inout  STD_LOGIC_VECTOR (15 downto 0);
           ramCE1 : out  STD_LOGIC;
           ramUB1 : out  STD_LOGIC;
           ramLB1 : out  STD_LOGIC;
           ramIO2 : inout  STD_LOGIC_VECTOR (15 downto 0);
           ramCE2 : out  STD_LOGIC;
           ramUB2 : out  STD_LOGIC;
           ramLB2 : out  STD_LOGIC
	 );
end controller;

architecture Behavioral of controller is

type CONTROLLER_STATES is (SAMPLE, DELAY, READ, READWAIT);

signal speed : std_logic_vector (23 downto 0);
signal fwd, bwd : std_logic_vector (15 downto 0);
signal nDiv, div : std_logic_vector (23 downto 0);
signal nAddress, address, ncounter, counter: std_logic_vector (17 downto 0);
signal nstate, state : CONTROLLER_STATES;
signal up, inc, ninc: std_logic;

begin
	ramA <= address;
	
	ramCE1 <= not '1';
	ramUB1 <= not '1';
	ramLB1 <= not '1';
	ramCE2 <= not '1';
	ramUB2 <= not '1';
	ramLB2 <= not '1';

	ramWE <= not up;
	ramOE <= up;

   output <= ramIO2 & ramIO1;
   -- output <= ramIO2 & address(15 downto 0);
	-- output <= address & ramIO1(13 downto 0);

	-- memory io interface state controller
	process(up, input)
	begin
		if up = '1' then
			ramIO1 <= input(15 downto 0);
			ramIO2 <= input(31 downto 16);
		else
			ramIO1 <= "ZZZZZZZZZZZZZZZZ";
			ramIO2 <= "ZZZZZZZZZZZZZZZZ";
		end if;
	end process;

	-- synchronization and reset logic
	process(run, clock, reset)
	begin
		if reset = '1' then
			state <= SAMPLE;
			address <= "000000000000000000";
		elsif clock = '1' and clock'event then
			state <= nstate;
			counter <= ncounter;
			address <= nAddress;
			div <= nDiv;
			inc <= ninc;
		end if;
	end process;

	-- memory address counter
	process(div, speed, up, address, send)
	begin
		if up = '1' then
			if div = speed then
				nDiv <= "000000000000000000000000";
				ninc <= '1';
			else
				nDiv <= div + 1;
				ninc <= '0';
			end if;
		else
			nDiv <= "000000000000000000000000";
			ninc <= '0';
		end if;
	end process;

	process(inc, up, address, send)
	begin
		if inc = '1' then
			nAddress <= address + 1;
		elsif up = '0' and send = '1' then
			nAddress <= address - 1;
		else
			nAddress <= address;
		end if;
	end process;

	-- FSM to control the controller action
	process(state, run, counter, fwd, div, speed, bwd, txBusy)
	begin
		case state is

			-- default mode: sample data from input to memory
			when SAMPLE =>
				if run = '1' then
					nstate <= DELAY;
				else
					nstate <= state;
				end if;
				ncounter <= "000000000000000000";
				up <= '1';
				send <= '0';

			-- keep sampling for fwd samples after run condition
			when DELAY =>
				if counter = fwd & "00" then
					ncounter <= "000000000000000000";
					nstate <= READ;
				else
					if div = speed then
						ncounter <= counter + 1;
					else
						ncounter <= counter;
					end if;
					nstate <= state;
				end if;
				up <= '1';
				send <= '0';

			-- read back bwd samples after DELAY
			-- go into wait state after each sample to give transmitter time
			when READ =>
				if counter = bwd & "00" then
					ncounter <= "000000000000000000";
					nstate <= SAMPLE;
				else
					ncounter <= counter + 1;
					nstate <= READWAIT;
				end if;
				up <= '0';
				send <= '1';

			-- wait for the transmitter to become ready again
			when READWAIT =>
				if txBusy = '0' then
					nstate <= READ;
				else
					nstate <= state;
				end if;
				ncounter <= counter;
				up <= '0';
				send <= '0';

		end case;
	end process;

	-- set speed and size registers if indicated
	process(clock)
	begin
		if clock='1' and clock'event then

			if wrSpeed = '1' then
				speed <= data(23 downto 0);
			end if;
			
			if wrSize = '1' then
				fwd <= data(31 downto 16);
				bwd <= data(15 downto 0);
			end if;

		end if;
	end process;
	
end Behavioral;
