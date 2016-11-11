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
import java.nio.file.Files;
import java.nio.file.Path;
import java.text.DateFormat;
import java.text.SimpleDateFormat;
import java.util.Date;
import org.wurtele.ifttt.push.PushDevices;
import org.wurtele.ifttt.push.PushUtils;
import org.wurtele.ifttt.watchers.base.SimpleFileWatcher;

/**
 *
 * @author Douglas Wurtele
 */
public class LaundryWatcher extends SimpleFileWatcher {
	
	public LaundryWatcher(Path watchFile) throws IOException {
		super(watchFile);
	}

	@Override
	public void handleFileCreate(Path path) {
		try {
			
			DateFormat df = new SimpleDateFormat("MM/dd/yyyy HH:mm:ss");
			String payload = APNS.newPayload()
					.category("laundryCategory")
					.alertTitle("Change the Laundry")
					.alertBody("The washing machine finished at " + df.format(new Date()))
					.sound("default")
					.build();
			PushDevices.getDevices().stream().forEach((device) -> {
				PushUtils.getService().push(device, payload);
			});
			Files.delete(path);
		} catch (Exception e) {
			logger.error("Failed to handle new laundry file: " + path, e);
		}
	}

	@Override
	public void handleFileDelete(Path path) { }

	@Override
	public void handleFileModify(Path path) { }
}
