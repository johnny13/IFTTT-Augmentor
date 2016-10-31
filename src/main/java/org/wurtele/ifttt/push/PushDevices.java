/*
 * Copyright (C) 2016 Douglas Wurtele
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */
package org.wurtele.ifttt.push;

import java.io.InputStream;
import java.io.ObjectInputStream;
import java.io.ObjectOutputStream;
import java.io.OutputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.HashSet;
import java.util.Set;
import org.jboss.logging.Logger;

/**
 *
 * @author Douglas Wurtele
 */
public class PushDevices {
	private static PushDevices instance;
	
	private final Logger logger = Logger.getLogger(getClass());
	private Set<String> devices;
	
	@SuppressWarnings("unchecked")
	private PushDevices() {
		super();
		try {
			if (Files.exists(getPath())) {
				try (InputStream is = Files.newInputStream(getPath());
						ObjectInputStream ois = new ObjectInputStream(is)) {
					this.devices = (Set<String>) ois.readObject();
				}
			}
		} catch (Exception e) {
			logger.warn("Failed to load notification devices", e);
		}
		if (devices == null)
			devices = new HashSet<>();
	}
	
	private void save() {
		try (OutputStream os = Files.newOutputStream(getPath());
				ObjectOutputStream oos = new ObjectOutputStream(os)) {
			oos.writeObject(devices);
		} catch (Exception e) {
			logger.warn("Failed to save notification devices", e);
		}
	}
	
	private Path getPath() {
		return Paths.get(System.getProperty("jboss.server.config.dir"), "ifttt-devices.data");
	}
	
	private static PushDevices instance() {
		if (instance == null)
			instance = new PushDevices();
		return instance;
	}
	
	public static Set<String> getDevices() {
		return instance().devices;
	}
	
	public static void addDevice(String device) {
		instance().devices.add(device);
		instance().save();
	}
}
