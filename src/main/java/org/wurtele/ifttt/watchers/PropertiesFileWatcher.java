package org.wurtele.ifttt.watchers;

import org.wurtele.ifttt.watchers.base.SimpleFileWatcher;
import java.io.IOException;
import java.nio.file.Path;
import org.jboss.logging.Logger;
import org.wurtele.ifttt.resources.ApplicationProperties;

/**
 *
 * @author Douglas Wurtele
 */
public class PropertiesFileWatcher extends SimpleFileWatcher {

	public PropertiesFileWatcher(Path watchFile) throws IOException {
		super(watchFile);
	}

	@Override
	public void handleFileCreate(Path path) { }

	@Override
	public void handleFileDelete(Path path) { }

	@Override
	public void handleFileModify(Path path) {
		Logger.getLogger(getClass()).info("Properties file changed");
		ApplicationProperties.reload();
	}
	
}
