import RxSwift
import TapkeyMobileLib

class SampleTokenRefreshHandler: TKMTokenRefreshHandler {

    private let viewController: UIViewController
    private let sampleServerManager: SampleServerManager
    private let tokenExchangeManager: TapkeyTokenExchangeManager

    init(viewController: UIViewController) {
        self.viewController = viewController
        self.sampleServerManager = SampleServerManager()
        self.tokenExchangeManager = TapkeyTokenExchangeManager()
    }

    func refreshAuthenticationAsync(userId: String, cancellationToken: TKMCancellationToken) -> TKMPromise<String> {
        let promiseSource = TKMPromiseSource<String>()

        guard SampleAuthStateManager.isLoggedIn() else {
            promiseSource.setError(TKMError(errorDescriptor: TKMErrorDescriptor(
                code: TKMAuthenticationHandlerErrorCodes.TokenRefreshFailed,
                message: "No new token can be obtained.",
                details: nil)))
            return promiseSource.promise
        }

        _ = self
            .sampleServerManager.getExternalToken(
                username: SampleAuthStateManager.getUsername()!,
                password: SampleAuthStateManager.getPassword()!
            )
            .flatMap { externalToken in self.tokenExchangeManager.exchangeExternalToken(externalToken: externalToken) }
            .single()
            .subscribe(onNext: { (value) in
                promiseSource.setResult(value)
            }, onError: { (error) in
                print(error)
                promiseSource.setError(TKMRuntimeError.unknownError("Re-authentication failed."))
            })

        return promiseSource.promise
    }

    func onRefreshFailed(userId: String) {
        /*
         * This sample app does not support multiple Tapkey users, hence the user ID is ignored. It
         * is good practice to check if it matches the user that is expected nonetheless in real
         * applications.
         * Furthermore, if your application is likely unable to recover from this situation without
         * running the user through the application's own authentication logic, this is a good place
         * to force-logout the user, for instance, in this sample:
         */
        SampleAuthStateManager.setLoggedOut()

        print("Refreshing Tapkey authentication failed. Redirecting to login activity.")
        let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let signInViewController = storyBoard.instantiateViewController(withIdentifier: "LoginViewController")
        viewController.present(signInViewController, animated: true, completion: nil)
    }

    enum TokenRefreshHandlerError: Error {
        case promiseConversionFailed
    }

}
