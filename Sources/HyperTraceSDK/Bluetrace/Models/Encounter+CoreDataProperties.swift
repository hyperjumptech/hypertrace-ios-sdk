//
//  Encounter+CoreDataProperties.swift
//  OpenTrace

import CoreBluetooth
import CoreData
import Foundation
import UIKit

public extension Encounter {
  internal enum CodingKeys: String, CodingKey {
    case timestamp
    case msg
    case modelC
    case modelP
    case rssi
    case txPower
    case org
  }

  @nonobjc class func fetchRequest() -> NSFetchRequest<Encounter> {
    return NSFetchRequest<Encounter>(entityName: "Encounter")
  }

  @nonobjc class func fetchRequestForRecords() -> NSFetchRequest<Encounter> {
    let fetchRequest = NSFetchRequest<Encounter>(entityName: "Encounter")
    fetchRequest.predicate = NSPredicate(format: "msg != %@ and msg != %@", Encounter.Event.scanningStarted.rawValue, Encounter.Event.scanningStopped.rawValue)
    fetchRequest.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: true)]
    return fetchRequest
  }

  @nonobjc class func fetchRequestForEvents() -> NSFetchRequest<Encounter> {
    let fetchRequest = NSFetchRequest<Encounter>(entityName: "Encounter")
    fetchRequest.predicate = NSPredicate(format: "msg = %@ or msg = %@", Encounter.Event.scanningStarted.rawValue, Encounter.Event.scanningStopped.rawValue)
    fetchRequest.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: true)]
    return fetchRequest
  }

  @NSManaged var timestamp: Date?
  @NSManaged var msg: String?
  @NSManaged var modelC: String?
  @NSManaged var modelP: String?
  @NSManaged var rssi: NSNumber?
  @NSManaged var txPower: NSNumber?
  @NSManaged var org: String?
  @NSManaged var v: NSNumber?

  internal func set(encounterStruct: EncounterRecord) {
    setValue(encounterStruct.timestamp, forKeyPath: "timestamp")
    setValue(encounterStruct.msg, forKeyPath: "msg")
    setValue(encounterStruct.modelC, forKeyPath: "modelC")
    setValue(encounterStruct.modelP, forKeyPath: "modelP")
    setValue(encounterStruct.rssi, forKeyPath: "rssi")
    setValue(encounterStruct.txPower, forKeyPath: "txPower")
    setValue(encounterStruct.org, forKeyPath: "org")
    setValue(encounterStruct.v, forKeyPath: "v")
  }

  // MARK: - Encodable

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(Int(timestamp!.timeIntervalSince1970), forKey: .timestamp)
    try container.encode(msg, forKey: .msg)

    if let modelC = modelC, let modelP = modelP {
      try container.encode(modelC, forKey: .modelC)
      try container.encode(modelP, forKey: .modelP)
      try container.encode(rssi?.doubleValue ?? 0, forKey: .rssi)
      try container.encode(txPower?.doubleValue ?? 0, forKey: .txPower)
      try container.encode(org, forKey: .org)
    }
  }
}
