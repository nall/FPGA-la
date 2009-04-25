----------------------------------------------------------------------------------
-- demux.vhd
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
-- Demultiplexes 16 input channels into 32 output channels,
-- thus doubling the sampling rate for those channels.
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity demux is
    Port ( input : in  STD_LOGIC_VECTOR (15 downto 0);
			  clock : in std_logic;
			  clock180 : in std_logic;
           output : out  STD_LOGIC_VECTOR (31 downto 0));
end demux;

architecture Behavioral of demux is

signal part : std_logic_vector (15 downto 0);

begin

	process (clock180)
	begin
		if rising_edge(clock180) then
			part <= input;
		end if;
	end process;

	process (clock)
	begin
		if rising_edge(clock) then
			output <= part & input;
		end if;
	end process;

end Behavioral;

