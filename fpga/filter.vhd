----------------------------------------------------------------------------------
-- filter.vhd
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
-- Fast 32 channel digital noise filter using a single LUT function for each
-- individual channel. It will filter out all signals that are exactly one
-- clock cycle long. To not filter out good signals it runs at twice
-- the frequency as the maximum sampling rate.
--
-- Noise cancelation is important when connecting to 5V signals with high
-- slew rate, because cross talk will occur.
-- It may or may not be necessary with low voltage signals.
--
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity filter is
    Port ( input : in  STD_LOGIC_VECTOR (31 downto 0);
			  clock2x : in std_logic;
			  clock : in std_logic;
           output : out  STD_LOGIC_VECTOR (31 downto 0));
end filter;

architecture Behavioral of filter is

signal lastInput, nresult, result : STD_LOGIC_VECTOR (31 downto 0);

begin
	-- synchronize result with system clock
	-- (result is stable for at least 2 clock2x cycles and thus always catched)
	process(clock)
	begin
		if clock = '1' and clock'event then
			output <= result;
		end if;
	end process;

	-- perform result change on rising edge
	process(clock2x)
	begin
		if clock2x = '1' and clock2x'event then
			result <= nresult;
			lastInput <= input;
		end if;
	end process;

	-- determine next result
	process(input, lastInput, result)
	begin
		for i in 31 downto 0 loop
			if 
				(input(i) = '0' and lastInput(i) = '0' and result(i) = '0')
				or (input(i) = '0' and lastInput(i) = '0' and result(i) = '1')
				or (input(i) = '0' and lastInput(i) = '1' and result(i) = '0')
				or (input(i) = '1' and lastInput(i) = '0' and result(i) = '0')
			then
				nresult(i) <= '0';
			else
				nresult(i) <= '1';
			end if;
		end loop;
	end process;

end Behavioral;
