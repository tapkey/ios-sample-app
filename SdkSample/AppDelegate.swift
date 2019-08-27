import TapkeyMobileLib
import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    private var tapkeyServiceFactory: TKMServiceFactory!

    func application(
            _ application: UIApplication,
            willFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {

        // Build service factory
        self.tapkeyServiceFactory = TKMServiceFactoryBuilder()
            .setTokenRefreshHandler(SampleTokenRefreshHandler(viewController: self.window!.rootViewController!))
            .build()

        // Check whether a user is logged in. If not, go to login view.
        if self.tapkeyServiceFactory.userManager.users.count < 1 {
            self.window = UIWindow(frame: UIScreen.main.bounds)
            let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
            let signInController = mainStoryboard
                    .instantiateViewController(withIdentifier: "LoginViewController") as! LoginViewController
            self.window?.rootViewController = signInController
            self.window?.makeKeyAndVisible()
        }

        return true

    }

    func application(
            _ application: UIApplication,
            didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        return true
    }

    // Background fetch
    func application(
            _ application: UIApplication,
            performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {

        // Configure the Tapkey SDK to poll for notifications.
        // Run the code via runAsyncInBackground to prevent the app from sleeping while fetching is in progress.
        runAsyncInBackground(application, promise:
            self.tapkeyServiceFactory.notificationManager
                    .pollForNotificationsAsync(cancellationToken: TKMCancellationTokens.None)
                    .finallyOnUi {
                        completionHandler(UIBackgroundFetchResult.newData)
                    }
        )
    }

    func applicationWillResignActive(_ application: UIApplication) {
        /*
         * Sent when the application is about to move from active to inactive state. This can occur for certain types of
         * temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the
         * application and it begins the transition to the background state.
         * Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games
         * should use this method to pause the game.
         */
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        /*
         * Use this method to release shared resources, save user data, invalidate timers, and store enough application
         * state information to restore your application to its current state in case it is terminated later.
         * If your application supports background execution, this method is called instead of applicationWillTerminate:
         * when the user quits.
         */
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        /*
         * Called as part of the transition from the background to the active state; here you can undo many of the
         * changes made on entering the background.
         */
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        /*
         * Restart any tasks that were paused (or not yet started) while the application was inactive. If the
         * application was previously in the background, optionally refresh the user interface.
         */
    }

    func applicationWillTerminate(_ application: UIApplication) {
        /*
         * Called when the application is about to terminate. Save data if appropriate. See also
         * applicationDidEnterBackground:.
         */
    }

    public func getTapkeyServiceFactory() -> TKMServiceFactory {
        return self.tapkeyServiceFactory
    }
}
