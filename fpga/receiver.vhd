----------------------------------------------------------------------------------
-- receiver.vhd
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
-- Receives 40 bits from the serial port. The first bit received has to
-- be '1' because it serves as buffer full indicator. (And execute flag
-- for the decoder.)
-- After a full command has been received it will be kept available for 10 cycles
-- on the cmd output. (A valid command can be detected by checking if cmd(0)
-- is set.) After this the register will be cleared automatically and the 
-- receiver waits for new data from the serial port.
--
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity receiver is
	generic (
		FREQ : integer;
		RATE : integer
	);

   Port ( rx : in STD_LOGIC;
           clock : in STD_LOGIC;
			  reset : in STD_LOGIC;
           cmd : inout STD_LOGIC_VECTOR (39 downto 0)
	);
end receiver;

architecture Behavioral of receiver is

	type UART_STATES is (INIT, WAITSTOP, WAITSTART, WAITBEGIN, READBYTE, READY);

	constant BITLENGTH : integer := FREQ / RATE;

	signal ncmd : STD_LOGIC_VECTOR (39 downto 0);				-- command buffer
	signal counter, ncounter : integer range 0 to BITLENGTH;	-- clock prescaling counter
	signal bitcount, nbitcount : integer range 0 to 8; 		-- count rxed bits
	signal state, nstate : UART_STATES;								-- receiver state

begin

	process(clock, reset)
	begin
		if reset = '1' then
			state <= INIT;
		elsif clock = '1' and clock'event then
			counter <= ncounter;
			bitcount <= nbitcount;
			cmd <= ncmd;
			state <= nstate;
		end if;
	end process;

	process(state, counter, bitcount, cmd, rx)
	begin
		case state is

			-- reset uart
			when INIT =>
				ncounter <= 0;
				nbitcount <= 0;
				ncmd <= "0000000000000000000000000000000000000000";
				nstate <= WAITSTOP;

			-- wait for stop bit
			when WAITSTOP =>
				ncounter <= 0; 
				nbitcount <= 0;
				ncmd <= cmd;
				if rx = '1' then
					nstate <= WAITSTART;
				else
					nstate <= state;
				end if;

			-- wait for start bit
			when WAITSTART =>
				ncounter <= 0; 
				nbitcount <= 0;
				ncmd <= cmd;
				if rx = '0' then
					nstate <= WAITBEGIN;
				else
					nstate <= state;
				end if;

			-- wait for end of start bit
			when WAITBEGIN =>
				nbitcount <= 0;
				ncmd <= cmd;
				if counter = BITLENGTH / 2 then
					ncounter <= 0; 
					nstate <= READBYTE;
				else
					ncounter <= counter + 1;
					nstate <= state;
				end if;
				
			-- receive byte
			when READBYTE =>
				if counter = BITLENGTH then
					ncounter <= 0;
					nbitcount <= bitcount + 1;
					if cmd(0) = '1' then
						nstate <= READY;
						ncmd <= cmd;
					elsif bitcount = 8 then
						nstate <= WAITSTOP;
						ncmd <= cmd;
					else
						ncmd <= rx & cmd(39 downto 1);
						nstate <= state;
					end if;
				else
					ncounter <= counter + 1;
					nbitcount <= bitcount;
					ncmd <= cmd;
					nstate <= state;
				end if;

			-- done, cmd buffer full, give 10 cycles for processing
			when READY =>
				ncounter <= counter + 1;
				nbitcount <= 0;
				ncmd <= cmd;
				if counter = 10 then
					nstate <= INIT;
				else
					nstate <= state;
				end if;
					
		end case;

	end process;

end Behavioral;
