import Foundation

/**
 * Represents a grant in this sample application's domain. It is based on a Tapkey grant, extended by a few
 * domain-specific fields.
 */
class ApplicationGrant {
    var id: String?
    var state: String?
    var validBefore: Date?
    var validFrom: Date?
    var timeRestrictionIcal: String?
    var issuer: String?
    var granteeFirstName: String?
    var granteeLastName: String?
    var lockTitle: String?
    var lockLocation: String?
    var physicalLockId: String?
}
