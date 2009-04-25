----------------------------------------------------------------------------------
-- transmitter.vhd
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
-- Takes 32bit (one sample) and sends it out on the serial port.
-- End of transmission is signalled by taking back the busy flag.
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity transmitter is
	generic (
		FREQ : integer;
		RATE : integer
	);
   Port (
		data : in STD_LOGIC_VECTOR (31 downto 0);
		write : in std_logic;
      clock : in STD_LOGIC;
		tx : out STD_LOGIC;
		busy: out std_logic
	);
end transmitter;

architecture Behavioral of transmitter is

	constant BITLENGTH : integer := FREQ / RATE;

	signal txBuffer, nTxBuffer : std_logic_vector (39 downto 0) := "1000000000100000000010000000001000000000";
	signal nBits,bits : integer range 0 to 41;
	signal nCounter, counter : integer range 0 to BITLENGTH;
	signal nbusy : std_logic;
begin

	tx <= txBuffer(0);

	nbusy <= '0' when bits = 41 and write = '0' else '1'; 

	process(clock, write, data, counter, txBuffer, bits)
	begin
		if clock = '1' and clock'event then
			txBuffer <= nTxBuffer;
			counter <= nCounter;
			busy <= nbusy;
			bits <= nBits;
		end if;
		
		if write = '1' then
			nTxBuffer <= data(31 downto 24) & "0"
						& '1' & data(23 downto 16) & "0"
						& '1' & data(15 downto 8) & "0"
						& '1' & data(7 downto 0) & "01";
			nCounter <= 0;
			nBits <= 0;
		else
			if counter = BITLENGTH then
				nTxBuffer <=  '1' & txBuffer(39 downto 1);
				nCounter <= 0;
				if bits = 41 then
					nBits <= bits;
				else
					nBits <= bits + 1;
				end if;
			else
				nTxBuffer <= txBuffer;
				nCounter <= counter + 1;
				nBits <= bits;
			end if;
		end if;
	end process;

end Behavioral;
