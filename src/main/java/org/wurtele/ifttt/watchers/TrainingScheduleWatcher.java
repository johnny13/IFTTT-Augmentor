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
package org.wurtele.ifttt.watchers;

import com.notnoop.apns.APNS;
import java.io.IOException;
import java.io.InputStream;
import java.io.ObjectInputStream;
import java.io.ObjectOutputStream;
import java.io.OutputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.attribute.BasicFileAttributes;
import java.text.DateFormat;
import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Calendar;
import java.util.Collections;
import java.util.Date;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import org.apache.commons.io.FilenameUtils;
import org.apache.commons.lang3.time.DateUtils;
import org.apache.poi.xwpf.extractor.XWPFWordExtractor;
import org.apache.poi.xwpf.usermodel.XWPFDocument;
import org.wurtele.ifttt.model.TrainingScheduleEntry;
import org.wurtele.ifttt.push.PushDevices;
import org.wurtele.ifttt.push.PushUtils;
import org.wurtele.ifttt.watchers.base.SimpleDirectoryWatcher;

/**
 *
 * @author Douglas Wurtele
 */
public class TrainingScheduleWatcher extends SimpleDirectoryWatcher {

	private static final Map<Path, List<TrainingScheduleEntry>> TRAINING_SCHEDULES = new HashMap<>();
	private static final Set<Path> FAILED = new HashSet<>();

	public TrainingScheduleWatcher(Path watchDirectory) throws IOException {
		super(watchDirectory);
	}

	@Override
	public void handleCreate(Path path) {
		if (isArmySender(path)) {
			if (!isProcessed(path)) {
				switch (FilenameUtils.getExtension(path.getFileName().toString().toLowerCase())) {
					case "docm":
						processWordFile(path);
						break;
					case "pdf":
						processPDF(path);
						break;
					default:
						break;
				}
			}
			addProcessed(path);
		}
	}

	@Override
	public void handleDelete(Path path) {
		try {
			if (Files.exists(processedPath(path)) && !path.equals(processedPath(path))) {
				Files.delete(processedPath(path));
				TRAINING_SCHEDULES.remove(processedPath(path));
			}
		}
		catch (IOException e) {
			logger.error("Failed to remove old training schedule data: " + processedPath(path), e);
		}
	}

	@Override
	public void handleModify(Path path) {
		this.handleDelete(path);
		this.handleCreate(path);
	}

	private boolean isArmySender(Path path) {
		return path.getParent().getFileName().toString().toLowerCase().matches(".*@mail.mil");
	}

	private boolean isProcessed(Path path) {
		try {
			return Files.exists(processedPath(path)) && Files.readAttributes(processedPath(path), BasicFileAttributes.class).size() > 0;
		}
		catch (IOException e) {
			return false;
		}
	}

	private Path processedPath(Path path) {
		return path.resolveSibling(FilenameUtils.getBaseName(path.getFileName().toString()).concat(".data"));
	}

	@SuppressWarnings("unchecked")
	private void addProcessed(Path path) {
		if (isProcessed(path)) {
			try (InputStream is = Files.newInputStream(processedPath(path));
					ObjectInputStream ois = new ObjectInputStream(is)) {
				List<TrainingScheduleEntry> data = (List<TrainingScheduleEntry>) ois.readObject();
				TRAINING_SCHEDULES.put(processedPath(path), data);
				FAILED.remove(path);
			}
			catch (Exception e) {
				if (!FAILED.contains(path)) {
					logger.error("Failed to read processed file: " + path, e);
					FAILED.add(path);
					this.handleDelete(path);
					this.handleCreate(path);
				} else {
					logger.error("Failed to read processed file on second attempt: " + path, e);
				}
			}
		}
	}

	private void processWordFile(Path path) {
		try {
			XWPFDocument doc = new XWPFDocument(Files.newInputStream(path));
			XWPFWordExtractor extractor = new XWPFWordExtractor(doc);
			List<List<String>> data = new ArrayList<>();
			DateFormat df1 = new SimpleDateFormat("MMM dd, yyyy");
			DateFormat df2 = new SimpleDateFormat("MMM dd, yyyy HH:mm");
			Arrays.asList(extractor.getText().split("\n")).stream().forEach((line) -> {
				try {
					df1.parse(line.split("\t")[0]);
					List<String> list = new ArrayList<>();
					list.addAll(Arrays.asList(line.split("\t")));
					data.add(list);
				}
				catch (ParseException pe) {
				}
				if (line.startsWith("\t")) {
					data.get(data.size() - 1).addAll(Arrays.asList(line.substring(1).split("\t")));
				}
			});
			List<TrainingScheduleEntry> entries = new ArrayList<>();
			for (List<String> event : data) {
				TrainingScheduleEntry entry = new TrainingScheduleEntry();
				entry.setStart(df2.parse(event.get(0) + " " + event.get(1)));
				entry.setEnd(df2.parse(event.get(0) + " " + event.get(2)));
				entry.setGroup(event.get(4));
				entry.setTitle(event.get(5));
				entry.setNotes(event.get(6).length() > 6 ? event.get(6).substring(6) : event.get(6));
				if (event.size() > 13) {
					for (int i = 7; i < 7 + event.size() - 13; i++) {
						entry.setNotes(entry.getNotes() + " " + event.get(i));
					}
				}
				entry.setInstructor(event.get(event.size() - 6).trim());
				entry.setUniform(event.get(event.size() - 5));
				entry.setLocation(event.get(event.size() - 2));
				entries.add(entry);
			}

			if (!entries.isEmpty()) {
				Collections.sort(entries);

				try (OutputStream os = Files.newOutputStream(processedPath(path));
						ObjectOutputStream oos = new ObjectOutputStream(os)) {
					oos.writeObject(entries);
				}
				logger.info("Processed " + path);
				Date start = DateUtils.truncate(entries.get(0).getStart(), Calendar.DATE);
				Date end = DateUtils.truncate(entries.get(entries.size() - 1).getEnd(), Calendar.DATE);
				DateFormat df = new SimpleDateFormat("MMM d, yyyy");
				String payload = APNS.newPayload()
						.category("scheduleCategory")
						.alertTitle("Training Schedule Received")
						.alertBody(entries.size() + " events found for " + (start.before(end) ? df.format(start) + " - " + df.format(end) : df.format(start)))
						.sound("default")
						.customField("schedule", path.getParent().getFileName().toString() + "/" + FilenameUtils.getBaseName(path.getFileName().toString()))
						.build();
				PushDevices.getDevices().stream().forEach((device) -> {
					PushUtils.getService().push(device, payload);
				});
			}
		}
		catch (Exception e) {
			logger.error("Failed to process training schedule file: " + path, e);
			FAILED.add(path);
		}
	}

	private void processPDF(Path path) {
		logger.error("PDF processing not implemented yet");
	}

	public static Map<Path, List<TrainingScheduleEntry>> getTrainingSchedules() {
		return TRAINING_SCHEDULES;
	}
}
