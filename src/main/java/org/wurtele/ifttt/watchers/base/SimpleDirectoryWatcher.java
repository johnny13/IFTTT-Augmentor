package org.wurtele.ifttt.watchers.base;

import java.io.IOException;
import java.nio.file.Path;
import org.jboss.logging.Logger;

/**
 *
 * @author Douglas Wurtele
 */
public abstract class SimpleDirectoryWatcher implements AutoCloseable {
	protected final Logger logger = Logger.getLogger(getClass());
	
	private final Path watchDirectory;
	private DirectoryWatcher watcher;
	private WatchRunner runner;
	private Thread watchThread;
	
	public SimpleDirectoryWatcher(Path watchDirectory) throws IOException {
	    super();
	    this.watchDirectory = watchDirectory;
	    try {
		this.watcher = new DirectoryWatcher(watchDirectory, this,
			this.getClass().getMethod("handleCreate", Path.class),
			this.getClass().getMethod("handleDelete", Path.class),
			this.getClass().getMethod("handleModify", Path.class));
		this.runner = new WatchRunner(watcher);
		this.watchThread = new Thread(this.runner);
	    } catch (NoSuchMethodException e) {
		Logger.getLogger(getClass()).error("Failed to load callback methods", e);
	    }
	}
	
	public void watch() {
		this.watchThread.start();
	}

	@Override
	public void close() throws Exception {
		this.runner.stop();
	}
	
	public abstract void handleCreate(Path path);
	public abstract void handleDelete(Path path);
	public abstract void handleModify(Path path);
	
}
