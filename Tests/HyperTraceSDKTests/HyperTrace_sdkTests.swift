import XCTest
@testable import HyperTraceSDK
import CoreBluetooth

final class HyperTraceSDKTests: XCTestCase {
  override func setUp() {
    BluetraceUtils.removeAllEncounters()
  }
  
  func testInit() throws {
    let hyperTrace = HyperTrace.shared()
    XCTAssertNotNil(hyperTrace)
    XCTAssertNotNil(hyperTrace.persistentContainer)
  }
  
  func testSession() throws {
    let hyperTrace = HyperTrace.shared()
    let configuration = URLSessionConfiguration.default
    configuration.timeoutIntervalForRequest = 1000
    
    // start the hypertrace with custom session configuration
    hyperTrace.start(baseUrl: "http://localhost:3000", uid: "hello", sessionConfiguration: configuration)
    
    let session = HyperTrace.getSession()
    XCTAssertNotNil(session)
    XCTAssertEqual(session?.configuration.timeoutIntervalForRequest, 1000)
  }
  
  func testCountEncounterRecordOlderThan() throws {
    // create an EncounterRecord
    let encounter = EncounterRecord(rssi: -20, txPower: 20)
    XCTAssertNotNil(encounter)
    
    // save the encounter to database
    encounter.saveToCoreData()
    
    let expectation = XCTestExpectation(description: "Wait for saveToCoreData")
    
    // wait for a second so that the saving finishes
    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
      // count the number of records in database,
      // and assert it's 1
      XCTAssertEqual(HyperTrace.countEncounters(olderThan: -1, unit: .second), 1)
      expectation.fulfill()
    }
    
    wait(for: [expectation], timeout: 3.0)
  }
  
  func testCountEncounterRecordInTheLast() throws {
    // create an EncounterRecord
    let encounter = EncounterRecord(rssi: -20, txPower: 20)
    XCTAssertNotNil(encounter)
    
    // save the encounter to database
    encounter.saveToCoreData()
    
    // create an older EncounterRecord
    let fiveMinutesAgo = Calendar.current.date(byAdding: .minute, value: -5, to: Date())
    let encounter2 = EncounterRecord(rssi: -20, txPower: 20, timestamp: fiveMinutesAgo)
    XCTAssertNotNil(encounter2)
    
    // save the encounter to database
    encounter2.saveToCoreData()
    
    let expectation = XCTestExpectation(description: "Wait for saveToCoreData")
    
    // wait for a second so that the saving finishes
    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
      // count the number of records in database,
      // and assert it's 1
      XCTAssertEqual(HyperTrace.countEncounters(inTheLast: 1, unit: .minute), 1)
      expectation.fulfill()
    }
    
    wait(for: [expectation], timeout: 3.0)
  }
  
  func testDeleteOldEncounter() {
    // create a Date which is 5 minutes ago
    let fiveMinutesAgo = Calendar.current.date(byAdding: .minute, value: -5, to: Date())
    
    // create an EncounterRecord with the timestamp
    let encounter = EncounterRecord(rssi: -20, txPower: 20, timestamp: fiveMinutesAgo)
    
    // save it to core data
    encounter.saveToCoreData()
    
    // create a Date which is 30 seconds ago
    let thirtySecsAgo = Calendar.current.date(byAdding: .second, value: -30, to: Date())
    
    // create an EncounterRecord with the timestamp
    let encounter2 = EncounterRecord(rssi: -20, txPower: 20, timestamp: thirtySecsAgo)
    
    // save it to core data
    encounter2.saveToCoreData()
    
    let expectation = XCTestExpectation(description: "Wait for delete")
    
    // wait until saving finishes
    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
      // now let's actually try deleting records older than 2 minutes ago.
      HyperTrace.removeData(olderThan: 2, unit: .minute)
      
      DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
        // there should be 1 record left after deleting records older than 1 minute ago
        XCTAssertEqual(HyperTrace.countEncounters(olderThan: -1, unit: .second), 1)
        expectation.fulfill()
      }
    }
    
    wait(for: [expectation], timeout: 3.0)
  }
  
  func testPeripheralControllerReceiveWrite() {
    // create the PeripheralController instance that will be tested
    let peripheralController = PeripheralController(peripheralName: "test", queue: .main)
    
    // create Testable CBPeripheralManager
    let manager = TestablePeripheralManager()
    
    // create Testable CBCharacteristic. We cannot call the init method because init function of CBCharacteristic is unavailable. The following is a workaround.
    let characteristic = TestableCBCharacteristic.perform(NSSelectorFromString("new")).takeRetainedValue() as! TestableCBCharacteristic
    let TestableCBUUID = TestableCBUUID()
    TestableCBUUID._uuidString = "hello"
    characteristic._uuid = TestableCBUUID
    
    // create the data that will be received
    let data = """
      {
        "mc": "iPhone 13",
        "rs": 100,
        "id": "abcd",
        "o": "Hyperjump",
        "v": 2
      }
    """
    
    // create Testable CBATTRequest
    let request = TestableCBATTRequest.perform(NSSelectorFromString("new")).takeRetainedValue() as! TestableCBATTRequest
    request.value = data.data(using: .utf8)
    request._offset = 2
    request._characteristic = characteristic
    
    XCTAssertNotNil(request)
    XCTAssertNotNil(request.value)
    XCTAssertEqual(request.offset, 2)
    
    // start testing peripheralManager(:didReceiveWrite:) function
    peripheralController.peripheralManager(manager, didReceiveWrite: [request])
    
    // create expectation
    let expectation = XCTestExpectation(description: "Wait for write")
    
    // wait until saving finishes
    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
      // there should be 1 record in the last 3 secods if peripheralManager(:didReceiveWrite:) function succeeds
      XCTAssertEqual(HyperTrace.countEncounters(inTheLast: 3, unit: .second), 1)
      XCTAssertEqual(manager._result, .success)
      expectation.fulfill()
    }
    
    // wait until expectation is fulfilled
    wait(for: [expectation], timeout: 3.0)
  }
  
  func testCentralControllerDidUpdateValue () {
    let peripheral = TestableCBPeripheral.perform(NSSelectorFromString("new")).takeRetainedValue() as! TestableCBPeripheral
    peripheral._uuid = UUID()
    // need to add observer here to solve runtime exception when its instance is dealloced
    peripheral.addObserver(peripheral, forKeyPath: "delegate", options: .new, context: nil)
    
    // create the data that will be received
    let data = """
      {
        "mp": "iPhone 13",
        "id": "abcd",
        "o": "Hyperjump",
        "v": 2
      }
    """
    
    // create Testable CBCharacteristic. We cannot call the init method because init function of CBCharacteristic is unavailable. The following is a workaround.
    let characteristic = TestableCBCharacteristic.perform(NSSelectorFromString("new")).takeRetainedValue() as! TestableCBCharacteristic
    let TestableCBUUID = TestableCBUUID()
    TestableCBUUID._uuidString = "hello"
    characteristic._uuid = TestableCBUUID
    characteristic._value = data.data(using: .utf8)
    
    // create a central manager
    let central = CBCentralManager.perform(NSSelectorFromString("new")).takeRetainedValue() as! CBCentralManager
    
    // create an advertisment data
    let advertismentData = [
      CBAdvertisementDataTxPowerLevelKey: 20
    ]
    
    // create the central controller that will be tested
    let centralController = CentralController(queue: .main)
    
    // let the central controller knows about a new peripheral
    centralController.centralManager(central, didDiscover: peripheral, advertisementData: advertismentData, rssi: NSNumber(value: 10))
    
    // the function to test
    centralController.peripheral(peripheral, didUpdateValueFor: characteristic, error: nil)
    
    // create expectation
    let expectation = XCTestExpectation(description: "Wait for write")
    
    // wait until saving finishes
    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
      // there should be 1 record in the last 3 secods if peripheralManager(:didReceiveWrite:) function succeeds
      XCTAssertEqual(HyperTrace.countEncounters(inTheLast: 3, unit: .second), 1)
      expectation.fulfill()
    }
    
    // wait until expectation is fulfilled
    wait(for: [expectation], timeout: 3.0)
    
    
    
  }
}
