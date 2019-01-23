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

class SignInViewController: UIViewController {
    
    @IBOutlet weak var username: UITextField!
    @IBOutlet weak var password: UITextField!
    @IBOutlet weak var button: UIButton!
    @IBOutlet weak var progressIndicator: UIActivityIndicatorView!;
    @IBOutlet weak var errorMessage: UILabel!;
    
    var userManager:TkUserManager?;
    var tapkeyIdentityProvider: Auth0PasswordIdentityProvider?;
    
    private var inProgress: Bool = false;
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let app:AppDelegate = UIApplication.shared.delegate as! AppDelegate;
        let tapkeyServiceFactory:TapkeyServiceFactory = app.getTapkeyServiceFactory();
        self.userManager = tapkeyServiceFactory.getUserManager();
        self.tapkeyIdentityProvider = app.getTapkeyIdentityProvider();
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func onClickSignIn(sender: UIButton) {

        if(self.inProgress){
            NSLog("Signin is already in progress");
            return;
        }
        
        let username = self.username.text;
        let password = self.password.text;
        
        
        if( username == nil || username! == "") {
            self.displayError("Please enter your email address");
            return;
        }
        
        if(!self.isValidEmail(testStr: username!)){
            self.displayError("Please enter a valid email address");
            return;
        }
        
        if( password == nil || password! == "") {
            self.displayError("Please enter your password");
            return;
        }
        
        self.inProgress = true;
        
        self.button.isEnabled = false;
        self.button.isHidden = true;
        self.username.isEnabled = false;
        self.password.isEnabled = false;
        self.progressIndicator.startAnimating();
        self.errorMessage.isHidden = true;
        
        self.tapkeyIdentityProvider!.signInWithPassword(email: username!, password: password!, cancellationToken: TkCancellationToken_None)

            .continueAsyncOnUi({ (identity: TkModelIdentity?) -> TkPromise<NetTpkyMcModelUser> in
                
                return self.userManager!.authenticateAsync(identity: identity!, cancellationToken: TkCancellationToken_None)
                
                
            })
            .continueOnUi({ (user: NetTpkyMcModelUser?) -> Void in
                
                // Signin was sucessfully. Continue with next view.
                self.finish();
            })
            .catchOnUi({ (e: NSException?) -> Void in
                
                self.progressIndicator.stopAnimating();
                self.button.isEnabled = true;
                self.button.isHidden = false;
                self.username.isEnabled = true;
                self.password.isEnabled = true;
                self.inProgress = false;
                
                if let asyncException = e as? NetTpkyMcConcurrentAsyncException,
                    let srcException = asyncException.getSyncSrcException(),
                    let tkException = srcException as? NetTpkyMcErrorTkException,
                    let errorCode = tkException.getErrorCode() {
                    
                    
                    if(errorCode == NetTpkyMcErrorAuthenticationErrorCodes.verificationFailed()){
                        self.displayError("Password or email address invalid");
                        return;
                    }
                    
                    if(errorCode == NetTpkyMcErrorAuthenticationErrorCodes.emailNotVerified()){
                        self.displayError("Your email address is not verified yet");
                        return;
                    }
                    
                    if(errorCode == NetTpkyMcErrorAuthenticationErrorCodes.tooManyAttempts()){
                        self.displayError("Your account is blocked");
                        return;
                    }
                    
                    if(errorCode == NetTpkyMcErrorAuthenticationErrorCodes.emailAlreadyExists()){
                        self.displayError("This email address is already used with another ip provider");
                        return;
                    }
                    
                }
                
                self.displayError("Ooops something went wrong")
                
            })
            .conclude();
        
        
    }
    
    private func displayError(_ message: String){
        self.errorMessage.text = message;
        self.errorMessage.isHidden = false;
    }
    
    private func finish() -> Void {

        let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil);
        let signInViewController = storyBoard.instantiateViewController(withIdentifier: "TabBarController");
        self.present(signInViewController, animated:true, completion:nil);
        
    }
    
    
    private func isValidEmail(testStr:String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailTest.evaluate(with: testStr)
    }
}

