import TapkeyMobileLib
import UIKit
import RxSwift

class KeyChainViewController: UITableViewController {

    var keyManager: TKMKeyManager!
    var userManager: TKMUserManager!
    var bleLockScanner: TKMBleLockScanner!
    var bleLockCommunicator: TKMBleLockCommunicator!
    var commandExecutionFacade: TKMCommandExecutionFacade!

    var keyObserverRegistration: TKMObserverRegistration?
    var bluetoothObserverRegistration: TKMObserverRegistration?
    var scanRegistration: TKMObserverRegistration?

    var sampleServerManager: SampleServerManager!

    var listItems: [(TKMKeyDetails, ApplicationGrant)] = []

    override func viewDidLoad() {
        let app: AppDelegate = UIApplication.shared.delegate as! AppDelegate
        let tapkeyServiceFactory: TKMServiceFactory = app.getTapkeyServiceFactory()
        self.keyManager = tapkeyServiceFactory.keyManager
        self.userManager = tapkeyServiceFactory.userManager
        self.bleLockScanner = tapkeyServiceFactory.bleLockScanner
        self.bleLockCommunicator = tapkeyServiceFactory.bleLockCommunicator
        self.commandExecutionFacade = tapkeyServiceFactory.commandExecutionFacade

        self.sampleServerManager = SampleServerManager()

        NotificationCenter.default.addObserver(self, selector: #selector(KeyChainViewController.viewInForeground),
                name: UIApplication.willEnterForegroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(KeyChainViewController.viewInBackground),
                name: UIApplication.didEnterBackgroundNotification, object: nil)
    }

    override func viewDidAppear(_ animated: Bool) {
        self.viewInForeground()
    }

    override func viewWillDisappear(_ animated: Bool) {
        self.viewInBackground()
    }

    @objc private func viewInForeground() {

        if self.keyObserverRegistration == nil {
            self.keyObserverRegistration = self.keyManager?.keyUpdateObservable.addObserver({ _ in
                self.reloadLocalKeys()
            })
        }

        if self.bluetoothObserverRegistration == nil {
            self.bluetoothObserverRegistration = self.bleLockScanner.observable.addObserver({ _ in
                self.refreshView()
            })
        }

        // Start scan, if not already in progress
        if self.scanRegistration == nil {
            self.scanRegistration = self.bleLockScanner!.startForegroundScan()
        }

        reloadLocalKeys()
    }

    @objc private func viewInBackground() {

        if self.keyObserverRegistration != nil {
            keyObserverRegistration!.close()
            keyObserverRegistration = nil
        }

        if self.bluetoothObserverRegistration != nil {
            self.bluetoothObserverRegistration!.close()
            self.bluetoothObserverRegistration = nil
        }

        if self.scanRegistration != nil {
            self.scanRegistration!.close()
            self.scanRegistration = nil
        }
    }

    private func reloadLocalKeys() {

        // This sample app assumes only one user is logged in at a time
        if self.userManager.users.count < 1 {
            NSLog("No User is signed in")
            return
        }
        let userId = self.userManager.users[0]

        self.keyManager!.queryLocalKeysAsync(
                        userId: userId,
                        cancellationToken: TKMCancellationTokens.None)
            .continueOnUi { keyDetails in

                guard let keys = keyDetails, keys.count > 0 else {
                    NSLog("No local keys available")
                    self.listItems = []
                    self.refreshView()
                    return
                }

                _ = self.getApplicationGrantsForKeyDetails(keyDetails: keys)
                        .subscribe(onNext: { (keysWithGrants) in
                            self.listItems = keysWithGrants
                            self.refreshView()
                        }, onError: { (error) in
                            NSLog("""
                                  Error while retrieving application grants for local keys:
                                   \(String(describing: error))
                                  """)
                            self.listItems = []
                            self.refreshView()
                        })

            }.catchOnUi { (error: TKMAsyncError) in
                NSLog("Query local keys failed. \(String(describing: error))")
                self.listItems = []
                self.refreshView()
                return nil
            }.conclude()
    }

    private func refreshView() {
        NSLog("Refresh view")
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }

    /**
     * Retrieves grants for the given local keys from the sample server. These domain-specific grants contain additional
     * metadata about the grant.
     */
    private func getApplicationGrantsForKeyDetails(
            keyDetails: [TKMKeyDetails]) -> Observable<[(TKMKeyDetails, ApplicationGrant)]> {

        if let username = SampleAuthStateManager.getUsername(), let password = SampleAuthStateManager.getPassword() {
            let grantIds = keyDetails.map({ (keyDetails) -> String in keyDetails.grantId })
            return self.sampleServerManager.getGrants(username: username, password: password, grantIds: grantIds)
                    .map({ (applicationGrants: [ApplicationGrant]) -> [(TKMKeyDetails, ApplicationGrant)] in
                        keyDetails.map({ (key) -> (TKMKeyDetails, ApplicationGrant?) in
                            if let grant = applicationGrants.first(where: { $0.id == key.grantId }) {
                                return (key, grant)
                            } else {
                                return (key, nil)
                            }
                        }).compactMap({
                            guard let grant = $0.1 else {
                                return nil
                            }
                            return ($0.0, grant)
                        })
                    })
        } else {
            NSLog("Cannot obtain sample server user information during local key reload.")
            return Observable.error(KeyChainError.notAuthenticatedDuringKeyReload)
        }
    }

    /**
     * This method contains the core logic for triggering a Tapkey lock. It takes a lock's physical lock ID and returns
     * a Promise that will resolve once the command has completed successfully, or resolve to an error if not.
     *
     * As a first step, the corresponding Bluetooth address is looked up for the given physical lock ID. The BLE lock
     * scanner provides such functionality.
     * Afterwards, the BLE lock communicator is used to establish a connection to the lock. The resulting TLCP
     * connection is then passed to the command execution facade, which will execute the actual trigger lock command.
     *
     * Please note that in a production-grade scenario, the implementing application will have to provide proper
     * cancellation mechanisms and handle errors.
     *
     * - Parameters:
     *    - physicalLockId: The lock's physical lock ID as a Base64-encoded string. More information on this topic can
     *                      be found here: https://developers.tapkey.io/mobile/concepts/lock_ids/
     */
    private func triggerLock(physicalLockId: String) -> TKMPromise<Bool> {
        guard let bluetoothAddress = self.bleLockScanner.getLock(
                physicalLockId: physicalLockId)?.bluetoothAddress else {
            NSLog("Lock not nearby")
            return TKMAsync.promiseFromResult(false)
        }

        let ct = TKMCancellationTokens.fromTimeout(timeoutMs: 15000)

        // Use the BLE lock communicator to send a command to the lock
        return self.bleLockCommunicator.executeCommandAsync(
                        bluetoothAddress: bluetoothAddress,
                        physicalLockId: physicalLockId,
                        commandFunc: { tlcpConnection -> TKMPromise<TKMCommandResult> in

                            let triggerLockCommand = TKMDefaultTriggerLockCommandBuilder()
                                .build()

                            // Pass the TLCP connection to the command execution facade
                            return self.commandExecutionFacade!.executeStandardCommandAsync(tlcpConnection, command: triggerLockCommand, cancellationToken: ct)
                        },
                        cancellationToken: ct)

            // Process the command's result
            .continueOnUi({ commandResult in
                let code: TKMCommandResult.TKMCommandResultCode = commandResult?.code ??
                        TKMCommandResult.TKMCommandResultCode.technicalError

                switch code {
                case TKMCommandResult.TKMCommandResultCode.ok:
                    return true
                default:
                    return false
                }
            })
            .catchOnUi({ (_: TKMAsyncError) -> Bool in
                NSLog("Trigger lock failed")
                return false
            })
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.listItems.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell: KeyItemTableCell = tableView.dequeueReusableCell(
                withIdentifier: "KeyItem",
                for: indexPath) as! KeyItemTableCell
        let keyWithGrant = self.listItems[indexPath.row]

        if let physicalLockId: String = keyWithGrant.1.physicalLockId {
            let isLockNearby: Bool = self.bleLockScanner!.isLockNearby(physicalLockId: physicalLockId)
            cell.setKey(keyWithGrant, nearby: isLockNearby, triggerFn: { () -> TKMPromise<Bool> in
                self.triggerLock(physicalLockId: physicalLockId)
            })
        } else {
            cell.setKey(keyWithGrant,
                    nearby: false,
                    triggerFn: { () -> TKMPromise<Bool> in TKMAsync.promiseFromResult(false) })
        }

        return cell
    }

    enum KeyChainError: Error {
        case notAuthenticatedDuringKeyReload
    }

}
