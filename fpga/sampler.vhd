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
-- Produces samples from input applying a programmabe divider to the clock.
-- Sampling rate can be calculated by:
--
--     r = f / (d + 1)
--
-- Where r is the sampling rate, f is the clock frequency and d is the value
-- programmed into the divider register.
--
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity sampler is
    Port ( input : in  STD_LOGIC_VECTOR (31 downto 0);
           clock : in  STD_LOGIC;
           data : in  STD_LOGIC_VECTOR (23 downto 0);
           wrDivider : in  STD_LOGIC;
           sample : out  STD_LOGIC_VECTOR (31 downto 0);
           ready : out  STD_LOGIC);
end sampler;

architecture Behavioral of sampler is

signal divider, counter : std_logic_vector (23 downto 0);

begin

	process(clock)
	begin
		if rising_edge(clock) then

			if wrDivider = '1' then
				divider <= data(23 downto 0);
				counter <= (others => '0');
				ready <= '0';

			elsif counter = divider then
				sample <= input;
				counter <= (others => '0');
				ready <= '1';
				
			else
				counter <= counter + 1;
				ready <= '0';

			end if;
		end if;
	end process;

end Behavioral;

