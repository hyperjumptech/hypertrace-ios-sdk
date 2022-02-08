import XCTest
@testable import HyperTraceSDK

final class HyperTraceSDKTests: XCTestCase {
  override func setUp() {
    BluetraceUtils.removeAllEncounters()
  }
  
  func testInit() throws {
    XCTAssertNotNil(HyperTrace.shared())
    XCTAssertNotNil(HyperTrace.shared().persistentContainer)
  }
  
  func testEncounterRecord() throws {
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
}
