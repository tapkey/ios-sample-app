import TapkeyMobileLib
import UIKit

class KeyItemTableCell: UITableViewCell {

    @IBOutlet weak var wrapperView: UIView!
    @IBOutlet weak var lockTitle: UILabel!
    @IBOutlet weak var lockLocation: UILabel!
    @IBOutlet weak var issuer: UILabel!
    @IBOutlet weak var grantee: UILabel!
    @IBOutlet weak var restriction: UILabel!
    @IBOutlet weak var buttonWrapper: UIView!
    @IBOutlet weak var button: UIButton!
    @IBOutlet weak var progressIndicator: UIActivityIndicatorView!

    private var key: (TKMKeyDetails, ApplicationGrant)?
    private var triggerFn: (() -> TKMPromise<Bool>)?

    private var inProgress: Bool = false

    public func setKey(_ key: (TKMKeyDetails, ApplicationGrant),
                       nearby: Bool,
                       triggerFn: @escaping () -> TKMPromise<Bool>) {

        self.key = key
        self.triggerFn = triggerFn

        // Show button only if the lock is nearby
        self.buttonWrapper.isHidden = !nearby

        if key.1.validFrom == nil, key.1.validBefore == nil, key.1.timeRestrictionIcal == nil {
            self.restriction.text = "Unrestricted Access"
        } else {
            self.restriction.text = "Restricted Access"
        }

        self.lockTitle.text = key.1.lockTitle ?? "Unknown"
        self.issuer.text = "Issued by " + (key.1.issuer ?? "Unknown")
        self.lockLocation.text = "Located at " + (key.1.lockLocation ?? "Unknown")
        self.grantee.text = "for " + (key.1.granteeFirstName ?? "") + " " + (key.1.granteeLastName ?? "")
    }

    @IBAction func onClickTriggerLock(_ sender: Any) {

        if self.inProgress {
            NSLog("Triggering lock is already in progress.")
            return
        }

        self.inProgress = true
        self.button.isHidden = true
        self.progressIndicator.startAnimating()

        self.triggerFn?()
            .continueOnUi({ (success: Bool?) -> Void in
                if success ?? false {
                    self.wrapperView.backgroundColor = UIColor(red: 0.6, green: 0.8, blue: 0, alpha: 1)
                } else {
                    self.wrapperView.backgroundColor = .red
                }
            })
            .catchOnUi({ (_: TKMAsyncError) in
                self.wrapperView.backgroundColor = .red
                return nil
            })
            .finallyOnUi {
                // Reset progress indication
                self.progressIndicator.stopAnimating()
                self.inProgress = false
                self.button.isHidden = false

                // Reset background color after delay
                TKMAsync.delayAsync(delayMs: 2000)
                    .continueOnUi({ (_: Void?) -> Void? in
                        self.wrapperView.backgroundColor = .clear
                    }).conclude()
            }
            .conclude()
    }

}
