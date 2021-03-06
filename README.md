# HyperTrace SDK

![HyperTraceSDK](https://github.com/hyperjumptech/hypertrace-ios-sdk/actions/workflows/test.yml/badge.svg)

This repository contains the iOS SDK for the [BlueTrace protocol](https://bluetrace.io/static/bluetrace_whitepaper-938063656596c104632def383eb33b3c.pdf).

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

### Setting configuration

#### Interval of the scanning

By default, the SDK will scan nearby devices every 60 seconds. You can change this value by calling the following function.

```swift
HyperTrace.setScanningInterval(10) // set the interval every 10 seconds.
```

#### Duration of the scanning

By default, the SDK will scan nearby devices for 10 seconds each time. You can change this value by calling the following function.

```swift
HyperTrace.setScanningDuration(5) // set the duration to 5 seconds.
```

#### Service ID

To set the service ID, add a key in Info.plist called `TRACER_SVC_ID`.

#### Characteristic ID

To set the characteristic ID, add a key in Info.plist called `V2_CHARACTERISTIC_ID`.

#### Organization

To set the organization ID, add a key in Info.plist called `TRACER_ORG`.

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

#### Upload Timeout

Under the hood, the SDK uses [URLSession](https://developer.apple.com/documentation/foundation/urlsession) with the [default configuration](https://developer.apple.com/documentation/foundation/urlsessionconfiguration), which sets the [request timeout to 60 seconds](https://developer.apple.com/documentation/foundation/urlsessionconfiguration/1408259-timeoutintervalforrequest). To change this value, you need to pass your custom session configuration when calling the `start` function as follows.

```swift
import HyperTraceSDK

let configuration = URLSessionConfiguration.default
configuration.timeoutIntervalForRequest = 1000 // in seconds

HyperTrace
  .shared()
  .start(baseUrl: "hypertrace-server-url-here",
         uid: UserDefaults.standard.string(forKey: "userId")!,
         sessionConfiguration: configuration)
```

### Stop Tracing

To stop the tracing, call the `stop` function.

```swift
HyperTrace.shared().stop()
```

### Data Clean Up

To prevent excessive amount of encounter data stored in the device, your app needs to call `removeData` function from time to time. It's better to call this function when your app enters foreground.

```swift
HyperTrace.removeData()
```

By default, that function will delete all encounters which are **older** than 21 days. You can change the cut off time as follows

```swift
HyperTrace.removeData(olderThan: 10, unit: .day) // Remove all encounters which are older than 10 days ago
```

### Number of Encounters Data

You can get the number of encounters saved in the device as follows

```swift
let encountersCount = HyperTrace.countEncounters() // The default. Get the number of all encounters which are older than 21 days ago
let encountersCount2 = HyperTrace.countEncounters(olderThan: 1, unit: .minute) // Get the number of all encounters which are older than 1 minute ago
let encountersCount3 = HyperTrace.countEncounters(inTheLast: 1, unit: .minute) // Get the number of all encounters in the last 1 minute
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

## Linting

This project uses [SwiftFormat](https://github.com/nicklockwood/SwiftFormat) to format and lint the swift files. The GitHub Actions workflow will lint the swift files before running the tests. To lint the swift files locally, run the following command.

```shell
swiftformat --lint Sources
```

To format your swift files, run the following command.

```shell
swiftformat Sources
```

## Testing

The tests can be run either from the Xcode, or from the Terminal using the following command

```shell
# Run the tests and generate coverage
xcodebuild -scheme HyperTraceSDK -enableCodeCoverage YES -derivedDataPath build/ clean build test -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 12 Pro'
# Show the compact coverage result in the terminal
xcrun xccov view --report --only-targets ./build/Logs/Test/*.xcresult
```

## License

GNU General Public License v3.0
