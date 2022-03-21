//
//  BluetraceConfig.swift
//  OpenTrace

import CoreBluetooth

import Foundation

public struct BluetraceConfig {
    static let BluetoothServiceID = CBUUID(string: "\(PlistHelper.getvalueFromInfoPlist(withKey: "TRACER_SVC_ID") ?? "A6BA4286-C550-4794-A888-9467EF0B31A8")")

    // Staging and Prod uses the same CharacteristicServiceIDv2, since BluetoothServiceID is different
    static let CharacteristicServiceIDv2 = CBUUID(string: "\(PlistHelper.getvalueFromInfoPlist(withKey: "V2_CHARACTERISTIC_ID") ?? "D1034710-B11E-42F2-BCA3-F481177D5BB2")")

    static let OrgID = PlistHelper.getvalueFromInfoPlist(withKey: "TRACER_ORG") ?? "hyperjump"
  
    public static var ProtocolVersion = 2
    public static var CentralScanInterval = 60 // in seconds
    public static var CentralScanDuration = 10 // in seconds
    public static var charUUIDArray = [CharacteristicServiceIDv2]
    public static var TTLDays = 21
}
