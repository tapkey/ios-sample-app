/* /////////////////////////////////////////////////////////////////////////////////////////////////
 //                          Copyright (c) Tapkey GmbH
 //
 //         All rights are reserved. Reproduction in whole or in part is
 //        prohibited without the written consent of the copyright owner.
 //    Tapkey reserves the right to make changes without notice at any time.
 //   Tapkey makes no warranty, expressed, implied or statutory, including but
 //   not limited to any implied warranty of merchantability or fitness for any
 //  particular purpose, or that the use will not infringe any third party patent,
 //   copyright or trademark. Tapkey must not be liable for any loss or damage
 //                            arising from its use.
 ///////////////////////////////////////////////////////////////////////////////////////////////// */


import UIKit
import TapkeyMobileLib

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, TapkeyAppDelegate {

    var window: UIWindow?

    private var tapkeyServiceFactory:TapkeyServiceFactory!;
    fileprivate var tapkeyIdentityProivder:Auth0PasswordIdentityProvider!;

    func application(_ application: UIApplication,
                     willFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        // Build service factory singleton instance
        self.tapkeyServiceFactory = TapkeyServiceFactoryBuilder()
            
            // Change the backend URI if required.
            //.setServiceBaseUri(serviceBaseUri: "https://example.com")
            
            //Change the tenant if required.
            //.setTenantId(tenantId: "someTenant")
            
            .build();
        
        //
        // Create and register IdentityProviders
        //
        // The Auth0PasswordIdentityProvider is an optional identity provider. To use this provider the Auth0Authentication.framework
        // must be loaded.
        //
        let configManager = tapkeyServiceFactory.getConfigManager();
        let dataContext = tapkeyServiceFactory.getDataContext();
        
        let tapkeyIdentityProivder = Auth0PasswordIdentityProvider(configManager: configManager, dataContext: dataContext);
        self.tapkeyIdentityProivder = tapkeyIdentityProivder;
        _ = tapkeyServiceFactory.getIdentityProviderRegistration().registerIdentityProvider(ipId: Auth0PasswordIdentityProvider.IP_ID, identityProvider: tapkeyIdentityProivder);
        
        
        // Find out, whether a user is logged in. If not, go to SignIn View
        let userManager = tapkeyServiceFactory.getUserManager();
        if(!userManager.hasUsers()){
            self.window = UIWindow(frame: UIScreen.main.bounds);
            let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil);
            let signInController = mainStoryboard.instantiateViewController(withIdentifier: "SignInViewController") as! SignInViewController;
            self.window?.rootViewController = signInController;
            self.window?.makeKeyAndVisible();
        }
        
        return true;

    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        return true
    }
    
    // Backgroung fetch
    func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        
        // Let Tapkey poll for notifications.
        // Run the code via runAsyncInBackground to prevent app from sleeping while fetching is in progress.
        runAsyncInBackground(application, promise: self.tapkeyServiceFactory!.getPollingManager().poll(with:nil, with: NetTpkyMcConcurrentCancellationTokens_None)
            .finallyOnUi {
                completionHandler(UIBackgroundFetchResult.newData);
            }
        );
        
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
    }

    public func getTapkeyServiceFactory() -> TapkeyServiceFactory {
        return self.tapkeyServiceFactory;
    }

    public func getTapkeyIdentityProvider() -> Auth0PasswordIdentityProvider {
        return self.tapkeyIdentityProivder!;
    }

}

