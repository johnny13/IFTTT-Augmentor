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
package org.wurtele.ifttt.model;

import java.text.DecimalFormat;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Date;
import java.util.List;
import java.util.Objects;
import org.wurtele.ifttt.model.enums.LocationType;

/**
 *
 * @author Douglas Wurtele
 */
public class WorkDay implements Comparable<WorkDay> {
	private final Date date;
	private final List<WorkTime> times;
	
	public WorkDay(Date date) {
		super();
		this.date = date;
		this.times = new ArrayList<>();
	}

	public Date getDate() {
		return date;
	}

	public List<WorkTime> getTimes() {
		return times;
	}
	
	public String getTotal() {
		if (times.size() % 2 == 0) {
			Collections.sort(times);
			long diff = 0;
			for (int i = 0; i < times.size(); i += 2) {
				WorkTime arr = times.get(i);
				WorkTime dep = times.get(i + 1);
				if (arr.getType() == LocationType.ARRIVED && dep.getType() == LocationType.DEPARTED) {
					diff += dep.getTime().getTime() - arr.getTime().getTime();
				}
			}
			
			long totalMinutes = diff / 60 / 1000;
			long minutes = totalMinutes % 60;
			long hours = (totalMinutes - minutes) / 60;
			
			DecimalFormat df = new DecimalFormat();
			df.setMinimumIntegerDigits(2);
			df.setMaximumIntegerDigits(2);
			
			return hours + ":" + df.format(minutes);
		}
		return null;
	}

	@Override
	public int hashCode() {
		int hash = 3;
		hash = 37 * hash + Objects.hashCode(this.date);
		return hash;
	}

	@Override
	public boolean equals(Object obj) {
		if (this == obj) {
			return true;
		}
		if (obj == null) {
			return false;
		}
		if (getClass() != obj.getClass()) {
			return false;
		}
		final WorkDay other = (WorkDay) obj;
		return Objects.equals(this.date, other.date);
	}

	@Override
	public int compareTo(WorkDay o) {
		return this.getDate().compareTo(o.getDate());
	}
}
