----------------------------------------------------------------------------------
-- trigger.vhd
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
-- 32 channel trigger with programmable mask and value registers.
-- The trigger will output a one cycle run signal if armed and
-- the trigger condition is met. It is met when all bits of the
-- input indicated by mask register have the value indicated by
-- the matching bit of the value register.
-- The trigger will disarm itself after firing or when reset is set.
--
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity trigger is
    Port ( input : in  STD_LOGIC_VECTOR (31 downto 0);
           data : in  STD_LOGIC_VECTOR (31 downto 0);
			  clock : in std_logic;
			  reset : in std_logic;
           wrMask : in  STD_LOGIC;
           wrValue : in  STD_LOGIC;
           arm : in  STD_LOGIC;
           run : out  STD_LOGIC
	);
end trigger;

architecture Behavioral of trigger is
	signal	maskRegister : STD_LOGIC_VECTOR (31 downto 0);
	signal	valueRegister : STD_LOGIC_VECTOR (31 downto 0);
	signal	match, armed : STD_LOGIC;

begin

	-- match indicates if the trigger condition is met
	match <= '1' when ((input xor valueRegister) and maskRegister) = "00000000000000000000000000000000" else '0';

	-- handle reset and arm requests; output run signal if armed and match
	process(clock, reset)
	begin
		if reset = '1' then
			armed <= '0';
			run <= '0';
		elsif clock = '1' and clock'event then
			if arm = '1' then
				armed <= '1';
			end if;
			if match = '1' and armed = '1' then
				armed <= '0';
				run <= '1';
			else
				run <= '0';
			end if;
		end if;
	end process;
	
	-- handle mask & value write requests
	process(clock) 
	begin
		if clock = '1' and clock'event then
			if wrMask = '1' then
				maskRegister <= data;
			end if;
			if wrValue = '1' then
				valueRegister <= data;
			end if;
		end if;
	end process;

end Behavioral;

