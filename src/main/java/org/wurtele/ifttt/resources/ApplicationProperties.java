package org.wurtele.ifttt.resources;

import java.net.URL;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.Properties;
import org.jboss.logging.Logger;

/**
 *
 * @author Douglas Wurtele
 */
public class ApplicationProperties extends Properties {
	public static final String PROPERTIES_FILE_NAME = "ifttt.properties";
	private static ApplicationProperties instance = null;
	
	private ApplicationProperties() {
		try {
			Path path = Paths.get(System.getProperty("jboss.server.config.dir"), PROPERTIES_FILE_NAME);
			if (Files.exists(path)) {
				this.load(Files.newInputStream(path));
			} else {
				URL url = Thread.currentThread().getContextClassLoader().getResource(PROPERTIES_FILE_NAME);
				this.load(url.openStream());
			}
		} catch (Exception e) {
			Logger.getLogger(getClass()).fatal("Failed to load application properties", e);
		}
	}
	
	private static ApplicationProperties getInstance() {
		if (instance == null)
			instance = new ApplicationProperties();
		return instance;
	}
	
	public static void reload() {
		instance = null;
		getInstance();
	}
	
	public static Path getDropboxPath() {
		return Paths.get(getInstance().getProperty("DROPBOX.DIR"));
	}
	
	public static Path getWorkTimesFile() {
		return getDropboxPath().resolve("iOS Location").resolve("work_times.csv.txt");
	}
	
	public static Path getGmailDirectory() {
		return getDropboxPath().resolve("Gmail");
	}
	
	public static Path getLaundryFile() {
		return getDropboxPath().resolve("Laundry").resolve("LG Smart Washer-complete.txt");
	}
}
