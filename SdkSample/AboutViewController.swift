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
import UIKit
import TapkeyMobileLib

class AboutViewController: UIViewController {
    
    @IBOutlet weak var versionName: UILabel!;
    @IBOutlet weak var version: UILabel!;
    @IBOutlet weak var versionCode: UILabel!;
    @IBOutlet weak var buildString: UILabel!;
    
    private var alertController: UIAlertController?;
    
    override func viewDidLoad() {
        
        let app:AppDelegate = UIApplication.shared.delegate as! AppDelegate;
        let tapkeyServiceFactory:TapkeyServiceFactory = app.getTapkeyServiceFactory();
        let environment = tapkeyServiceFactory.getEnvironment();
        
        
        self.version.text = environment.getVersion();
        self.versionName.text = environment.getVersionName();
        self.versionCode.text = environment.getVersionCode().description;
        self.buildString.text = environment.getBuildString();
        
        
    }
    
    
    @IBAction func onClickShowThirdPartyLicences(_ sender: Any) {

        do {
            let filepath = Bundle.main.url(forResource: "third_party_licenses", withExtension: "txt");
            let content = try String(contentsOf: filepath!, encoding: String.Encoding.utf8);
            
            let cancelAction = UIAlertAction(title: "Ok", style: .default) { (action) in
                self.alertController=nil;
            }

            self.alertController = UIAlertController(title: "Third Party Licenses", message: "\n" + content, preferredStyle: .alert)
            self.alertController!.addAction(cancelAction)
            self.present(self.alertController!, animated: true, completion: nil)
            
        } catch {
            
            NSLog("Failed to read licence file");
        }
        
    }
    
}
