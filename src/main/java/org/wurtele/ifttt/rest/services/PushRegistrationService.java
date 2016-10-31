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

import com.notnoop.apns.APNS;
import com.notnoop.apns.ApnsService;
import java.net.URL;
import javax.ws.rs.GET;
import javax.ws.rs.Path;
import javax.ws.rs.Produces;
import javax.ws.rs.QueryParam;
import javax.ws.rs.core.MediaType;
import javax.ws.rs.core.Response;
import org.jboss.logging.Logger;
import org.wurtele.ifttt.push.PushDevices;

/**
 *
 * @author Douglas Wurtele
 */
@Path("register")
public class PushRegistrationService {
	private final Logger logger = Logger.getLogger(getClass());
	
	@GET
	@Produces(MediaType.APPLICATION_JSON)
	public Response register(
			@QueryParam("token") String token
	) {
		try {
			PushDevices.addDevice(token);
			logger.info("Registered " + token + " for push notifications");
			return Response.ok().build();
		} catch (Exception e) {
			logger.error("Failed to register for push notifications", e);
			return Response.serverError().build();
		}
	}
	
	@GET
	@Path("test")
	@Produces(MediaType.APPLICATION_JSON)
	public Response pushTest() {
		try {
			URL url = Thread.currentThread().getContextClassLoader().getResource("IFTTT.p12");
			ApnsService service = APNS.newService()
					.withCert(url.openStream(), "ifTTT")
					.withSandboxDestination()
					.build();
			String payload = APNS.newPayload()
					.category("scheduleCategory")
					.alertBody("This is a test notification")
					.alertTitle("Test Alert")
					.sound("default")
					.customField("schedule", "michaelsmitchell34mil@mailmil/TS_5-6_NOV_2016")
					.build();
			PushDevices.getDevices().stream().forEach((device) -> {
				service.push(device, payload);
			});
			logger.info("Sent: " + payload);
			return Response.ok().build();
		} catch (Exception e) {
			logger.error("Failed to send push notification", e);
			return Response.serverError().build();
		}
	}
}
