# HyperTrace SDK

This repository contains the iOS SDK for the BlueTrace protocol.

## Installation

Using Swift Package Manager is the easiest way to install the SDK.

1. Go to Package Dependencies in your Xcode project.
2. Enter the URL of this repository: https://github.com/hyperjumptech/hypertrace-ios-sdk

## App Requirements

Your app needs to have [Background Modes Capability](https://developer.apple.com/documentation/xcode/configuring-background-execution-modes) enabled for the following modes:

1. Uses Bluetooth LE accessories.
2. Acts as a Bluetooth LE accessory.
3. Remote notification.

Please also add `Privacy - Bluetooth Peripheral Usage Description` and `Privacy - Bluetooth Always Usage Description` in the Info.plist.

You also need to have a [Hypertrace server](https://github.com/hyperjumptech/hypertrace) running.

## Usage

Before the tracing started, you need to initialize the SDK by getting the handshake PIN.

```swift
import HyperTraceSDK

HyperTrace.shared(baseUrl: "the_url_of_hypertrace_server", uid: "unique_id_to_identify_the_device_or_user")
     .getHandshakePIN { [weak self]  error, pin in
        // After the handshake PIN is fetched, keep it somewhere safe.
        // At this point, the tracing will start automatically.
     }
```

To upload the encounters data, call the `upload` function.

```swift
import HyperTraceSDK

// code is a security string given by authority
HyperTrace.shared().upload(code: code) { [weak self] error in
    guard error == nil else {
        // show error alert or something
        return
    }

    // at this point, you can show success message or something
}
```

For debugging purpose, you can observe the encounter logs by getting the [NSFetchedResultsController](https://developer.apple.com/documentation/coredata/nsfetchedresultscontroller) instance.

```swift
import HyperTraceSDK
import CoreData

class LogViewController: UITableViewController {
  var fetchedResultsController: NSFetchedResultsController<Encounter>?


  override func viewDidLoad() {
    super.viewDidLoad()

    self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Upload", style: .plain, target: self, action: #selector(addTapped))

    // get the NSFetchedResultsController instance from HyperTrace SDK
    fetchedResultsController = HyperTrace.shared().getFetchedResultsController(delegate: self)
  }


  override func viewWillAppear(_ animated: Bool) {
    do {
      // start fetching and listening to the encounters
      try fetchedResultsController?.performFetch()
    } catch let error as NSError {
      print("Could not perform fetch. \(error), \(error.userInfo)")
    }
  }
}
```

For a working example, see the [HyperTrace Sample app](https://github.com/hyperjumptech/hypertrace-ios-sdk-sample).

## License

GNU General Public License v3.0
