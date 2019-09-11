import RxSwift
import TapkeyMobileLib
import UIKit

class LoginViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var username: UITextField!
    @IBOutlet weak var password: UITextField!
    @IBOutlet weak var firstName: UITextField!
    @IBOutlet weak var lastName: UITextField!
    @IBOutlet weak var button: UIButton!
    @IBOutlet weak var progressIndicator: UIActivityIndicatorView!
    @IBOutlet weak var errorMessage: UILabel!

    var userManager: TKMUserManager!
    var notificationManager: TKMNotificationManager!
    var sampleServerManager: SampleServerManager!
    var tokenExchangeManager: TapkeyTokenExchangeManager!

    private var inProgress: Bool = false

    override func viewDidLoad() {
        super.viewDidLoad()
        let app: AppDelegate = UIApplication.shared.delegate as! AppDelegate
        let tapkeyServiceFactory = app.getTapkeyServiceFactory()
        self.userManager = tapkeyServiceFactory.userManager
        self.notificationManager = tapkeyServiceFactory.notificationManager
        self.sampleServerManager = SampleServerManager()
        self.tokenExchangeManager = TapkeyTokenExchangeManager()
        
        self.lastName.delegate = self
        self.errorMessage.alpha = 0
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func onClickSignIn(sender: UIButton) {

        if self.inProgress {
            NSLog("Login is already in progress")
            return
        }

        let username = self.username.text
        let password = self.password.text

        if username == nil || username! == "" {
            self.displayError("Please enter your email address")
            return
        }

        if !self.isValidEmail(testStr: username!) {
            self.displayError("Please enter a valid email address")
            return
        }

        if password == nil || password! == "" {
            self.displayError("Please enter your password")
            return
        }

        self.inProgress = true
        self.button.isEnabled = false
        self.username.isEnabled = false
        self.password.isEnabled = false
        self.firstName.isEnabled = false
        self.lastName.isEnabled = false
        self.progressIndicator.startAnimating()
        self.errorMessage.alpha = 0

        _ = self.sampleServerManager.registerUser(
                        username: username!,
                        password: password!,
                        firstName: self.firstName.text ?? "",
                        lastName: self.lastName.text ?? "")
            .do(onNext: { _ -> Void in SampleAuthStateManager.setLoggedIn(username: username!, password: password!) })
            .flatMap { _ in self.sampleServerManager.getExternalToken(username: username!, password: password!) }
            .flatMap { externalToken in self.tokenExchangeManager.exchangeExternalToken(externalToken: externalToken) }
            .flatMap { tapkeyAccessToken in self.loginTapkeySDK(accessToken: tapkeyAccessToken) }
            .flatMap { _ in self.fetchTapkeyNotifications() }
            .subscribe(
                onNext: { _ in
                    // Login successful, continue to next view.
                    self.finish()
                },
                onError: { error in
                    print(error)
                    DispatchQueue.main.async {
                        self.button.isEnabled = true
                        self.username.isEnabled = true
                        self.password.isEnabled = true
                        self.firstName.isEnabled = true
                        self.lastName.isEnabled = true
                        self.inProgress = false
                        self.displayError("Login failed.")
                        self.progressIndicator.stopAnimating()
                    }
                }
            )
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }

    /**
     * Wraps the Tapkey mobile SDK functionality to log in a new user.
     */
    private func loginTapkeySDK(accessToken: String) -> Observable<String> {
        return Observable.create { observer in
            self.userManager.logInAsync(accessToken: accessToken, cancellationToken: TKMCancellationTokens.None)
                .continueOnUi { (userId) -> Void in
                    guard let tapkeyUserId = userId else {
                        observer.on(.error(LoginError.sdkLoginUnknownError))
                        return
                    }
                    observer.on(.next(tapkeyUserId))
                }
                .catchOnUi { (error) -> Void in
                    print(error)
                    observer.on(.error(LoginError.sdkLoginFailed))
                    return
                }
                .finallyOnUi {
                    observer.on(.completed)
                }
                .conclude()
            return Disposables.create()
        }
    }
    
    /**
     * Triggers a fetch for notifications from the Tapkey Trust Service. This is usually done during the application's
     * background fetch, but in order to ensure all data is available right away, this is called once manually after
     * login.
     * Implementing applications need to decide when to fetch for notifications manually.
     */
    private func fetchTapkeyNotifications() -> Observable<Void> {
        return Observable.create { observer in
            self.notificationManager.pollForNotificationsAsync(cancellationToken: TKMCancellationTokens.None)
                .continueOnUi { _ in
                    observer.on(.next(Void()))
                }
                .catchOnUi { (error) -> Void in
                    print(error)
                    observer.on(.error(LoginError.sdkNotificationFetchFailed))
                    return
                }
                .finallyOnUi {
                    observer.on(.completed)
                }
                .conclude()
            return Disposables.create()
        }
    }

    private func displayError(_ message: String) {
        self.errorMessage.text = message
        self.errorMessage.alpha = 1
    }

    private func finish() {
        let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let signInViewController = storyBoard.instantiateViewController(withIdentifier: "TabBarController")
        self.present(signInViewController, animated: true, completion: nil)
    }

    private func isValidEmail(testStr: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        let emailTest = NSPredicate(format: "SELF MATCHES %@", emailRegEx)
        return emailTest.evaluate(with: testStr)
    }

    enum LoginError: Error {
        case sdkLoginUnknownError
        case sdkLoginFailed
        case sdkNotificationFetchFailed
    }
}
