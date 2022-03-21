//
//  EncounterRecord.swift
//  OpenTrace

import Foundation

struct EncounterRecord: Encodable {
  var timestamp: Date?
  var msg: String?
  var modelC: String?
  private(set) var modelP: String?
  var rssi: Double?
  var txPower: Double?
  var org: String?
  var v: Int?

  mutating func update(msg: String) {
    self.msg = msg
  }

  mutating func update(modelP: String) {
    self.modelP = modelP
  }

  // This initializer is used when central discovered a peripheral, and need to record down the rssi and txpower, and have not yet connected with the peripheral to get the msg
  init(rssi: Double, txPower: Double?) {
    timestamp = Date()
    msg = nil
    modelC = Device.current.description
    modelP = nil
    self.rssi = rssi
    self.txPower = txPower
    org = nil
    v = nil
  }

  init(rssi: Double, txPower: Double?, timestamp: Date?) {
    self.timestamp = timestamp ?? Date()
    msg = nil
    modelC = Device.current.description
    modelP = nil
    self.rssi = rssi
    self.txPower = txPower
    org = nil
    v = nil
  }

  init(from centralWriteDataV2: CentralWriteDataV2) {
    timestamp = Date()
    msg = centralWriteDataV2.id
    modelC = centralWriteDataV2.mc
    modelP = Device.current.description
    rssi = centralWriteDataV2.rs
    org = centralWriteDataV2.o
    v = centralWriteDataV2.v
  }

  init(msg: String) {
    timestamp = Date()
    self.msg = msg
    modelC = nil
    modelP = nil
    rssi = nil
    txPower = nil
    org = nil
    v = nil
  }
}
