package org.wurtele.ifttt.watchers.base;

/**
 *
 * @author Douglas Wurtele
 */
public class WatchRunner implements Runnable {
	private final DirectoryWatcher watcher;
	
	public WatchRunner(DirectoryWatcher watcher) {
		super();
		this.watcher = watcher;
	}
	
	@Override
	public void run() {
		this.watcher.watch();
	}
	
	public void stop() {
		this.watcher.destroy();
	}
}
