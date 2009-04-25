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

import java.awt.Color;
import java.awt.Dimension;
import java.awt.Graphics;
import java.awt.Rectangle;

import javax.swing.JComponent;
/**
 * This component displays a logic level diagram which is obtained from a {@link CapturedData} object.
 * <p>
 * Component size changes with the size of the diagram.
 * Therefore it should only be used from within a JScrollPane.
 *
 * @version 0.3
 * @author Michael "Mr. Sump" Poppitz
 *
 */
public class Diagram extends JComponent {

	/**
	 * Create a new empty diagram to be placed in a container.
	 *
	 */
	public Diagram() {
		super();
		
		this.size = new Dimension(25, 32 * 20);
		
		this.signal = new Color(0,0,196);
		this.trigger = new Color(196,255,196);
		this.grid = new Color(196,196,196);
		this.text = new Color(0,0,0);
		this.time = new Color(0,0,0);
		this.background = new Color(255,255,255);
		
		zoomDefault();
		setBackground(background);

		this.capturedData = null;
	}
	
	/**
	 * Resizes the diagram as required by available data and scaling factor.
	 *
	 */
	private void resize() {
		if (capturedData == null)
			return;
	
		int[] data = capturedData.values;
		Rectangle rect = getBounds();
		rect.setSize((int)(25 + scale * data.length), rect.getSize().height);
		setBounds(rect);
		size.width = (int)(25 + scale * data.length);
		update(this.getGraphics());
	}
	
	/**
	 * Sets the captured data object to use for drawing the diagram.
	 * 
	 * @param capturedData		captured data to base diagram on
	 */
	public void setCapturedData(CapturedData capturedData) {
		this.capturedData = capturedData;
		resize();
	}

	/**
	 * Returns the captured data object currently displayed in the diagram.
	 * 
	 * @return diagram's current captured data
	 */
	public CapturedData getCapturedData() {
		return (capturedData);
	}

	
	/**
	 * Zooms in by factor 2 and resizes the component accordingly.
	 *
	 */
	public void zoomIn() {
		if (scale < 10) {
			scale = scale * 2;
			resize();
		}
	}
	
	/**
	 * Zooms out by factor 2 and resizes the component accordingly.
	 *
	 */
	public void zoomOut() {
		scale = scale / 2;
		resize();
	}
	
	/**
	 * Reverts back to the standard zoom level.
	 *
	 */
	public void zoomDefault() {
		scale = 10;
		resize();
	}

	/**
	 * Gets the dimensions of the full diagram.
	 * Used to inform the container (preferrably a JScrollPane) about the size.
	 */
	public Dimension getPreferredSize() {
		return (size);
	}
	
	/**
	 * Gets the dimensions of the full diagram.
	 * Used to inform the container (preferrably a JScrollPane) about the size.
	 */
	public Dimension getMinimumSize() {
		return (size);
	}

	/**
	 * Paints the diagram to the extend necessary.
	 */
	public void paintComponent(Graphics g) {
		if (capturedData == null)
			return;
		
		int[] data = capturedData.values;
		int triggerPosition = capturedData.triggerPosition;
		int rate = capturedData.rate;
		
		int xofs = 25;
		int yofs = 20;

		// obtain portion of graphics that needs to be drawn
		Rectangle clipArea = g.getClipBounds();

		// paint portion of background that needs drawing
		g.setColor(background);
		g.fillRect(clipArea.x, clipArea.y, clipArea.width, clipArea.height);

		// find index of first row that needs drawing
		int firstRow = (int)((clipArea.x - xofs)/ scale);
		if (firstRow < 0)
			firstRow = 0;
			
		// find index of last row that needs drawing
		int lastRow = (int)((clipArea.x + clipArea.width) / scale);
		if (lastRow >= data.length)
 			lastRow = data.length - 1;

		// draw trigger if existing and visible
		if (triggerPosition >= firstRow && triggerPosition <= lastRow) {
			g.setColor(trigger);
			g.fillRect(xofs + (int)(triggerPosition * scale) - 1, 0, (int)(scale) + 2, yofs + 32 * 20);		
		}
		
		// draw channel separators
		for (int bit = 0; bit < 32; bit++) {
			g.setColor(grid);
			g.drawLine(clipArea.x, 20 * bit + yofs + 15, clipArea.x + clipArea.width, 20 * bit + yofs + 15);
			g.setColor(text);
			g.drawString("" + bit, 5, 20 * bit + yofs + 10);
		}
		
		// draw time line
		if (rate > 0) {
			int rowInc = (int)(100 / scale);
			long unitMul = 1;
			String unitName = "s";
			if (rowInc / (float)rate <= 0.000001) { unitMul = 1000000000; unitName = "ns"; } 
			else if (rowInc / (float)rate <= 0.001) { unitMul = 1000000; unitName = "µs"; } 
			else if (rowInc / (float)rate <= 1) { unitMul = 1000; unitName = "ms"; } 

			g.setColor(time);
			for (int row = (firstRow / rowInc) * rowInc; row < lastRow; row += rowInc) {
				int pos = (int)(xofs + scale * row);
				g.drawLine(pos, 1, pos, 15);
				g.drawString((Math.round(10 * (row * unitMul) / (float)rate) / 10F) + unitName, pos + 5, 10);
				for (int sub = rowInc / 10; sub < rowInc; sub += rowInc / 10)
					g.drawLine(pos + (int)(sub * scale), 12, pos + (int)(sub * scale), 15);
			}
		}
		
		// draw actual signals
		g.setColor(signal);
		for (int row = firstRow; row < lastRow; row++) {
			for (int bit = 0; bit < 32; bit++) {
				int val1 = 1 - ((data[row] >> bit) & 1);
				int val2 = 1 - ((data[row + 1] >> bit) & 1);
				int edgeX;
				if (scale >= 5) {
					edgeX = (int)(xofs + scale * (row + 0.3));
				} else {
					edgeX = (int)(xofs + scale * row);
				}
				g.drawLine(
					(int)(xofs + scale * row),
					yofs + 20 * bit + 10 * val1,
					edgeX,
					yofs + 20 * bit + 10 * val2
				);
				g.drawLine(
					edgeX,
					yofs + 20 * bit + 10 * val2,
					(int)(xofs + scale * (row + 1)),
					yofs + 20 * bit + 10 * val2
				);
			}
		}
	}

	private CapturedData capturedData;
	
	private float scale;
	
	private Color signal;
	private Color trigger;
	private Color grid;
	private Color text;
	private Color time;
	private Color background;
	
	private Dimension size;

	private static final long serialVersionUID = 1L;
}
