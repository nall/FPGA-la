/*
 *  Copyright (C) 2006 Michael Poppitz
 * 
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or (at
 *  your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful, but
 *  WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 *  General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License along
 *  with this program; if not, write to the Free Software Foundation, Inc.,
 *  51 Franklin St, Fifth Floor, Boston, MA 02110, USA
 *
 */
package org.sump.analyzer;

import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.File;
import java.io.FileReader;
import java.io.FileWriter;
import java.io.IOException;

/**
 * CapturedData encapsulates the data obtained by the analyzer during a single run.
 * It also provides a method for (partially) saving the data to a file.
 * <p>
 * Data files will only contain the actual readout values. A value is a
 * single logic level measurement of all channels at a particular time.
 * This means a value is 32bits long. The value is encoded in hex and
 * each value is followed by a new line.
 * <p>
 * In the java code each value is represented by an integer.
 * 
 * @version 0.3
 * @author Michael "Mr. Sump" Poppitz
 *
 */
public class CapturedData extends Object {
	/**
	 * Constructs CapturedData based on the given data.
	 * 
	 * @param values 32bit values as read from device
	 * @param triggerPosition position of trigger as index of values array
	 */
	protected CapturedData(int[] values, int triggerPosition, int rate) {
		this.values = values;
		this.triggerPosition = triggerPosition;
		this.rate = rate; 
	}

	/**
	 * Constructs CapturedData based on the data read from the given file.
	 * 
	 * @param file			file to read captured data from
	 * @throws IOException when reading from file failes
	 */
	public CapturedData(File file) throws IOException {
		int size = 0, r = -1, t = -1;
		String line;
		BufferedReader br = new BufferedReader(new FileReader(file));
		do {
			line = br.readLine();
			if (line == null)
				throw new IOException("File appears to be corrupted.");
			else if (line.startsWith(";Size: "))
				size = Integer.parseInt(line.substring(7));
			else if (line.startsWith(";Rate: "))
				r = Integer.parseInt(line.substring(7));
			else if (line.startsWith(";TriggerPosition: "))
				t = Integer.parseInt(line.substring(18));
		} while (line.startsWith(";"));

		if (size <= 0 || size > 1024 * 256)
			throw new IOException("Invalid size encountered.");
			
		values = new int[size];
		try {
			for (int i = 0; i < values.length && line != null; i++) {
				values[i] =
					Integer.parseInt(line.substring(0, 4), 16) << 16
					| Integer.parseInt(line.substring(4, 8), 16);
				line = br.readLine();
			}
		} catch (NumberFormatException E) {
			throw new IOException("Invalid data encountered.");
		}

		triggerPosition = t;
		rate = r;

		br.close();
	}
	
	/**
	 * Writes device data to given file.
	 * 
	 * @param file			file to write to
	 * @throws IOException when writing to file failes
	 */
	public void writeToFile(File file) throws IOException  {
		try {
			BufferedWriter bw = new BufferedWriter(new FileWriter(file));
			
			bw.write(";Size: " + values.length);
			bw.newLine();
			bw.write(";Rate: " + rate);
			bw.newLine();
			bw.write(";TriggerPosition: " + triggerPosition);
			bw.newLine();
			
			for (int i = 0; i < values.length; i++) {
				bw.write(Integer.toHexString(values[i]));
				bw.newLine();
			}
			bw.close();
		} catch (Exception E) {
			E.printStackTrace(System.out);
		}
	}

	/** captured values */
	public final int[] values;
	/** position of trigger as index of values */
	public final int triggerPosition;
	/** sampling rate in Hz */
	public final int rate;
}
