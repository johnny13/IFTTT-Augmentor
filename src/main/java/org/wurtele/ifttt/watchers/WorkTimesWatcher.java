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
import java.io.OutputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardOpenOption;
import java.text.DateFormat;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Calendar;
import java.util.Collections;
import java.util.Date;
import java.util.List;
import org.apache.commons.lang3.time.DateUtils;
import org.apache.poi.ss.usermodel.CellStyle;
import org.apache.poi.ss.usermodel.CreationHelper;
import org.apache.poi.ss.usermodel.Font;
import org.apache.poi.ss.usermodel.Row;
import org.apache.poi.ss.usermodel.Sheet;
import org.apache.poi.ss.usermodel.Workbook;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;
import org.wurtele.ifttt.model.WorkDay;
import org.wurtele.ifttt.model.WorkTime;
import org.wurtele.ifttt.model.enums.LocationType;
import org.wurtele.ifttt.watchers.base.SimpleFileWatcher;

/**
 *
 * @author Douglas Wurtele
 */
public class WorkTimesWatcher extends SimpleFileWatcher {
    private static final String OUTPUT_FILENAME = "work_times.xlsx";
    private final Path output;
    
    public WorkTimesWatcher(Path path) throws IOException {
		super(path);
		this.output = path.resolveSibling(OUTPUT_FILENAME);
    }
    
    @Override
    public void handleFileCreate(Path path) {
		processFile(path);
    }
    
    @Override
    public void handleFileDelete(Path path) {
		try {
			if (Files.exists(output))
			Files.delete(output);
		} catch (Exception e) {
			logger.error("Failed to remove " + OUTPUT_FILENAME, e);
		}
    }
    
    @Override
    public void handleFileModify(Path path) {
		processFile(path);
    }
    
    private void processFile(Path input) {
		logger.info("Updating " + output);
		
		try (Workbook wb = new XSSFWorkbook(); OutputStream out = Files.newOutputStream(output, StandardOpenOption.CREATE, StandardOpenOption.TRUNCATE_EXISTING)) {
			Sheet sheet = wb.createSheet("Time Sheet");
			List<WorkDay> days = new ArrayList<>();
			DateFormat df = new SimpleDateFormat("MMMM dd, yyyy 'at' hh:mma");
			for (String line : Files.readAllLines(input)) {
				String[] data = line.split(";");
				LocationType type = LocationType.valueOf(data[0].toUpperCase());
				Date time = df.parse(data[1]);
				Date day = DateUtils.truncate(time, Calendar.DATE);
				WorkDay wd = new WorkDay(day);
				if (days.contains(wd))
					wd = days.get(days.indexOf(wd));
				else
					days.add(wd);
				wd.getTimes().add(new WorkTime(time, type));
			}
			
			CreationHelper helper = wb.getCreationHelper();
			Font bold = wb.createFont();
			bold.setBoldweight(Font.BOLDWEIGHT_BOLD);
			
			CellStyle dateStyle = wb.createCellStyle();
			dateStyle.setDataFormat(helper.createDataFormat().getFormat("MMMM d, yyyy"));
			CellStyle timeStyle = wb.createCellStyle();
			timeStyle.setDataFormat(helper.createDataFormat().getFormat("h:mm AM/PM"));
			CellStyle headerStyle = wb.createCellStyle();
			headerStyle.setAlignment(CellStyle.ALIGN_CENTER);
			headerStyle.setFont(bold);
			CellStyle totalStyle = wb.createCellStyle();
			totalStyle.setAlignment(CellStyle.ALIGN_RIGHT);
			
			Row header = sheet.createRow(0);
			header.createCell(0).setCellValue("DATE");
			header.getCell(0).setCellStyle(headerStyle);
			
			Collections.sort(days);
			for (int r = 0; r < days.size(); r++) {
				WorkDay day = days.get(r);
				Row row = sheet.createRow(r + 1);
				row.createCell(0).setCellValue(day.getDate());
				row.getCell(0).setCellStyle(dateStyle);
				Collections.sort(day.getTimes());
				for (int c = 0; c < day.getTimes().size(); c++) {
					WorkTime time = day.getTimes().get(c);
					if (sheet.getRow(0).getCell(c + 1) != null && !sheet.getRow(0).getCell(c + 1).getStringCellValue().equals(time.getType().name())) {
						throw new Exception("Invalid data");
					} else if (sheet.getRow(0).getCell(c + 1) == null) {
						sheet.getRow(0).createCell(c + 1).setCellValue(time.getType().name());
						sheet.getRow(0).getCell(c + 1).setCellStyle(headerStyle);
					}
					row.createCell(c + 1).setCellValue(time.getTime());
					row.getCell(c + 1).setCellStyle(timeStyle);
				}
			}
			
			int totalCol = header.getLastCellNum();
			header.createCell(totalCol).setCellValue("TOTAL");
			header.getCell(totalCol).setCellStyle(headerStyle);
			
			for (int r = 0; r < days.size(); r++) {
				sheet.getRow(r + 1).createCell(totalCol).setCellValue(days.get(r).getTotal());
				sheet.getRow(r + 1).getCell(totalCol).setCellStyle(totalStyle);
			}
			
			for (int c = 0; c <= totalCol; c++) {
				sheet.autoSizeColumn(c);
			}
			
			wb.write(out);
		} catch (Exception e) {
			logger.error("Failed to update " + output, e);
		}
    }
}
