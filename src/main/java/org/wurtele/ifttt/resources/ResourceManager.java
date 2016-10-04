package org.wurtele.ifttt.resources;

import org.wurtele.ifttt.watchers.PropertiesFileWatcher;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.List;
import javax.annotation.PostConstruct;
import javax.annotation.PreDestroy;
import javax.ejb.Singleton;
import javax.ejb.Startup;
import org.jboss.logging.Logger;
import org.wurtele.ifttt.watchers.WorkTimesWatcher;
import org.wurtele.ifttt.watchers.base.SimpleDirectoryWatcher;

/**
 *
 * @author Douglas Wurtele
 */
@Startup
@Singleton
public class ResourceManager {
	private final Logger logger = Logger.getLogger(getClass());
	private final List<SimpleDirectoryWatcher> watchers = new ArrayList<>();
	
	@PostConstruct
	public void init() {
		Path props = Paths.get(System.getProperty("jboss.server.config.dir"), ApplicationProperties.PROPERTIES_FILE_NAME);
		if (Files.exists(props)) {
			try {
				PropertiesFileWatcher propsWatcher = new PropertiesFileWatcher(props);
				propsWatcher.watch();
				watchers.add(propsWatcher);
			} catch (Exception e) {
				logger.error("Failed to create properties file watcher");
			}
		}
		try {
			WorkTimesWatcher wtWatcher = new WorkTimesWatcher(ApplicationProperties.getWorkTimesFile());
			wtWatcher.watch();
			watchers.add(wtWatcher);
		} catch (Exception e) {
			logger.error("Failed to create work times files watcher");
		}
	}
	
	@PreDestroy
	public void destroy() {
	    watchers.stream().forEach((watcher) -> {
			try {
				watcher.close();
			} catch (Exception e) {
				logger.error("Failed to close watcher", e);
			}
		});
	}
}
