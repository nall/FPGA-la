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

import java.awt.BorderLayout;
import java.awt.Container;
import java.awt.Insets;
import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;
import java.awt.event.WindowAdapter;
import java.awt.event.WindowEvent;
import java.awt.event.WindowListener;
import java.io.File;
import javax.swing.filechooser.FileFilter;

import javax.swing.ImageIcon;
import javax.swing.JButton;
import javax.swing.JFileChooser;
import javax.swing.JFrame;
import javax.swing.JMenu;
import javax.swing.JMenuBar;
import javax.swing.JMenuItem;
import javax.swing.JScrollPane;
import javax.swing.JSeparator;
import javax.swing.JToolBar;

/**
 * Main frame and starter for Logic Analyzer Client.
 * <p>
 * This class only provides a simple end-user frontend and no functionality to be used by other code.
 * 
 * @version 0.3
 * @author Michael "Mr. Sump" Poppitz
 */
public final class MainWindow extends WindowAdapter implements ActionListener, WindowListener {

	/**
	 * Creates a JMenu containing items as specified.
	 * If an item name is empty, a separator will be added in its place.
	 * 
	 * @param name Menu name
	 * @param entries array of menu item names.
	 * @return created menu
	 */
	private JMenu createMenu(String name, String[] entries) {
		JMenu menu = new JMenu(name);
		for (int i = 0; i < entries.length; i++) {
			if (!entries[i].equals("")) {
				JMenuItem item = new JMenuItem(entries[i]);
				item.addActionListener(this);
				menu.add(item);
			} else {
				menu.add(new JSeparator());
			}
		}
		return (menu);
	}
	
	/**
	 * Creates tool icons and adds them the the given tool bar.
	 * 
	 * @param tools tool bar to add icons to
	 * @param files array of icon file names
	 * @param descriptions array of icon descriptions
	 */
	private void createTools(JToolBar tools, String[] files, String[] descriptions) {
		for (int i = 0; i < files.length; i++) {
			JButton b = new JButton(new ImageIcon("org/sump/analyzer/icons/" + files[i], descriptions[i]));
			b.setMargin(new Insets(0,0,0,0));
			b.addActionListener(this);
			tools.add(b);
		}
	}

	/**
	 * Inner class defining a File Filter for SLA files.
	 * 
	 * @author Michael "Mr. Sump" Poppitz
	 *
	 */
	private class SLAFilter extends FileFilter {
		public boolean accept(File f) {
			return (f.getName().toLowerCase().endsWith(".sla"));
		}
		public String getDescription() {
			return ("Sump's Logic Analyzer Files (*.sla)");
		}
	}
	
	/**
	 * Constructs and displays the main window.
	 *
	 */
	public MainWindow() {
		super();
		
		frame = new JFrame("Logic Analyzer Client");
		frame.setIconImage((new ImageIcon("org/sump/analyzer/icons/la.png")).getImage());
		Container contentPane = frame.getContentPane();
		contentPane.setLayout(new BorderLayout());

		JMenuBar mb = new JMenuBar();
		
		// file menu
		String[] fileEntries = {"Open...", "Save as...", "", "Exit"};
		JMenu fileMenu = createMenu("File", fileEntries);
		mb.add(fileMenu);

		// device menu
		String[] deviceEntries = {"Capture...", "Repeat Capture"};
		JMenu deviceMenu = createMenu("Device", deviceEntries);
		mb.add(deviceMenu);
		
		// diagram menu
		String[] diagramEntries = {"Zoom in", "Zoom out", "Default Zoom"};
		JMenu diagramMenu = createMenu("Diagram", diagramEntries);
		mb.add(diagramMenu);
		
		frame.setJMenuBar(mb);
		
		JToolBar tools = new JToolBar();
		tools.setRollover(true);
		tools.setFloatable(false);
		
		String[] fileToolsF = {"fileopen.png", "filesaveas.png"}; // , "fileclose.png"};
		String[] fileToolsD = {"Open...", "Save as..."}; // , "Close"};
		createTools(tools, fileToolsF, fileToolsD);
		tools.addSeparator();

		String[] deviceToolsF = {"launch.png", "reload.png"};
		String[] deviceToolsD = {"Capture...", "Repeat Capture"};
		createTools(tools, deviceToolsF, deviceToolsD);
		tools.addSeparator();

		String[] diagramToolsF = {"viewmag+.png", "viewmag-.png", "viewmag1.png"};
		String[] diagramToolsD = {"Zoom In", "Zoom Out", "Default Zoom"};
		createTools(tools, diagramToolsF, diagramToolsD);
		
		contentPane.add(tools, BorderLayout.NORTH);
		
		diagram = new Diagram();
		contentPane.add(new JScrollPane(diagram), BorderLayout.CENTER);

		frame.setSize(1000, 750);
		frame.setVisible(true);
		frame.addWindowListener(this);

		fileChooser = new JFileChooser();
		fileChooser.addChoosableFileFilter((FileFilter) new SLAFilter());

		controller = new DeviceController();
	}
	
	/**
	 * Handles all user interaction.
	 */
	public void actionPerformed(ActionEvent event) {
		String label = event.getActionCommand();
		// if no action command, check if button and if so, use icon description as action
		if (label.equals("")) {
			if (event.getSource() instanceof JButton)
				label = ((ImageIcon)((JButton)event.getSource()).getIcon()).getDescription();
		}
		System.out.println(label);
		try {
			
			if (label.equals("Open...")) {
				if (fileChooser.showOpenDialog(frame) == JFileChooser.APPROVE_OPTION) {
					File file = fileChooser.getSelectedFile();
					if (file.isFile()) {
						System.out.println("Opening: " + file.getName() + ".");
						diagram.setCapturedData(new CapturedData(file));
					}
				}
			
			} else if (label.equals("Save as...")) {
				if (fileChooser.showSaveDialog(frame) == JFileChooser.APPROVE_OPTION) {
					File file = fileChooser.getSelectedFile();
					System.out.println("Saving: " + file.getName() + ".");
					diagram.getCapturedData().writeToFile(file);
				}
			
			} else if (label.equals("Capture...")) {
				if (controller.showCaptureDialog(frame) == DeviceController.DATA_READ) {
					diagram.setCapturedData(controller.getDeviceData());
				}

			} else if (label.equals("Repeat Capture")) {
				if (controller.showCaptureProgress(frame) == DeviceController.DATA_READ) {
					diagram.setCapturedData(controller.getDeviceData());
				}

			} else if (label.equals("Exit")) {
				exit();
			
			} else if (label.equals("Zoom In")) {
				diagram.zoomIn();
			
			} else if (label.equals("Zoom Out")) {
				diagram.zoomOut();
			} else if (label.equals("Default Zoom")) {
				diagram.zoomDefault();
			}
		} catch(Exception E) {
			E.printStackTrace(System.out);
		}
	}
	
	/**
	 * Handles window close requests.
	 */
	public void windowClosing(WindowEvent event) {
		exit();
	}
	
	/**
	 * Home of the main thread.
	 * Which happens to be a lazy one.
	 */
	// TODO: Check if it really needs to live as long as the program runs.
	public void run() {
		thread = Thread.currentThread();
		done = false;
		while (!done) {
			try {
				Thread.sleep(1000);
			} catch (Exception E) {
				// ignore 
			}
		}
	}
	
	/**
	 * Tells the main thread to exit. This will stop stop the VM.
	 */
	public void exit() {
		done = true;
		if (thread != null) {
			thread.interrupt();
		} else {
			// bummer
		}
	}
		
	/**
	 * Starts up the logic analyzer client.
	 * @param args	no arguments are supported
	 */
	public static void main(String[] args) {
		MainWindow w = new MainWindow();
		w.run();
		System.exit(0);
	}

	private JFileChooser fileChooser;
	private DeviceController controller;
	private Diagram diagram;
	
	private JFrame frame;
	private Thread thread;
	private boolean done; 
}
