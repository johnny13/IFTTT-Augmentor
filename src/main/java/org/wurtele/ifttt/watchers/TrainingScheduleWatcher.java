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

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardOpenOption;
import java.nio.file.attribute.BasicFileAttributes;
import java.text.DateFormat;
import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import org.apache.commons.io.FilenameUtils;
import org.apache.poi.xwpf.extractor.XWPFWordExtractor;
import org.apache.poi.xwpf.usermodel.XWPFDocument;
import org.json.JSONArray;
import org.wurtele.ifttt.model.TrainingScheduleEntry;
import org.wurtele.ifttt.watchers.base.SimpleDirectoryWatcher;

/**
 *
 * @author Douglas Wurtele
 */
public class TrainingScheduleWatcher extends SimpleDirectoryWatcher {

	public TrainingScheduleWatcher(Path watchDirectory) throws IOException {
		super(watchDirectory);
	}

	@Override
	public void handleCreate(Path path) {
		if (isArmySender(path) && !isProcessed(path)) {
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
	}

	@Override
	public void handleDelete(Path path) {
		try {
			if (Files.exists(processedPath(path)))
				Files.delete(processedPath(path));
		} catch (IOException e) {
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
		} catch (IOException e) {
			return false;
		}
	}
	
	private Path processedPath(Path path) {
		return path.resolveSibling(FilenameUtils.getBaseName(path.getFileName().toString()).concat(".json"));
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
				} catch (ParseException pe) { }
				if (line.startsWith("\t"))
					data.get(data.size() - 1).addAll(Arrays.asList(line.substring(1).split("\t")));
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
			JSONArray events = new JSONArray(entries);
			Files.write(processedPath(path), events.toString().getBytes(), StandardOpenOption.CREATE, StandardOpenOption.TRUNCATE_EXISTING);
			logger.info("Processed " + path);
		} catch (Exception e) {
			logger.error("Failed to process training schedule file: " + path, e);
		}
	}
	
	private void processPDF(Path path) {
		logger.error("PDF processing not implemented yet");
	}
}
