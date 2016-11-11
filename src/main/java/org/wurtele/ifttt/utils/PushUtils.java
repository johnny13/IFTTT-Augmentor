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
package org.wurtele.ifttt.utils;

import com.notnoop.apns.APNS;
import com.notnoop.apns.ApnsService;

/**
 *
 * @author Douglas Wurtele
 */
public class PushUtils {
	private static PushUtils instance;
	
	private final ApnsService service;
	
	private PushUtils() {
		super();
		this.service = APNS.newService()
				.withCert(Thread.currentThread().getContextClassLoader().getResourceAsStream("IFTTT.p12"), "ifTTT")
				.withSandboxDestination()
				.build();
	}
	
	private static PushUtils getInstance() {
		if (instance == null)
			instance = new PushUtils();
		return instance;
	}
	
	public static ApnsService getService() {
		return getInstance().service;
	}
}
