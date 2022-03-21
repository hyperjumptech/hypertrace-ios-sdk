import CoreData

public class HyperTrace {
  private static var sharedInstance: HyperTrace?
  
  /// The requirements for this SDK.
  public var requirements: HyperTraceRequirements = HyperTraceRequirements()
  
  /// Returns the singleton of this SDK.
  /// - Returns: An instance of HyperTrace.
  public static func shared() -> HyperTrace {
    if sharedInstance == nil {
      sharedInstance = HyperTrace()
    }
    return sharedInstance!
  }
  
  lazy var persistentContainer: NSPersistentContainer = {
    /*
     The persistent container for the application. This implementation
     creates and returns a container, having loaded the store for the
     application to it. This property is optional since there are legitimate
     error conditions that could cause the creation of the store to fail.
     */
    guard let modelURL = Bundle.module.url(forResource:"tracer", withExtension: "momd") else {
      fatalError("Cannot find tracer model")
    }
    guard let model = NSManagedObjectModel(contentsOf: modelURL) else {
      fatalError("Cannot create NSManagedObjectModel")
    }
    let container = NSPersistentContainer(name:"tracer", managedObjectModel:model)
    container.loadPersistentStores(completionHandler: { (_, error) in
      if let error = error as NSError? {
        // Replace this implementation with code to handle the error appropriately.
        
        /*
         Typical reasons for an error here include:
         * The parent directory does not exist, cannot be created, or disallows writing.
         * The persistent store is not accessible, due to permissions or data protection when the device is locked.
         * The device is out of space.
         * The store could not be migrated to the current model version.
         Check the error message to determine what the actual problem was.
         */
        fatalError("Unresolved error \(error), \(error.userInfo)")
      }
    })
    return container
  }()
  
  public init() {}
  
  
  /// Starts the tracing process.
  /// - Parameters:
  ///   - baseUrl: The base URL of HyperTrace server.
  ///   - uid: The unique ID of the user.
  ///   - sessionConfiguration: An optional instance of URLSessionConfiguration for the network calls.
  public func start(baseUrl: String, uid: String = "", sessionConfiguration: URLSessionConfiguration? = nil) {
    let _ = API.shared(baseUrl: baseUrl, sessionConfiguration: sessionConfiguration)
    self.setIdentity(uid)
    DatabaseManager.shared().persistentContainer = self.persistentContainer
    EncounterMessageManager.shared.setup()
    BlueTraceLocalNotifications.shared.initialConfiguration()
    BluetraceManager.shared.turnOn()
  }
  
  
  /// Stops the tracing.
  public func stop() {
    BluetraceManager.shared.turnOff()
    BlueTraceLocalNotifications.shared.removePendingNotificationRequests()
  }
  
  
  /// Checks whether the tracing is running.
  /// - Returns: If true, the tracing is currently running.
  public func isTracing() -> Bool {
    return BluetraceManager.shared.getCentralState() == .poweredOn || BluetraceManager.shared.getPeripheralState() == .poweredOn
  }
  
  
  /// Returns the NSFetchedResultsController which can be used for debugging.
  /// - Parameter delegate: The delegate for the NSFetchedResultsController instance.
  /// - Returns: An instance of the NSFetchedResultsController.
  public func getFetchedResultsController(delegate: NSFetchedResultsControllerDelegate?) -> NSFetchedResultsController<Encounter> {
    let managedContext = persistentContainer.viewContext
    let fetchRequest = NSFetchRequest<Encounter>(entityName: "Encounter")
    let sortByDate = NSSortDescriptor(key: "timestamp", ascending: false)
    fetchRequest.sortDescriptors = [sortByDate]
    let fetchedResultsController = NSFetchedResultsController<Encounter>(fetchRequest: fetchRequest, managedObjectContext: managedContext, sectionNameKeyPath: nil, cacheName: nil)
    fetchedResultsController.delegate = delegate
    return fetchedResultsController
  }
  
  
  /// Sets the identity of the user.
  /// - Parameter identity: The unique identifier to identify the user.
  public func setIdentity (_ identity: String) {
    API.shared().uid = identity
  }
  
  
  /// Upload the encounters to HyperTrace server.
  /// - Parameters:
  ///   - code: The upload token.
  ///   - onComplete: The callback that will be called when the upload is finished.
  public func upload(code: String, onComplete: ( (Error?) -> Void )?) {
    API.shared().getUploadToken(code: code) { error, token in
      if error != nil {
        onComplete?(error)
        return
      }
      
      guard let uploadToken = token else {
        onComplete?(NSError(domain: "HyperTraceSDK", code: 404, userInfo: [
          NSLocalizedDescriptionKey: "Cannot get upload token"
        ]))
        return
      }
      
      self.getUploadData { getUploadDataError, encounters in
        if getUploadDataError != nil {
          onComplete?(getUploadDataError)
          return
        }
        guard let traces = encounters else {
          onComplete?(NSError(domain: "HyperTraceSDK", code: 404, userInfo: [
            NSLocalizedDescriptionKey: "Cannot get encounters"
          ]))
          return
        }
        API.shared().uploadData(token: uploadToken, traces: traces) { uploadError, uploadStatus in
          if uploadError != nil {
            onComplete?(uploadError)
            return
          }
          
          onComplete?(nil)
        }
      }
    }
  }
}

extension HyperTrace {
  
  /// Queries the local database and returns the encounters to be uploaded.
  /// - Parameter onComplete: The callback that is called when the queried encounters are ready.
  func getUploadData ( onComplete: ((Error?, [Encounter]? ) -> Void)? ) {
    let managedContext = persistentContainer.viewContext
    let recordsFetchRequest: NSFetchRequest<Encounter> = Encounter.fetchRequestForRecords()
    
    managedContext.perform {
      do {
        let records = try recordsFetchRequest.execute()
        onComplete?(nil, records)
      } catch {
        Logger.DLog("Error fetching records")
        onComplete?(error, nil)
      }
    }
  }
}

extension HyperTrace {
  
  /// Remove encounters from local database.
  /// - Parameters:
  ///   - olderThan: The value of cut off date.
  ///   - unit: The unit of time.
  public static func removeData(olderThan: Int = BluetraceConfig.TTLDays, unit: Calendar.Component = .day) {
    BluetraceUtils.removeData(olderThan: olderThan, unit: unit)
  }
  
  
  /// Returns the number of encounters older than the given time.
  /// - Parameters:
  ///   - olderThan: The value of the time.
  ///   - unit: The unit of the time.
  /// - Returns: The number of encounters.
  public static func countEncounters(olderThan: Int = BluetraceConfig.TTLDays, unit: Calendar.Component = .day) -> Int {
    return BluetraceUtils.countEncounters(olderThan: olderThan, unit: unit)
  }
  
  
  /// Returns the number of recent encounters.
  /// - Parameters:
  ///   - inTheLast: The value of the minimum time.
  ///   - unit: The unit of the time.
  /// - Returns: The number of encounters.
  public static func countEncounters(inTheLast: Int = BluetraceConfig.TTLDays, unit: Calendar.Component = .day) -> Int {
    return BluetraceUtils.countEncounters(inTheLast: inTheLast, unit: unit)
  }
}

extension HyperTrace {
  /// Sets the interval of the scanning.
  /// - Parameter interval: The desired interval in seconds.
  public static func setScanningInterval (_ interval: Int) {
    guard interval > 0 else { return }
    BluetraceConfig.CentralScanInterval = interval
  }
  
  
  /// Sets the duration of the scanning.
  /// - Parameter duration: The desired duration in seconds.
  public static func setScanningDuration (_ duration: Int) {
    guard duration > 0 else { return }
    BluetraceConfig.CentralScanDuration = duration
  }
}

#if DEBUG
extension HyperTrace {
  public static func getSession () -> URLSession? {
    return API.shared().session
  }
}
#endif

public struct HyperTraceRequirements {
  var bleAuthorized: Bool = false
  var blePoweredOn: Bool = false
}
