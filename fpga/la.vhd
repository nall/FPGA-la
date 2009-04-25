----------------------------------------------------------------------------------
-- la.vhd
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
-- Logic Analyzer top level module. It connects all the other modules
-- and defines all inputs and outputs that representent phyisical pins of
-- the fpga.
--
-- It defines two constants FREQ and RATE. The first is the clock frequency 
-- used for receiver and transmitter for generating the proper baud rate.
-- The second defines the speed at which to operate the serial port.
--
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity la is
	Port(
		clockIn : in std_logic;
	   resetSwitch : in std_logic;
		input : in std_logic_vector(31 downto 0);
		rx : in std_logic;
		tx : inout std_logic;

		an : OUT std_logic_vector(3 downto 0);
		segment : OUT std_logic_vector(7 downto 0);
		led : OUT std_logic_vector(7 downto 0);

		switch : in std_logic_vector(1 downto 0);

		ramIO1 : INOUT std_logic_vector(15 downto 0);
		ramIO2 : INOUT std_logic_vector(15 downto 0);      
		ramA : OUT std_logic_vector(17 downto 0);
		ramWE : OUT std_logic;
		ramOE : OUT std_logic;
		ramCE1 : OUT std_logic;
		ramUB1 : OUT std_logic;
		ramLB1 : OUT std_logic;
		ramCE2 : OUT std_logic;
		ramUB2 : OUT std_logic;
		ramLB2 : OUT std_logic
	);
end la;

architecture Behavioral of la is

	COMPONENT clockman
	PORT(
		clkin : IN std_logic;       
		clk0 : INOUT std_logic;
		clk2x : INOUT std_logic
		);
	END COMPONENT;
	
	COMPONENT receiver
	generic (
		FREQ : integer;
		RATE : integer
	);
	PORT(
		rx : IN std_logic;
		clock : IN std_logic;    
	   reset : in STD_LOGIC;
		cmd : INOUT std_logic_vector(39 downto 0)
	   );
	END COMPONENT;

	COMPONENT decoder
	PORT ( opcode : in  STD_LOGIC_VECTOR (7 downto 0);
			  clock : in std_logic;
           wrtrigmask : out  STD_LOGIC;
           wrtrigval : out  STD_LOGIC;
			  wrspeed : out STD_LOGIC;
			  wrsize : out std_logic;
			  arm : out std_logic;
			  reset : out std_logic
		);
	END COMPONENT;
	
	COMPONENT filter
	PORT(
		input : IN std_logic_vector(31 downto 0);
		clock2x : IN std_logic;
		clock : IN std_logic;
		output : OUT std_logic_vector(31 downto 0)
		);
	END COMPONENT;

	COMPONENT trigger
	PORT(
		input : IN std_logic_vector(31 downto 0);
		data : IN std_logic_vector(31 downto 0);
	   clock : in std_logic;
		reset : in std_logic;
		wrMask : IN std_logic;
		wrValue : IN std_logic;
		arm : IN std_logic;          
		run : OUT std_logic
		);
	END COMPONENT;

	COMPONENT controller
	PORT(
		clock : IN std_logic;
		reset : in std_logic;
		input : IN std_logic_vector(31 downto 0);    
		data : in std_logic_vector(31 downto 0);
		wrSpeed : in std_logic;
		wrSize : in std_logic;
		run : in std_logic;
		txBusy : in std_logic;
		send : inout std_logic;
		output : out std_logic_vector(31 downto 0);    
		ramIO1 : INOUT std_logic_vector(15 downto 0);
		ramIO2 : INOUT std_logic_vector(15 downto 0);      
		ramA : OUT std_logic_vector(17 downto 0);
		ramWE : OUT std_logic;
		ramOE : OUT std_logic;
		ramCE1 : OUT std_logic;
		ramUB1 : OUT std_logic;
		ramLB1 : OUT std_logic;
		ramCE2 : OUT std_logic;
		ramUB2 : OUT std_logic;
		ramLB2 : OUT std_logic
		);
	END COMPONENT;

	COMPONENT transmitter
	generic (
		FREQ : integer;
		RATE : integer
	);
	PORT(
		data : IN std_logic_vector(31 downto 0);
		write : IN std_logic;
		clock : IN std_logic;
		tx : OUT std_logic;
		busy : out std_logic
		);
	END COMPONENT;

	COMPONENT display
	PORT(
		data : IN std_logic_vector(31 downto 0);
		clock : IN std_logic;          
		an : OUT std_logic_vector(3 downto 0);
		segment : OUT std_logic_vector(7 downto 0)
		);
	END COMPONENT;

signal command : std_logic_vector (39 downto 0);
signal displayData : std_logic_vector (31 downto 0);
signal output : std_logic_vector (31 downto 0);
signal wrtrigmask, wrtrigval, wrspeed, wrsize, run, arm, txBusy, send : std_logic;
signal filteredInput : std_logic_vector (31 downto 0);
signal clock, clock2x, reset, resetCmd: std_logic;

constant FREQ : integer := 100000000;
constant RATE : integer := 115200;

begin
	-- switches and leds are kept in design to be available for debugging
	led(7 downto 0) <= "0000" & switch & (tx, rx);
	displayData <= output;

	reset <= resetSwitch or resetCmd;

	Inst_clockman: clockman PORT MAP(
		clkin => clockIn,
		clk0 => clock,
		clk2x => clock2x
	);
	
	Inst_receiver: receiver
	generic map (
		FREQ => FREQ,
		RATE => RATE
	)
	PORT MAP(
		rx => rx,
		clock => clock,
		reset => reset,
		cmd => command
	);

	Inst_decoder: decoder PORT MAP(
		opcode => command(7 downto 0),
		clock => clock,
		wrtrigmask => wrtrigmask,
		wrtrigval => wrtrigval,
		wrspeed => wrspeed,
		wrsize => wrsize,
		arm => arm,
		reset => resetCmd
	);


	Inst_filter: filter PORT MAP(
		input => input,
		clock2x => clock2x,
		clock => clock,
		output => filteredInput
	);
	
	Inst_trigger: trigger PORT MAP(
		input => filteredInput,
		data => command(39 downto 8),
		clock => clock,
		reset => reset,
		wrMask => wrtrigmask,
		wrValue => wrtrigval,
		arm => arm,
		run => run
	);

	Inst_controller: controller PORT MAP(
		clock => clock,
		reset => reset,
		input => filteredInput,
		data => command(39 downto 8),
		wrSpeed => wrspeed,
		wrSize => wrsize,
		run => run,
		txBusy => txBusy,
		send => send,
		output => output,
		ramA => ramA,
		ramWE => ramWE,
		ramOE => ramOE,
		ramIO1 => ramIO1,
		ramCE1 => ramCE1,
		ramUB1 => ramUB1,
		ramLB1 => ramLB1,
		ramIO2 => ramIO2,
		ramCE2 => ramCE2,
		ramUB2 => ramUB2,
		ramLB2 => ramLB2 
	);

	Inst_transmitter: transmitter
	generic map (
		FREQ => FREQ,
		RATE => RATE
	)
	PORT MAP(
		data => output,
		write => send,
		clock => clock,
		tx => tx,
		busy => txBusy
	);
	
	Inst_display: display PORT MAP(
		data => displayData,
		clock => clock,
		an => an,
		segment => segment
	);

end Behavioral;

