import TapkeyMobileLib
import UIKit

class AboutViewController: UIViewController {

    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var version: UILabel!
    @IBOutlet weak var tapkeySDKVersion: UILabel!

    private var alertController: UIAlertController?

    override func viewDidLoad() {
        self.version.text = Bundle.main.object(forInfoDictionaryKey: kCFBundleVersionKey as String) as? String
        self.name.text = Bundle.main.object(forInfoDictionaryKey: kCFBundleNameKey as String) as? String
        guard let tapkeySDKPlistFileURL = Bundle.main.url(
            forResource: "TapkeyMobileLib.bundle/Info",
            withExtension: "plist") else {
                self.tapkeySDKVersion.text = "Unknown"
                return
        }
        let tapkeySDKInfoDict = NSDictionary(contentsOf: tapkeySDKPlistFileURL)
        self.tapkeySDKVersion.text = tapkeySDKInfoDict?["CFBundleVersion"] as? String
    }

    @IBAction func onClickShowThirdPartyLicences(_ sender: Any) {
        do {
            let filepath = Bundle.main.url(forResource: "third_party_licenses", withExtension: "txt")
            let content = try String(contentsOf: filepath!, encoding: String.Encoding.utf8)

            let cancelAction = UIAlertAction(title: "Ok", style: .default) { (_) in
                self.alertController=nil
            }

            self.alertController = UIAlertController(
                    title: "Third-party licenses",
                    message: "\n" + content, preferredStyle: .alert
            )
            self.alertController!.addAction(cancelAction)
            self.present(self.alertController!, animated: true, completion: nil)

        } catch {
            NSLog("Failed to read license file.")
        }
    }

}
