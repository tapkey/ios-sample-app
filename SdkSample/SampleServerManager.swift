import RxCocoa
import RxSwift

/**
 * This class is responsible for communicating with the sample server. It provides functionality to register users,
 * retrieve external tokens for the Token Exchange grant type flow and to retrieve grants.
 */
class SampleServerManager {

    private var urlComponents: URLComponents

    init() {
        urlComponents = URLComponents()
        urlComponents.scheme = Environment.sampleBackendScheme
        urlComponents.host = Environment.sampleBackendHost
        urlComponents.port = Environment.sampleBackendPort
    }

    /**
     * Registers a new user with the sample server.
     *
     * - Parameters:
     *     - username: The username (will be used for basic authentication later)
     *     - password: The password (will be used for basic authentication later)
     *     - firstName: The user's first name
     *     - lastName: The users's last name
     *
     * - Returns: An Observable that will complete once the registration has finished.
     */
    func registerUser(username: String, password: String, firstName: String, lastName: String) -> Observable<Any> {
        urlComponents.path = "/user"
        var request = URLRequest(url: urlComponents.url!.absoluteURL)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: [
                "username": username,
                "password": password,
                "firstName": firstName,
                "lastName": lastName
                ])
        } catch let error {
            print(error.localizedDescription)
        }
        return URLSession.shared.rx.json(request: request)
    }

    /**
     * Returns an external token to be used in the Token Exchange grant type for the given user.
     *
     * - Parameters:
     *     - username: The username to use for basic authentication
     *     - password: The password to use for basic authentication
     *
     * - Returns: An Observable that yields an external token.
     */
    func getExternalToken(username: String, password: String) -> Observable<String> {
        urlComponents.path = "/user/tapkey-token"
        var request = URLRequest(url: urlComponents.url!.absoluteURL)
        request.httpMethod = "GET"
        authorizeRequest(request: &request, username: username, password: password)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        return URLSession.shared.rx
            .json(request: request)
            .map({ (data: Any) -> String in
                if let dictionary = data as? [String: Any] {
                    if let token = dictionary["externalToken"] as? String {
                        return token
                    }
                }
                throw TokenError.malformedResponse
            })
    }

    /**
     * Returns a list of application-specific grants for the given grant IDs.
     *
     * - Parameters:
     *     - username: The username to use for basic authentication
     *     - password: The password to use for basic authentication
     *     - grantIds: The grant IDs to get corresponding application grants for
     *
     * - Returns: An Observable that yields a list of grants, extended by application-specific grants.
     */
    func getGrants(username: String, password: String, grantIds: [String]) -> Observable<[ApplicationGrant]> {

        if grantIds.count <= 0 {
            return Observable.from([])
        }

        urlComponents.path = "/user/grants"
        urlComponents.queryItems = [ URLQueryItem(name: "grantIds", value: grantIds.joined(separator: ","))]
        var request = URLRequest(url: urlComponents.url!.absoluteURL)
        request.httpMethod = "GET"
        authorizeRequest(request: &request, username: username, password: password)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        return URLSession.shared.rx
            .json(request: request)
            .map({ (data) -> [ApplicationGrant] in
                if let grantDataList = data as? [Any] {
                    return grantDataList.map({ (grantData: Any) -> ApplicationGrant in
                        let grant = ApplicationGrant()
                        if let dictionary = grantData as? [String: Any] {
                            grant.id = dictionary["id"] as? String
                            grant.physicalLockId = dictionary["physicalLockId"] as? String
                            grant.state = dictionary["state"] as? String
                            grant.timeRestrictionIcal = dictionary["timeRestrictionIcal"] as? String
                            grant.validBefore = dictionary["validBefore"] as? Date
                            grant.validFrom = dictionary["validFrom"] as? Date
                            grant.granteeFirstName = dictionary["granteeFirstName"] as? String
                            grant.granteeLastName = dictionary["granteeLastName"] as? String
                            grant.issuer = dictionary["issuer"] as? String
                            grant.lockLocation = dictionary["lockLocation"] as? String
                            grant.lockTitle = dictionary["lockTitle"] as? String
                        }
                        return grant
                    })
                }
                throw TokenError.malformedResponse
            })
    }

    private func authorizeRequest(request: inout URLRequest, username: String, password: String) {
        let loginString = String(format: "%@:%@", username, password)
        let loginData = loginString.data(using: String.Encoding.utf8)!
        let base64LoginString = loginData.base64EncodedString()
        request.addValue("Basic \(base64LoginString)", forHTTPHeaderField: "Authorization")
    }

    enum TokenError: Error {
        case malformedResponse
    }

}
