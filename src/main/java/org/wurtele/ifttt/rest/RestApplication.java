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
package org.wurtele.ifttt.rest;

import java.util.Set;
import javax.ws.rs.ApplicationPath;
import javax.ws.rs.Path;
import javax.ws.rs.core.Application;
import org.reflections.Reflections;

/**
 *
 * @author Douglas Wurtele
 */
@ApplicationPath("api")
public class RestApplication extends Application {

	@Override
	public Set<Class<?>> getClasses() {
		Reflections ref = new Reflections("org.wurtele.ifttt.rest.services");
		return ref.getTypesAnnotatedWith(Path.class);
	}
	
}
