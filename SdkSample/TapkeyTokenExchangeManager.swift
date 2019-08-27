import AppAuth
import RxCocoa
import RxSwift

/**
 * This class is responsible for exchanging external JWT tokens for Tapkey access tokens. It implements the last step of
 * the Token Exchange grant type flow. Access tokens obtained through this class' exchangeExternalToken() method can be
 * used to log in users in the Tapkey mobile SDK.
 */
class TapkeyTokenExchangeManager {

    private var urlComponents: URLComponents

    init() {
        urlComponents = URLComponents()
        urlComponents.scheme = Environment.tapkeyAuthorizationServerScheme
        urlComponents.host = Environment.tapkeyAuthorizationServerAuthority
    }

    /**
     * Exchanges an external JWT token for a Tapkey access token.
     *
     * - Parameters
     *     - externalToken: The external token to exchange for a Tapkey access token
     */
    func exchangeExternalToken(externalToken: String) -> Observable<String> {
        return self
            .discoverConfiguration()
            .flatMap { configuration in
                self.exchangeExternalToken(externalToken: externalToken, configuration: configuration)
            }
    }

    private func discoverConfiguration() -> Observable<OIDServiceConfiguration> {
        return Observable.create { observer in
            OIDAuthorizationService.discoverConfiguration(
                    forIssuer: self.urlComponents.url!.absoluteURL) { configuration, error in
                guard let config = configuration else {
                    print("Error retrieving discovery document: \(error?.localizedDescription ?? "Unknown")")
                    observer.on(.error(error ?? TapkeyTokenExchangeError.discoveryFailed))
                    return
                }
                observer.on(.next(config))
                observer.on(.completed)
            }
            return Disposables.create()
        }
    }

    private func exchangeExternalToken(
            externalToken: String, configuration: OIDServiceConfiguration) -> Observable<String> {
        return Observable.create { observer in
            let tokenRequest: OIDTokenRequest = OIDTokenRequest(
                configuration: configuration,
                grantType: "http://tapkey.net/oauth/token_exchange",
                authorizationCode: nil,
                redirectURL: nil,
                clientID: Environment.tapkeyOAuthClientId,
                clientSecret: nil,
                scopes: [ "register:mobiles", "read:user", "handle:keys" ],
                refreshToken: nil,
                codeVerifier: nil,
                additionalParameters: [
                    "provider": Environment.tapkeyIdentityProviderId,
                    "subject_token_type": "jwt",
                    "subject_token": externalToken,
                    "audience": "tapkey_api",
                    "requested_token_type": "access_token"
                ]
            )

            OIDAuthorizationService.perform(tokenRequest) { response, error in
                if let tokenResponse = response {
                    if let accessToken = tokenResponse.accessToken {
                        observer.on(.next(accessToken))
                        observer.on(.completed)
                    } else {
                       observer.on(.error(error ?? TapkeyTokenExchangeError.tokenResponseContainsNoAccessToken))
                    }
                } else {
                    observer.on(.error(error ?? TapkeyTokenExchangeError.tokenExchangeFailed))
                }
            }
            return Disposables.create()
        }
    }

    enum TapkeyTokenExchangeError: Error {
        case discoveryFailed
        case tokenExchangeFailed
        case tokenResponseContainsNoAccessToken
    }

}
