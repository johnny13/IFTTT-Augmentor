package org.wurtele.ifttt.watchers.base;

import java.io.IOException;
import java.nio.file.Path;

/**
 *
 * @author Douglas Wurtele
 */
public abstract class SimpleFileWatcher extends SimpleDirectoryWatcher {
	private final Path watchFile;
	
	public SimpleFileWatcher(Path watchFile) throws IOException {
		super(watchFile.getParent());
		this.watchFile = watchFile;
	}

	@Override
	public void handleCreate(Path path) {
		if (path.equals(this.watchFile))
			this.handleFileCreate(path);
	}

	@Override
	public void handleDelete(Path path) {
		if (path.equals(this.watchFile))
			this.handleFileDelete(path);
	}

	@Override
	public void handleModify(Path path) {
		if (path.equals(this.watchFile))
			this.handleFileModify(path);
	}
	
	public abstract void handleFileCreate(Path path);
	public abstract void handleFileDelete(Path path);
	public abstract void handleFileModify(Path path);
}
