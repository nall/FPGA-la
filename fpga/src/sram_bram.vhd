----------------------------------------------------------------------------------
-- sram_bram.vhd
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
-- Simple BlockRAM interface.
-- 
-- This module should be used instead of sram.vhd if no external SRAM is present.
-- Instead, it will use internal BlockRAM (16 Blocks).
--
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity sram_bram is
    GENERIC
	(
		ADDRESS_WIDTH	: integer := 13
	);

    Port (
		clock : in  STD_LOGIC;
		output : out std_logic_vector(31 downto 0);          
		input : in std_logic_vector(31 downto 0);          
		read : in std_logic; 
		write : in std_logic
	);
end sram_bram;

architecture Behavioral of sram_bram is

signal address : std_logic_vector (ADDRESS_WIDTH - 1 downto 0);

signal bramIn, bramOut : std_logic_vector (31 downto 0);

COMPONENT BRAM8k32bit--SampleRAM
	PORT(
		WE : IN std_logic;
		DIN : IN std_logic_vector(31 downto 0);
		ADDR : IN std_logic_vector(ADDRESS_WIDTH - 1 downto 0);
		DOUT : OUT std_logic_vector(31 downto 0);
		CLK : IN std_logic
		);
	END COMPONENT;

begin

	-- assign signals
   output <= bramOut;
	
	-- memory io interface state controller
	bramIn <= input;
	
	-- memory address controller
	process(clock)
	begin
		if rising_edge(clock) then
			if write = '1' then
				address <= address + 1;
			elsif read = '1' then
				address <= address - 1;
			end if;
		end if;
	end process;

	-- sample block ram
	Inst_SampleRAM: BRAM8k32bit PORT MAP(
		ADDR => address,
		DIN => bramIn,
		WE => write,
		CLK => clock,
		DOUT => bramOut
	);
end Behavioral;

