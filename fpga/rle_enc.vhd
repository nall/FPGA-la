----------------------------------------------------------------------------------
-- rle_enc.vhd
--
-- Copyright (C) 2007 Jonas Diemer
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
-- Details: http://www.sump.org/projects/analyzer/
--
-- Run Length Encoder
--
-- If enabled, encode the incoming data with the following scheme:
-- The MSB (bit 31) is used as a flag for the encoding.
-- If the MSB is clear, the datum represents "regular" data
--  if set, the datum represents the number of repetitions of the previous data
--
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity rle_enc is
    Port ( clock : in  STD_LOGIC;
			  reset : in STD_LOGIC;
			  dataIn : in  STD_LOGIC_VECTOR (31 downto 0);
           validIn : in  STD_LOGIC;
           enable : in  STD_LOGIC;
           dataOut : out  STD_LOGIC_VECTOR (31 downto 0);
           validOut : out  STD_LOGIC);
end rle_enc;

architecture Behavioral of rle_enc is

signal old: std_logic_vector(30 downto 0);
signal dout: std_logic_vector(31 downto 0);

signal ctr: std_logic_vector(30 downto 0);

signal valid, valout: std_logic;

begin

	dataOut <= dataIn when (enable = '0') else dout;
	validOut <= validIn when (enable = '0') else valout;
	
	-- shift register
	process(clock, reset)
	begin
		if (reset = '1') then
			valid <= '0';
		elsif rising_edge(clock) then
			if (validIn = '1') then
				old <= dataIn(30 downto 0);
				valid <= '1';
			end if;
		end if;
	end process;
	
	
	-- RLE encoder
	process(clock, reset)
	begin
		if (reset = '1') then
			ctr <= (others => '0');
		elsif rising_edge(clock) then
			valout <= '0'; --default
			if (enable = '0') then
				ctr <= (others => '0');
			elsif (valid = '1') AND (validIn = '1') then
				if (old = dataIn(30 downto 0)) then
					if (ctr = 0) then -- write first datum of series
						dout <= '0' & dataIn(30 downto 0); -- discard MSB, which is used for encoding a count
						valout <= '1';
					elsif (ctr = "111111111111111111111111111111") then -- ctr overflow
						dout <= '1' & ctr;	-- write count
						valout <= '1';
						ctr <= (others => '0'); -- reset count, so "series" starts again. 
					end if;
					ctr <= ctr + 1;
				else -- series complete, write count (or data, if series was 0 or 1 long)
					valout <= '1';
					ctr <= (others => '0');
					if (ctr > 1) then -- TODO: try if /=0 AND /=1 is faster than >1
						dout <= '1' & ctr;
					else
						dout <= '0' & old;
					end if;
				end if;
			end if;
		end if;
	end process;

end Behavioral;

