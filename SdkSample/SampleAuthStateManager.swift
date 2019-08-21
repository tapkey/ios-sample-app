import Foundation

/**
 * Handles the app's authentication state. Please note that this is not related to authentication with Tapkey. Also,
 * this is just a simple example and should not be used in production scenarios.
 */
class SampleAuthStateManager {

    private static let keyUsername = "KEY_USERNAME"
    private static let keyPassword = "KEY_PASSWORD"

    static func setLoggedIn(username: String, password: String) {
        UserDefaults.standard.set(username, forKey: keyUsername)
        UserDefaults.standard.set(password, forKey: keyPassword)
    }

    static func setLoggedOut() {
        UserDefaults.standard.removeObject(forKey: keyUsername)
        UserDefaults.standard.removeObject(forKey: keyPassword)
    }

    static func isLoggedIn() -> Bool {
        return getUsername() != nil && getPassword() != nil
    }

    static func getUsername() -> String? {
        return UserDefaults.standard.string(forKey: keyUsername)
    }

    static func getPassword() -> String? {
        return UserDefaults.standard.string(forKey: keyPassword)
    }

}
