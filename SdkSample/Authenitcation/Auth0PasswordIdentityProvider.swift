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
import TapkeyMobileLib
import Auth0

public class Auth0PasswordIdentityProvider: NSObject, TkIdenitityProvider {
    
    private static let TAG:String = String(describing: Auth0PasswordIdentityProvider.self);
    
    public static let IP_ID = "com.auth0";
    private static let PARTITION_KEY = "";


    let configManager: TkConfigManager;
    let auth0Dao: NetTpkyMcDaoDao;
    
    public init(configManager: TkConfigManager, dataContext: NetTpkyMcDaoDataContext){
    
        self.configManager = configManager;
        self.auth0Dao = dataContext.getAuth0Dao();
        
    }
    
    public func signInWithPassword(email: String, password: String, cancellationToken: TkCancellationToken) -> TkPromise<TkModelIdentity> {

        return self.getAuth0Client(cancellationToken: cancellationToken)
            .continueAsyncOnUi{ (client: AsyncAuth0Client?) -> TkPromise<TkModelIdentity> in
                
                return client!.loginAsync(email: email, password: password, scope: "openid email offline_access")
                    .continueOnUi{ (response: Credentials?) -> TkModelIdentity in
                        
                        guard let credentials:Credentials = response else {
                            JavaLangIllegalStateException(nsString: "no response").raise();
                            // won't be reached
                            return TkModelIdentity(nsString: nil, with: nil);
                        }
                        
                        guard let idToken: String = credentials.idToken else {
                            JavaLangIllegalStateException(nsString: "no id_token response").raise();
                            // won't be reached
                            return TkModelIdentity(nsString: nil, with: nil);
                        }
                        
                        if let refreshToken: String = credentials.refreshToken {
                            
                            let auth0Data = self.auth0Dao.getWith(Auth0PasswordIdentityProvider.PARTITION_KEY, with: email) as? NetTpkyMcModelAuth0Auth0Data;
                            
                            if let currentRefreshToken: String = auth0Data?.getRefresh_token() {
                            
                                _ = client?.revokeAsync(refreshToken: currentRefreshToken)
                                    .continueOnUi{ (aVoid: Void?) -> Void in
                                        TkLog.d(with: Auth0PasswordIdentityProvider.TAG, with: "Revocation of refresh token was successfully.");
                                    }
                                    .catchOnUi { (e: NSException?) -> Void? in
                                        TkLog.e(with: Auth0PasswordIdentityProvider.TAG, with: "Revocation of refresh token failed.", nsException: e)
                                        return nil;
                                    }
                                
                            }
                            
                            self.auth0Dao.save(with: Auth0PasswordIdentityProvider.PARTITION_KEY, with: email, withId: NetTpkyMcModelAuth0Auth0Data(nsString: credentials.accessToken, with: refreshToken));
                            
                        }
                    
                        return TkModelIdentity(nsString: Auth0PasswordIdentityProvider.IP_ID, with: idToken)
                    }
                    .catchOnUi { exception in

                        var srcException: NSException = exception!;
                        
                        if let asyncException = exception as? NetTpkyMcConcurrentAsyncException {
                            srcException = asyncException.getSyncSrcException();
                        }
                        
                        if let errorException: ErrorException = srcException as? ErrorException,
                            let error: Error = errorException.getError(),
                           let aut0Error = error as? Auth0.AuthenticationError {

                            if(aut0Error.isInvalidCredentials) {
                                NetTpkyMcErrorTkException(netTpkyMcModelTkErrorDescriptor: NetTpkyMcModelTkErrorDescriptor(nsString: NetTpkyMcErrorAuthenticationErrorCodes.verificationFailed(), with: "sign in with auth0 failed", withId: nil)).raise();
                            }
                            
                            if(aut0Error.isTooManyAttempts){
                                NetTpkyMcErrorTkException(netTpkyMcModelTkErrorDescriptor: NetTpkyMcModelTkErrorDescriptor(nsString: NetTpkyMcErrorAuthenticationErrorCodes.tooManyAttempts(), with: "sign in with auth0 failed", withId: nil)).raise();
                            }
                        }
                        
                        NetTpkyMcErrorTkException(netTpkyMcModelTkErrorDescriptor: NetTpkyMcModelTkErrorDescriptor(nsString: NetTpkyMcErrorGenericErrorCodes.genericError(), with: "sign in with auth0 failed", withId: nil)).raise();

                        // won't be reached
                        return nil;
                     }
            }
        
    }
    
    public func logOut(user: NetTpkyMcModelUser, cancellationToken: TkCancellationToken) -> TkPromise<Void> {
        
        let email = user.getIpUserName()!;
        
        guard let auth0Data = self.auth0Dao.getWith(Auth0PasswordIdentityProvider.PARTITION_KEY, with: email) as? NetTpkyMcModelAuth0Auth0Data else {
            return TkAsync.promiseFromException(JavaLangIllegalStateException(nsString: "No user signed in with this username"))
        }
        
        self.auth0Dao.delete__(with: Auth0PasswordIdentityProvider.PARTITION_KEY, with: email);
        
        guard let refreshToken = auth0Data.getRefresh_token() else {
            TkLog.w(with: Auth0PasswordIdentityProvider.TAG, with: "No refresh token persisted. Skip revocation of refresh token");
            return TkAsync.PromiseFromResult(nil);
        }
        
        TkLog.d(with: Auth0PasswordIdentityProvider.TAG, with: "Going to revoke refresh token.") ;
        
        return self.getAuth0Client(cancellationToken: cancellationToken).continueAsyncOnUi{ (auth0Client: AsyncAuth0Client?) -> TkPromise<Void> in
            
            return auth0Client!.revokeAsync(refreshToken: refreshToken)
                .continueOnUi { (aVoid: Void?) -> Void in
                    TkLog.d(with: Auth0PasswordIdentityProvider.TAG, with: "Revocation of refresh token was successfully.");
                }
                .catchOnUi { (e: NSException?) -> Void? in
                    
                    TkLog.e(with: Auth0PasswordIdentityProvider.TAG, with: "Revocation of refresh token failed.", nsException: e)
                    return nil;
                }
            
        }        
    }
    
    public func refreshToken(user: NetTpkyMcModelUser, cancellationToken: TkCancellationToken) -> TkPromise<NetTpkyMcModelIdentity> {
        
        guard let ipId = user.getIpId() else {
            return TkAsync.promiseFromException(JavaLangException(nsString: "ipId must not be null."));
        }
    
        guard let email = user.getIpUserName() else {
            return TkAsync.promiseFromException(JavaLangException(nsString: "email must not be null"));
        }
        
        if(ipId != Auth0PasswordIdentityProvider.IP_ID){
            TkLog.e(with: Auth0PasswordIdentityProvider.TAG, with: "The ipId " + ipId + " can not be handled by this IdentityProvider.");
            return TkAsync.promiseFromException(JavaLangException(nsString: "The ipId " + ipId + " can not be handled by this IdentityProvider."));
        }
        
        guard let auth0Data: NetTpkyMcModelAuth0Auth0Data = self.auth0Dao.getWith(Auth0PasswordIdentityProvider.PARTITION_KEY, with: email) as? NetTpkyMcModelAuth0Auth0Data else {
            TkLog.e(with: Auth0PasswordIdentityProvider.TAG, with: "This user was not logged in by this IdentityProvider.");
            return TkAsync.promiseFromException(JavaLangIllegalStateException(nsString: "This user was not logged in by this IdentityProvider."));
        }
        
        return self.getAuth0Client(cancellationToken: cancellationToken)
            .continueAsyncOnUi { (client: AsyncAuth0Client?) -> TkPromise<NetTpkyMcModelIdentity> in
                
                client!.renewAuthAsync(refreshToken: auth0Data.getRefresh_token()!)
                    .continueOnUi { (idToken: String?) -> NetTpkyMcModelIdentity in
                        return NetTpkyMcModelIdentity(nsString: Auth0PasswordIdentityProvider.IP_ID, with: idToken!)
                    }
                    .catchOnUi { (e) -> NetTpkyMcModelIdentity? in
                
                        TkLog.e(with: Auth0PasswordIdentityProvider.TAG, with: "Refresh token via auth0 failed", nsException: e);
                        
                        NetTpkyMcErrorTkException(netTpkyMcModelTkErrorDescriptor: NetTpkyMcModelTkErrorDescriptor(nsString: NetTpkyMcManagerIdenitityIdentityProviderErrorCodes.tokenRefreshFailed(), with: "Refresh token via auth0 failed", withId: nil)).raise();
                        
                        return nil;
                    }
            
        }
  
    }

    private func getAuth0Client(cancellationToken: TkCancellationToken) -> TkPromise<AsyncAuth0Client> {
        
        return self.configManager
            .updateConfigAsync(cancellationToken: cancellationToken)
            .continueOnUi{ (config: NetTpkyMcModelConfig?) -> AsyncAuth0Client in
                
                if(config == nil){
                    JavaLangIllegalStateException(nsString: "Config result was unexpected null.").raise();
                }
                
                let auth0Config = config?.getAuth0Config();

                if(auth0Config == nil || auth0Config?.getClientId() == nil || auth0Config?.getServer() == nil || auth0Config?.getConnection() == nil ){
                    JavaLangIllegalStateException(nsString: "Can't fetch auth0 information").raise();
                }

                return AsyncAuth0Client(config: auth0Config!);
            }
            .catchOnUi{ (e) -> AsyncAuth0Client? in
                
                TkLog.e(with: Auth0PasswordIdentityProvider.TAG, with: "Failed to fetch auth0 configuration from backend", nsException: e);
                e!.raise();
                return nil;
                
            };
        
        
    }
    
}


