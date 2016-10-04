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

import java.util.Date;
import java.util.Objects;
import org.wurtele.ifttt.model.enums.LocationType;

/**
 *
 * @author Douglas Wurtele
 */
public class WorkTime implements Comparable<WorkTime> {
	private final Date time;
	private final LocationType type;
	
	public WorkTime(Date time, LocationType type) {
		super();
		this.time = time;
		this.type = type;
	}

	public Date getTime() {
		return time;
	}

	public LocationType getType() {
		return type;
	}

	@Override
	public int hashCode() {
		int hash = 7;
		hash = 79 * hash + Objects.hashCode(this.time);
		hash = 79 * hash + Objects.hashCode(this.type);
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
		final WorkTime other = (WorkTime) obj;
		if (!Objects.equals(this.time, other.time)) {
			return false;
		}
		return this.type == other.type;
	}

	@Override
	public int compareTo(WorkTime o) {
		return this.getTime().compareTo(o.getTime());
	}
}
