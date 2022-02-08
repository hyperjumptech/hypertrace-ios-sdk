//
//  BluetraceUtils.swift
//  OpenTrace

import UIKit
import CoreData
import Foundation
import CoreBluetooth

public class BluetraceUtils {
  static func managerStateToString(_ state: CBManagerState) -> String {
    switch state {
    case .poweredOff:
      return "poweredOff"
    case .poweredOn:
      return "poweredOn"
    case .resetting:
      return "resetting"
    case .unauthorized:
      return "unauthorized"
    case .unknown:
      return "unknown"
    case .unsupported:
      return "unsupported"
    default:
      return "unknown"
    }
  }
  
  static func peripheralStateToString(_ state: CBPeripheralState) -> String {
    switch state {
    case .disconnected:
      return "disconnected"
    case .connecting:
      return "connecting"
    case .connected:
      return "connected"
    case .disconnecting:
      return "disconnecting"
    default:
      return "unknown"
    }
  }
  
  
  /// This function removes data from the beginning up to provided time and unit.  By default the value is 21 days, i.e., olderThan is 21 and the unit is day.
  /// - Parameters:
  ///   - olderThan: the cut off time. Default is 21. Please provide positive Int.
  ///   - unit: the unit of since. Default is day.
  public static func removeData(olderThan: Int = BluetraceConfig.TTLDays, unit: Calendar.Component = .day) {
    Logger.DLog("Removing data older than \(olderThan) \(unit) ago from device!")
    let managedContext = HyperTrace.shared().persistentContainer.viewContext
    let fetchRequest = NSFetchRequest<Encounter>(entityName: "Encounter")
    fetchRequest.includesPropertyValues = false
    
    // For e.g. 31st of March, we get reverseCutOffDate of 10th March
    let reverseCutOffDate: Date? = Calendar.current.date(byAdding: unit, value: -olderThan, to: Date())
    if let validDate = reverseCutOffDate {
      let predicateForDel = NSPredicate(format: "timestamp < %@", validDate as NSDate)
      fetchRequest.predicate = predicateForDel
      do {
        let encounters = try managedContext.fetch(fetchRequest)
        for encounter in encounters {
          managedContext.delete(encounter)
        }
        try managedContext.save()
      } catch {
        print("Could not perform delete of old data. \(error)")
      }
    }
  }
  
  public static func removeAllEncounters () {
    Logger.DLog("Removing all encounters")
    let managedContext = HyperTrace.shared().persistentContainer.viewContext
    let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Encounter")
    fetchRequest.includesPropertyValues = false
    
    do {
      let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
      
      try managedContext.execute(deleteRequest)
      try managedContext.save()
    } catch {
      print(error)
    }
  }
  
  public static func countEncounters(olderThan: Int = BluetraceConfig.TTLDays, unit: Calendar.Component = .day) -> Int {
    Logger.DLog("Counting number of encounters older than \(olderThan) \(unit) ago.")
    let managedContext = HyperTrace.shared().persistentContainer.viewContext
    let fetchRequest = NSFetchRequest<Encounter>(entityName: "Encounter")
    fetchRequest.includesPropertyValues = false
    
    // For e.g. 31st of March, we get reverseCutOffDate of 10th March
    let reverseCutOffDate: Date? = Calendar.current.date(byAdding: unit, value: -olderThan, to: Date())
    if let validDate = reverseCutOffDate {
      let predicateForDel = NSPredicate(format: "timestamp < %@", validDate as NSDate)
      fetchRequest.predicate = predicateForDel
      do {
        let encounters = try managedContext.count(for: fetchRequest)
        return encounters
      } catch {
        print("Could not perform count of old data. \(error)")
      }
    }
    
    return 0
  }
}
