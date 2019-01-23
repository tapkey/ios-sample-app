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


import Foundation
import UIKit
import TapkeyMobileLib

class TabBarController : UITabBarController, UITabBarControllerDelegate {
    
    var userManager:TkUserManager?;
    var tapkeyIdentityProvider: Auth0PasswordIdentityProvider?;

    
    override func viewDidLoad() {
        delegate = self
        
        
        let app:AppDelegate = UIApplication.shared.delegate as! AppDelegate;
        let tapkeyServiceFactory:TapkeyServiceFactory = app.getTapkeyServiceFactory();
        self.userManager = tapkeyServiceFactory.getUserManager();
        self.tapkeyIdentityProvider = app.getTapkeyIdentityProvider();

    }
    
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        
        if(viewController.title == "signout" ) {
            NSLog("SignOut now!");
            self.signOut();
            return false;
        }
        
        return true
        
    }
    
    
    func signOut() -> Void {
        
        guard let userManager = self.userManager else { return }
        guard let tapkeyIdentityProvider = self.tapkeyIdentityProvider else { return }

        for user in userManager.getUsers() {
        
            if (user == nil) { continue }
            
            let _ = userManager.logOff(user: user!, cancellationToken: TkCancellationToken_None);
            let _ = tapkeyIdentityProvider.logOut(user: user!, cancellationToken: TkCancellationToken_None)
            
        }
        
        let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil);
        let signInViewController = storyBoard.instantiateViewController(withIdentifier: "SignInViewController");
        self.present(signInViewController, animated:true, completion:nil);
    }

}
