import Foundation

/**
 * Provides basic configuration for this sample app.
 */
enum Environment {

    private static let infoDictionary: [String: Any] = {
        guard let dict = Bundle.main.infoDictionary else {
            fatalError("Plist file not found")
        }
        return dict
    }()

    static let tapkeyAuthorizationServerScheme: String = {
        guard let authorizationServerScheme =
                Environment.infoDictionary["tapkey_authorization_server_scheme"] as? String else {
            fatalError("Tapkey authorization server scheme not set in plist for this environment")
        }
        return authorizationServerScheme
    }()

    static let tapkeyAuthorizationServerAuthority: String = {
        guard let authorizationServerAuthority =
                Environment.infoDictionary["tapkey_authorization_server_authority"] as? String else {
            fatalError("Tapkey authorization server authority not set in plist for this environment")
        }
        return authorizationServerAuthority
    }()

    static let tapkeyOAuthClientId: String = {
        guard let oAuthClientId = Environment.infoDictionary["tapkey_oauth_client_id"] as? String else {
            fatalError("Tapkey OAuth client ID not set in plist for this environment")
        }
        return oAuthClientId
    }()

    static let tapkeyIdentityProviderId: String = {
        guard let identityProviderId = Environment.infoDictionary["tapkey_identity_provider_id"] as? String else {
            fatalError("Tapkey identity provider ID not set in plist for this environment")
        }
        return identityProviderId
    }()

    static let sampleBackendScheme: String = {
        guard let sampleBackendScheme = Environment.infoDictionary["sample_backend_scheme"] as? String else {
            fatalError("Sample backend scheme not set in plist for this environment")
        }
        return sampleBackendScheme
    }()

    static let sampleBackendHost: String = {
        guard let sampleBackendHost = Environment.infoDictionary["sample_backend_host"] as? String else {
            fatalError("Sample backend host not set in plist for this environment")
        }
        return sampleBackendHost
    }()

    static let sampleBackendPort: Int = {
        guard let sampleBackendPortString = Environment.infoDictionary["sample_backend_port"] as? String else {
            fatalError("Sample backend port not set in plist for this environment")
        }
        guard let sampleBackendPort = Int(sampleBackendPortString) else {
            fatalError("Sample backend port is invalid")
        }
        return sampleBackendPort
    }()

}
