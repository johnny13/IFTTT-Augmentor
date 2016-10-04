package org.wurtele.ifttt.watchers.base;

import java.io.IOException;
import java.lang.reflect.Method;
import java.nio.file.ClosedWatchServiceException;
import java.nio.file.FileSystems;
import java.nio.file.FileVisitOption;
import java.nio.file.FileVisitResult;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.SimpleFileVisitor;
import static java.nio.file.StandardWatchEventKinds.ENTRY_CREATE;
import static java.nio.file.StandardWatchEventKinds.ENTRY_DELETE;
import static java.nio.file.StandardWatchEventKinds.ENTRY_MODIFY;
import static java.nio.file.StandardWatchEventKinds.OVERFLOW;
import java.nio.file.WatchEvent;
import java.nio.file.WatchEvent.Kind;
import java.nio.file.WatchKey;
import java.nio.file.WatchService;
import java.nio.file.attribute.BasicFileAttributes;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import org.jboss.logging.Logger;

/**
 *
 * @author Douglas Wurtele
 */
public class DirectoryWatcher {
	private final Logger logger = Logger.getLogger(getClass());
	private final WatchService watcher;
	private final Map<WatchKey, Path> keys;
	private final Path directory;
	private final Object callbackObject;
	private final Method createCallback, deleteCallback, modifyCallback;
	private boolean running = true;
	
	public DirectoryWatcher(Path directory, Object callbackObject, Method createCallback, Method deleteCallback, Method modifyCallback) throws IOException {
		super();
		if (directory == null) throw new NullPointerException("directory cannot be null");
		if (callbackObject == null) throw new NullPointerException("callbackObject cannot be null");
		if (createCallback != null && (createCallback.getParameterCount() != 1 || createCallback.getParameterTypes()[0] != Path.class))
			throw new IllegalArgumentException("Invalid create callback method");
		if (deleteCallback != null && (deleteCallback.getParameterCount() != 1 || deleteCallback.getParameterTypes()[0] != Path.class))
			throw new IllegalArgumentException("Invalid delete callback method");
		if (modifyCallback != null && (modifyCallback.getParameterCount() != 1 || modifyCallback.getParameterTypes()[0] != Path.class))
			throw new IllegalArgumentException("Invalid modify callback method");
		if (createCallback == null && deleteCallback == null && modifyCallback == null)
			throw new IllegalArgumentException("Must have at least one callback");
		this.watcher = FileSystems.getDefault().newWatchService();
		this.keys = new HashMap<>();
		this.directory = directory;
		this.callbackObject = callbackObject;
		this.createCallback = createCallback;
		this.deleteCallback = deleteCallback;
		this.modifyCallback = modifyCallback;
		this.register();
	}
	
	private void register() throws IOException {
		final Kind<?>[] kinds = getKinds();
		Files.walkFileTree(this.directory, Collections.singleton(FileVisitOption.FOLLOW_LINKS), Integer.MAX_VALUE, new SimpleFileVisitor<Path>() {
			@Override
			public FileVisitResult preVisitDirectory(Path dir, BasicFileAttributes attrs) throws IOException {
				keys.put(dir.register(watcher, kinds), dir);
				return FileVisitResult.CONTINUE;
			}
		});
	}
	
	public void watch() {
		try {
			Files.walkFileTree(this.directory, Collections.singleton(FileVisitOption.FOLLOW_LINKS), Integer.MAX_VALUE, new SimpleFileVisitor<Path>() {
				@Override
				public FileVisitResult visitFile(Path file, BasicFileAttributes attrs) throws IOException {
					try {
						createCallback.invoke(callbackObject, file);
					} catch (Exception e) {
						logger.error("Failed to execute create callback for " + file, e);
					}
					return FileVisitResult.CONTINUE;
				}
			});
		} catch (IOException e) {
			logger.error("Failed to scan " + this.directory, e);
		}
		
		do {
			WatchKey key;
			try {
				key = watcher.take();
			} catch (InterruptedException e) {
				this.destroy();
				return;
			} catch (ClosedWatchServiceException e) {
				return;
			}
			
			Path dir = keys.get(key);
			if (dir == null) continue;
			
			for (WatchEvent<?> event : key.pollEvents()) {
				if (event.kind() == OVERFLOW) continue;
				WatchEvent<Path> we = cast(event);
				Path file = dir.resolve(we.context());
				
				if (!Files.isDirectory(file)) {
					if (event.kind() == ENTRY_CREATE || event.kind() == ENTRY_MODIFY) {
						try {
							long size = 0L;
							do {
								size = Files.size(file);
								Thread.sleep(500L);
							} while (Files.exists(file) && Files.size(file) > size);
						} catch (Exception e) { }
					}
					try {
						if (event.kind() == ENTRY_CREATE) {
							createCallback.invoke(callbackObject, file);
						} else if (event.kind() == ENTRY_DELETE) {
							deleteCallback.invoke(callbackObject, file);
						} else if (event.kind() == ENTRY_MODIFY) {
							modifyCallback.invoke(callbackObject, file);
						}
					} catch (Exception e) {
						logger.error("Failed to handle file event", e);
					}
				} else {
					if (event.kind() == ENTRY_CREATE) {
						try {
							keys.put(file.register(watcher, getKinds()), file);
						} catch (IOException e) {
							logger.error("Failed to register new sub-directory: " + file, e);
						}
					} else if (event.kind() == ENTRY_DELETE) {
						WatchKey existing = null;
						for (Map.Entry<WatchKey, Path> entry : keys.entrySet()) {
							if (entry.getValue().equals(file)) {
								existing = entry.getKey();
								break;
							}
						}
						if (existing != null) {
							existing.cancel();
							keys.remove(existing);
						}
					}
				}
			}
			if (!key.reset()) {
				keys.remove(key);
				if (keys.isEmpty()) break;
			}
		} while (running);
	}
	
	public void destroy() {
		try {
			this.keys.keySet().stream().forEach((key) -> {
				key.cancel();
			});
			this.watcher.close();
			this.keys.clear();
			this.running = false;
		} catch (IOException e) {
			logger.error("Failed to destroy watcher", e);
		}
	}
	
	private Kind<?>[] getKinds() {
		List<Kind<?>> kindList = new ArrayList<>();
		if (this.createCallback != null)
			kindList.add(ENTRY_CREATE);
		if (this.deleteCallback != null)
			kindList.add(ENTRY_DELETE);
		if (this.modifyCallback != null)
			kindList.add(ENTRY_MODIFY);
		
		return kindList.toArray(new Kind<?>[0]);
	}
	
	@SuppressWarnings("unchecked")
	private static <T> WatchEvent<T> cast(WatchEvent<?> event) {
		return (WatchEvent<T>) event;
	}
}
