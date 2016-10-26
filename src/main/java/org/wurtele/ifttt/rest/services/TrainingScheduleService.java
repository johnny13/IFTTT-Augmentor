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
package org.wurtele.ifttt.rest.services;

import java.util.ArrayList;
import java.util.Calendar;
import java.util.Collections;
import java.util.Date;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import javax.ws.rs.GET;
import javax.ws.rs.Path;
import javax.ws.rs.PathParam;
import javax.ws.rs.Produces;
import javax.ws.rs.core.MediaType;
import javax.ws.rs.core.Response;
import javax.ws.rs.core.Response.Status;
import org.apache.commons.io.FilenameUtils;
import org.apache.commons.lang3.time.DateUtils;
import org.jboss.logging.Logger;
import org.wurtele.ifttt.model.TrainingScheduleEntry;
import org.wurtele.ifttt.resources.ApplicationProperties;
import org.wurtele.ifttt.watchers.TrainingScheduleWatcher;

/**
 *
 * @author Douglas Wurtele
 */
@Path("schedules")
public class TrainingScheduleService {
	private final Logger logger = Logger.getLogger(getClass());
	
	@GET
	@Produces(MediaType.APPLICATION_JSON)
	public Response list() {
		try {
			List<Map<String, Object>> list = new ArrayList<>();
			TrainingScheduleWatcher.getTrainingSchedules().entrySet().stream().parallel().forEach((schedule) -> {
				Map<String, Object> map = new HashMap<>();
				map.put("sender", schedule.getKey().getParent().getFileName().toString().toLowerCase());
				map.put("file", FilenameUtils.getBaseName(schedule.getKey().getFileName().toString()));
				Dates dates = new Dates();
				schedule.getValue().forEach((item) -> {
					dates.checkStart(item.getStart());
					dates.checkEnd(item.getEnd());
				});
				map.put("start", dates.getStart());
				map.put("end", dates.getEnd());
				list.add(map);
			});
			return Response.ok(list).build();
		} catch (Exception e) {
			logger.error("Failed to list training schedules", e);
			return Response.serverError().build();
		}
	}
	
	@GET
	@Path("{sender}/{file}")
	@Produces(MediaType.APPLICATION_JSON)
	public Response get(
			@PathParam("sender") String sender,
			@PathParam("file") String file
	) {
		try {
			java.nio.file.Path path = ApplicationProperties.getGmailDirectory().resolve(sender).resolve(file + ".data");
			List<TrainingScheduleEntry> data = TrainingScheduleWatcher.getTrainingSchedules().get(path);
			if (data != null) {
				Collections.sort(data);
				return Response.ok(data).build();
			} else {
				return Response.status(Status.NOT_FOUND).build();
			}
		} catch (Exception e) {
			logger.error("Failed to get training schedule", e);
			return Response.serverError().build();
		}
	}
	
	private static class Dates {
		private Date start, end;
		
		public Dates() {
			super();
			start = null;
			end = null;
		}
		
		public void checkStart(Date start) {
			if (this.start == null || this.start.after(start))
				this.start = start;
		}
		
		public void checkEnd(Date end) {
			if (this.end == null || this.end.before(end))
				this.end = end;
		}
		
		public Date getStart() {
			return DateUtils.truncate(start, Calendar.DATE);
		}
		
		public Date getEnd() {
			return DateUtils.truncate(end, Calendar.DATE);
		}
	}
}
