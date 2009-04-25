----------------------------------------------------------------------------------
-- decoder.vhd
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
-- Takes the lowest byte from the command received by the receiver
-- which is the opcode of the command. 
-- The decoded command will be performed for only one cycle. This
-- makes it somewhat independent of the receiver timings. 
--
-- The receiver keeps the cmd output active long enough so all the
-- data is still available on its cmd output when the command has
-- been decoded and sent out to other modules with the next
-- clock cycle. (Maybe this paragraph should go in receiver.vhd?)
--
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity decoder is
   Port ( opcode : in  STD_LOGIC_VECTOR (7 downto 0);
	   clock : in std_logic;
      wrtrigmask : out  STD_LOGIC;
      wrtrigval : out  STD_LOGIC;
	   wrspeed : out STD_LOGIC;
	   wrsize : out STD_LOGIC;
		arm : out STD_LOGIC;
		reset : out STD_LOGIC
	);
end decoder;

architecture Behavioral of decoder is

signal	exe, set, trigger : std_logic;
signal	regid : std_logic_vector(4 downto 0);
signal	exeReg : std_logic;

begin

	(set, trigger, regid(4), regid(3), regid(2), regid(1), regid(0), exe) <= opcode;

	process(clock)
	begin
		if clock = '1' and clock'event then
			wrtrigmask <= exe and set and trigger and regid(0) and not exeReg;
			wrtrigval <= exe and set and trigger and regid(1) and not exeReg;
			wrspeed <= exe and set and not trigger and regid(0) and not exeReg;
			wrsize <= exe and set and not trigger and regid(1) and not exeReg;

			-- hack: reset uses two bits at the moment to avoid unused input warnings
			reset <= exe and regid(3) and regid(2) and not exeReg;
			arm <= exe and regid(4) and not exeReg;

			exeReg <= exe;
		end if;
	end process;

end Behavioral;
