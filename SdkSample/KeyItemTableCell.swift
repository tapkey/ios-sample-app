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

public class KeyItemTableCell : UITableViewCell {
 
    @IBOutlet weak var wrapperView: UIView!;
    @IBOutlet weak var lockName: UILabel!;
    @IBOutlet weak var ownerName: UILabel!;
    @IBOutlet weak var validFrom: UILabel!;
    @IBOutlet weak var validUntil: UILabel!;
    @IBOutlet weak var buttonWrapper: UIView!;
    @IBOutlet weak var button: UIButton!;
    @IBOutlet weak var progressIndicator: UIActivityIndicatorView!;
    
    private var key:NetTpkyMcModelWebviewCachedKeyInformation? = nil;
    private var triggerFn: Func<TkPromise<Bool>>?;
    
    private var inProgress: Bool = false;
    
    public func setKey(_ key:NetTpkyMcModelWebviewCachedKeyInformation, nearby: Bool, triggerFn: @escaping Func<TkPromise<Bool>>){
        
        self.key = key;
        self.triggerFn = triggerFn;
        
        // Show button only, if lock is nearby
        self.buttonWrapper!.isHidden = !nearby;
        

        let lockName: String = key.getGrant()?.getBoundLock()?.getTitle() ?? "Unkown";
        let ownerName: String = key.getGrant()?.getOwner()?.getName() ?? "Unkown"
        let validFrom: Date? = key.getGrant()?.getValidFrom()?.toDate() ?? nil;
        let validBefore: Date? = key.getGrant()?.getValidBefore()?.toDate() ?? nil;

        
        self.lockName.text = lockName;
        self.ownerName.text = ownerName;
        
        
        if let validFromTmp: Date = validFrom {
            let text = DateFormatter.localizedString(from: validFromTmp, dateStyle: DateFormatter.Style.medium, timeStyle: DateFormatter.Style.medium)
            self.validFrom.text = text;

        }else {
            self.validFrom.text = "Unrestricted"
        }
        
        if let validBeforeTmp: Date = validBefore {
            let text = DateFormatter.localizedString(from: validBeforeTmp, dateStyle: DateFormatter.Style.medium, timeStyle: DateFormatter.Style.medium)
            self.validUntil.text = text;
            
        }else {
            self.validUntil.text = "Unlimited"
        }

    }
    

    @IBAction func onClickTriggerLock(_ sender: Any) {
        
        if( self.inProgress){
            NSLog("Trigger is allready in progress");
            return;
        }
        
        self.inProgress = true;
        self.button.isHidden = true;
        self.progressIndicator.startAnimating();
        
        self.triggerFn?()
            .continueOnUi({ (success: Bool?) -> Void in
                
                if(success ?? false) {
                    
                    self.wrapperView.backgroundColor = UIColor(red: 0.6, green: 0.8, blue: 0, alpha: 1);
                
                } else {
                    
                    self.wrapperView.backgroundColor = .red;
                }
                
                
            })
            .catchOnUi({ (e:NSException?) in
                
                self.wrapperView.backgroundColor = .red;
            })
            .finallyOnUi {
             
                // reset progress indication
                self.progressIndicator.stopAnimating();
                self.inProgress = false;
                self.button.isHidden = false;
                
                // reset background color after delay
                NetTpkyMcConcurrentAsync.delay(withLong: 2000)
                    .continueOnUi({ (aVoid: Void?) -> Void? in
                        self.wrapperView.backgroundColor = .clear;
                    }).conclude();
                
            }
            .conclude();
        
    }
    
}
 
