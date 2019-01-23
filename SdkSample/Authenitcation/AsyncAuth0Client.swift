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

class AsyncAuth0Client {
    
    private let auth0: Authentication;
    private let server: String;
    private let dbConnection: String;
    
    convenience init(config: NetTpkyMcModelAuth0Config){
        self.init(clientId: config.getClientId(), server: config.getServer(), dbConnection: config.getConnection());
    }
    
    init(clientId: String, server: String, dbConnection:String ){
        
        self.server = server;
        self.dbConnection = dbConnection;
        
        let domain = server.replacingOccurrences(of: "https://", with: "");
        
        self.auth0 = Auth0.authentication(clientId: clientId, domain: domain);
        
    }
    
    
    func loginAsync(email:String, password:String, scope: String) -> TkPromise<Auth0.Credentials> {
        return self.requestToPromise(self.auth0.login(usernameOrEmail: email, password: password, realm: self.dbConnection, audience: self.server + "/userinfo", scope: scope));
    }
    
    func renewAuthAsync(refreshToken: String) -> TkPromise<String> {
        
        return self.requestToPromise(self.auth0.delegation(withParameters: ["refresh_token": refreshToken]))
            .continueOnUi({ (value: [String:Any]?) -> String in

                guard let idToken = value?["id_token"] as? String else {
                    
                    JavaLangIllegalStateException(nsString: "No idToken in response").raise();
                    return "";
                    
                }
                
                return idToken;
            })
        
    }
    
    func revokeAsync(refreshToken: String) -> TkPromise<Void>{
        return self.requestToPromise(self.auth0.revoke(refreshToken: refreshToken));
    }
    
    private func requestToPromise<T>(_ request: Auth0.Request<T, Auth0.AuthenticationError>) -> TkPromise<T> {
        let promiseSource = TkPromiseSource<T>();
        
        
        request.start { (result: Result<T>) in
            
            switch(result){
            case .success(let result):
                promiseSource.setResult(result);
                break;
                
            case .failure(let error):
                
                promiseSource.setException(ErrorException(error))
                break;
                
            }
            
        }
        
        return promiseSource.getPromise();
    }
}
