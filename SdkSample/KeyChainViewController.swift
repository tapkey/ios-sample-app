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

class KeyChainViewController : UITableViewController{
    
    var keyManager: TkKeyManager?;
    var userManager: TkUserManager?;
    var bleLockManager: TkBleLockManager?;
    var commandExecutionFacade: TkCommandExecutionFacade?;
    var configManager: TkConfigManager?;
    
    var observer: TkObserver<Void>?;
    var keyObserverRegistration: TkObserverRegistration?;
    
    var bluetoothObserver: TkObserver<AnyObject>?;
    var bluetoothObserverRegistration: TkObserverRegistration?;
    
    var bluetoothStateObserver: TkObserver<NetTpkyMcModelBluetoothState>?;
    var bluetoothStateObserverRegistration: TkObserverRegistration?;
    
    var scanInProgress: Bool = false;
    var keys: [NetTpkyMcModelWebviewCachedKeyInformation] = [];

    
    override func viewDidLoad() {
     
        let app:AppDelegate = UIApplication.shared.delegate as! AppDelegate;
        let tapkeyServiceFactory:TapkeyServiceFactory = app.getTapkeyServiceFactory();
        self.keyManager = tapkeyServiceFactory.getKeyManager();
        self.userManager = tapkeyServiceFactory.getUserManager();
        self.bleLockManager = tapkeyServiceFactory.getBleLockManager();
        self.commandExecutionFacade = tapkeyServiceFactory.getCommandExecutionFacade();
        self.configManager = tapkeyServiceFactory.getConfigManager();
        
        self.observer = TkObserver({ (aVoid:Void?) in self.reloadLocalKeys() })
        self.bluetoothObserver = TkObserver({ (any:AnyObject?) in self.refreshView(); });
        self.bluetoothStateObserver = TkObserver({ (newBluetoothState: NetTpkyMcModelBluetoothState?) in
        
            let bluetoothState:NetTpkyMcModelBluetoothState = newBluetoothState ?? NetTpkyMcModelBluetoothState.no_BLE();
            
            /*
             * When bluetooth is enabled and scan not in progress yet, start scan
             */
            if (!self.scanInProgress && bluetoothState == NetTpkyMcModelBluetoothState.bluetooth_ENABLED()){
                
                self.scanInProgress = true;
                self.bleLockManager!.startForegroundScan();
                
            /*
             * Whe bluetooth is not enabled and scan in progress, stop scan
             */
            } else if (self.scanInProgress && bluetoothState != NetTpkyMcModelBluetoothState.bluetooth_ENABLED()){
                
                self.bleLockManager!.stopForegroundScan();
                self.scanInProgress = false;
                
            }
            
            self.refreshView();

        
        });

        NotificationCenter.default.addObserver(self, selector: #selector(KeyChainViewController.viewInForeground), name:NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(KeyChainViewController.viewInBackground), name:NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
        

    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.viewInForeground();
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.viewInBackground();
    }
    
    @objc private func viewInForeground() {
        
        if(self.keyObserverRegistration == nil){
            self.keyObserverRegistration = self.keyManager!.getKeyUpdateObserveable().addObserver(self.observer!);
        }
        
        if(self.bluetoothObserverRegistration == nil){
            self.bluetoothObserverRegistration = self.bleLockManager!.getLocksChangedObservable().addObserver(self.bluetoothObserver!);
        }
        
        if(self.bluetoothStateObserverRegistration == nil){
            self.bluetoothStateObserverRegistration = self.configManager!.observerBluetoothState().addObserver(self.bluetoothStateObserver!);
        }

        // Start scan, if not in progress and bluetooth is enabled
        if(!self.scanInProgress){
            if(self.configManager?.getBluetoothState() == NetTpkyMcModelBluetoothState.bluetooth_ENABLED()){
                self.scanInProgress = true;
                self.bleLockManager!.startForegroundScan();
            }
        }
        
        reloadLocalKeys();
    }
    
    @objc private func viewInBackground() {

        
        
        if(self.keyObserverRegistration != nil){
            keyObserverRegistration!.close();
            keyObserverRegistration = nil;
        }
        
        if(self.bluetoothObserverRegistration != nil){
            self.bluetoothObserverRegistration!.close();
            self.bluetoothObserverRegistration = nil;
        }
        
        if(self.bluetoothStateObserverRegistration != nil){
            self.bluetoothStateObserverRegistration!.close();
            self.bluetoothStateObserverRegistration = nil;
        }

        if(self.scanInProgress){
            self.bleLockManager!.stopForegroundScan();
            self.scanInProgress = false;
        }
    }
    
    
    
    private func reloadLocalKeys() {
        
        // We only support a single user today, so the first user is the only user.
        guard let user = self.userManager!.getFirstUser() else {
            NSLog("No User is signed in")
            return;
        }
        
        self.keyManager!.queryLocalKeysAsync(user: user, forceUpdate: false, cancellationToken: TkCancellationToken_None)
            .continueOnUi { (keys: [NetTpkyMcModelWebviewCachedKeyInformation]?) -> Void in
                
                self.keys = keys ?? [];
                self.refreshView();
                
            }.catchOnUi { (e:NSException?) in

                NSLog("Query local keys failed. \(String(describing: e?.reason))");
                
            }.conclude();
    }

    private func refreshView() {
        NSLog("Refresh view");
        self.tableView.reloadData();
    }
    
    private func triggerLock(physicalLockId: String) -> TkPromise<Bool> {
        return self.bleLockManager!.executeCommandAsync(deviceIds: [], physicalLockId: physicalLockId, commandFunc: { (tlcConnection: NetTpkyMcTlcpTlcpConnection?) -> TkPromise<NetTpkyMcModelCommandResult> in
            return self.commandExecutionFacade!.triggerLockAsync(tlcConnection, cancellationToken: TkCancellationToken_None)
        }, cancellationToken: TkCancellationToken_None)
        .continueOnUi({ (commandResult: NetTpkyMcModelCommandResult?) -> Bool in
                
            let code: NetTpkyMcModelCommandResult_CommandResultCode = commandResult?.getCode() ?? NetTpkyMcModelCommandResult_CommandResultCode.technicalError();
            
            switch(code) {
                    
                case NetTpkyMcModelCommandResult_CommandResultCode.ok():
                    return true;
                    
                default:
                    return false;
                
            }
                
        })
        .catchOnUi({ (e:NSException?) -> Bool in
            NSLog("Trigger lock failed");
            return false;
        });
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.keys.count;
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell:KeyItemTableCell = tableView.dequeueReusableCell(withIdentifier:"KeyItem", for: indexPath) as! KeyItemTableCell
        
        let key = self.keys[indexPath.row]
        let physicalLockId: String = key.getGrant().getBoundLock().getPhysicalLockId();
        let isLockNearby:Bool = self.bleLockManager!.isLockNearby(physicalLockId: physicalLockId)
        
        cell.setKey(key, nearby: isLockNearby, triggerFn: { () -> TkPromise<Bool> in
            return self.triggerLock(physicalLockId: physicalLockId);
        });
        
        return cell
    }


}
