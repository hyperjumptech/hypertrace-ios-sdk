//
//  File.swift
//  
//
//  Created by Nico Prananta on 21.03.22.
//

import Foundation
import CoreBluetooth


/**
 A subclass of CBPeripheralManager for helping with test.
 */
class TestablePeripheralManager: CBPeripheralManager {
  var _result: CBATTError.Code?
  var _request: CBATTRequest?
  
  override func respond(to request: CBATTRequest, withResult result: CBATTError.Code) {
    _result = result
    _request = request
  }
}

/**
 A subclass of CBUUID for helping with test.
 */
class TestableCBUUID: CBUUID {
  var _uuidString: String = ""
  
  override var uuidString: String {
    return _uuidString
  }
}

/**
 A subclass of CBCharacteristic for helping with test.
 */
class TestableCBCharacteristic: CBCharacteristic {
  var _uuid: TestableCBUUID = TestableCBUUID()
  var _value: Data?
  
  override var uuid: CBUUID {
    return _uuid
  }
  
  override var value: Data? {
    return _value
  }
}

/**
 A subclass of CBATTRequest for helping with test.
 */
class TestableCBATTRequest: CBATTRequest {
  var _offset: Int = 1
  var _central: CBCentral
  var _characteristic: CBCharacteristic
  
  override var offset: Int {
    return _offset
  }
  
  override var central: CBCentral {
    return _central
  }
  
  override var characteristic: CBCharacteristic {
    return _characteristic
  }
}

/**
 A subclass of CBPeripheral for helping with test. 
 */
class TestableCBPeripheral: CBPeripheral {
  var _uuid: UUID = UUID()
  
  override var identifier: UUID {
    return _uuid
  }
}
