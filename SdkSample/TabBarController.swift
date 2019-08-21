import TapkeyMobileLib
import UIKit

class TabBarController: UITabBarController, UITabBarControllerDelegate {

    var userManager: TKMUserManager!

    override func viewDidLoad() {
        delegate = self

        let app: AppDelegate = UIApplication.shared.delegate as! AppDelegate
        let tapkeyServiceFactory = app.getTapkeyServiceFactory()
        self.userManager = tapkeyServiceFactory.userManager
    }

    func tabBarController(
            _ tabBarController: UITabBarController,
            shouldSelect viewController: UIViewController) -> Bool {

        if viewController.title == "logout" {
            NSLog("Logging out")
            self.signOut()
            return false
        }

        return true
    }

    func signOut() {

        // Destroy user session of sample server
        SampleAuthStateManager.setLoggedOut()

        // Perform Tapkey SDK logout
        guard let userManager = self.userManager else { return }

        // Although there is only one user allowed in this sample app, any user is logged out to ensure consistency
        for userId in userManager.users {
            _ = userManager.logOutAsync(userId: userId, cancellationToken: TKMCancellationTokens.None)
        }

        // Redirect to login view
        let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let signInViewController = storyBoard.instantiateViewController(withIdentifier: "LoginViewController")
        self.present(signInViewController, animated: true, completion: nil)
    }

}
