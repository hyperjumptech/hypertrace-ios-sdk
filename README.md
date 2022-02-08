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

### Initialization

Before the tracing started, you need to initialize the SDK and call the `start` function.

```swift
import HyperTraceSDK

HyperTrace
  .shared()
  .start(baseUrl: "hypertrace-server-url-here",
         uid: UserDefaults.standard.string(forKey: "userId")!)
```

### Data Upload

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

### Data Clean Up

To prevent excessive amount of encounter data stored in the device, your app needs to call `removeData` function from time to time. It's better to call this function when your app enters foreground.

```swift
HyperTrace.removeData()
```

By default, that function will delete data older than 21 days. You can change the cut off time as follows

```swift
HyperTrace.removeData(olderThan: 10, unit: .day)
```

### Number of Encounters Data

You can get the number of encounters saved in the device as follows

```swift
let encountersCount = HyperTrace.countEncounters() // get the number of encounters older than 21 days ago
let encountersCount2 = HyperTrace.countEncounters(olderThan: 1, unit: .minute) // get the number of encounters older than 1 minute ago
```

### Debugging

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
