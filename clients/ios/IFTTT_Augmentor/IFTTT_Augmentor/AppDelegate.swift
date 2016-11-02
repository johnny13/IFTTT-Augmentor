//
//  AppDelegate.swift
//  IFTTT_Augmentor
//
//  Created by Douglas Wurtele on 10/26/16.
//  Copyright © 2016 Douglas Wurtele. All rights reserved.
//

import UIKit
import CoreData
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {

	var window: UIWindow?


	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
		let notifications = UNUserNotificationCenter.current()
		let actions = [UNNotificationAction(identifier: "scheduleImport", title: "Import", options: []), UNNotificationAction(identifier: "scheduleView", title: "View", options: .foreground)]
		let category = UNNotificationCategory(identifier: "scheduleCategory", actions: actions, intentIdentifiers: [], options: [])
		notifications.setNotificationCategories([category])
		notifications.delegate = self
		notifications.requestAuthorization(options: [.badge, .alert, .sound], completionHandler: { granted, error in
			if let error = error {
				print("Failed to register for notifications: \(error)")
			}
		})
		application.registerForRemoteNotifications()
		
		return true
	}

	func applicationWillResignActive(_ application: UIApplication) {
		// Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
		// Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
	}

	func applicationDidEnterBackground(_ application: UIApplication) {
		// Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
		// If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
	}

	func applicationWillEnterForeground(_ application: UIApplication) {
		// Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
	}

	func applicationDidBecomeActive(_ application: UIApplication) {
		// Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
	}

	func applicationWillTerminate(_ application: UIApplication) {
		// Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
		// Saves changes in the application's managed object context before the application terminates.
		self.saveContext()
	}

	// MARK: - Core Data stack

	lazy var persistentContainer: NSPersistentContainer = {
	    /*
	     The persistent container for the application. This implementation
	     creates and returns a container, having loaded the store for the
	     application to it. This property is optional since there are legitimate
	     error conditions that could cause the creation of the store to fail.
	    */
	    let container = NSPersistentContainer(name: "persistence")
	    container.loadPersistentStores(completionHandler: { (storeDescription, error) in
	        if let error = error as NSError? {
	            // Replace this implementation with code to handle the error appropriately.
	            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
	             
	            /*
	             Typical reasons for an error here include:
	             * The parent directory does not exist, cannot be created, or disallows writing.
	             * The persistent store is not accessible, due to permissions or data protection when the device is locked.
	             * The device is out of space.
	             * The store could not be migrated to the current model version.
	             Check the error message to determine what the actual problem was.
	             */
	            fatalError("Unresolved error \(error), \(error.userInfo)")
	        }
	    })
	    return container
	}()

	// MARK: - Core Data Saving support

	func saveContext () {
	    let context = persistentContainer.viewContext
	    if context.hasChanges {
	        do {
	            try context.save()
	        } catch {
	            // Replace this implementation with code to handle the error appropriately.
	            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
	            let nserror = error as NSError
	            fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
	        }
	    }
	}
	
	var context: NSManagedObjectContext {
		get {
			return persistentContainer.viewContext
		}
	}
	
	// MARK: - Remote notifications
	
	func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
		let token = deviceToken.reduce("", {$0 + String(format: "%02X", $1)})
		print("Registered for remote notifications: \(token)")
	}
	
	func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
		print("Failed to register for remote notifications: \(error)")
	}
	
	func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
		if response.notification.request.content.categoryIdentifier == "scheduleCategory" {
			if let nav = self.window?.rootViewController as? RootNavigationViewController {
				if let main = nav.viewControllers[0] as? MainMenuViewController {
					main.showLoadingView()
					if let sched = response.notification.request.content.userInfo["schedule"] as? String {
						TrainingScheduleManager.loadTrainingSchedules(completion: { schedules in
							var schedule: TrainingSchedule?
							for sch in schedules {
								if sch.file == sched {
									schedule = sch
									break
								}
							}
							if let schedule = schedule {
								switch response.actionIdentifier {
								case "scheduleImport":
									main.hideLoadingView()
									TrainingScheduleManager.importSchedule(schedule: schedule, completion: {
										//TODO: send local notification to inform user of successful import
										completionHandler()
									})
								case "scheduleView":
									self.viewSchedule(schedule: schedule)
									completionHandler()
								default:
									self.viewSchedule(schedule: schedule)
									completionHandler()
								}
							}
						})
					}
				}
			}
		} else {
			completionHandler()
		}
	}
	
	private func viewSchedule(schedule: TrainingSchedule) {
		if let nav = self.window?.rootViewController as? RootNavigationViewController {
			nav.popToRootViewController(animated: true)
			if let main = nav.viewControllers[0] as? MainMenuViewController {
				main.viewTrainingSchedule(schedule)
			}
		}
	}
	
	func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
		print("Notification received while app is in the foreground")
	}
}

