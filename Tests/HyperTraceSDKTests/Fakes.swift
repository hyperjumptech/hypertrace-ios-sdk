//
//  File.swift
//  
//
//  Created by Nico Prananta on 21.03.22.
//

import Foundation
import CoreBluetooth


/**
 A subclass of CBPeripheralManager for helping with test
 */
class FakePeripheralManager: CBPeripheralManager {
  var _result: CBATTError.Code?
  var _request: CBATTRequest?
  
  override func respond(to request: CBATTRequest, withResult result: CBATTError.Code) {
    _result = result
    _request = request
  }
}

/**
 A subclass of CBUUID for helping with test
 */
class FakeCBUUID: CBUUID {
  var _uuidString: String = ""
  
  override var uuidString: String {
    return _uuidString
  }
}

/**
 A subclass of CBCharacteristic for helping with test
 */
class FakeCBCharacteristic: CBCharacteristic {
  var _uuid: FakeCBUUID = FakeCBUUID()
  
  override var uuid: CBUUID {
    return _uuid
  }
}

/**
 A subclass of CBATTRequest for helping with test
 */
class FakeCBATTRequest: CBATTRequest {
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
