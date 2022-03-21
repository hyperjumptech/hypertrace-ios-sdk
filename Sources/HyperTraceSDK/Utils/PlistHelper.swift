//
//  File.swift
//
//
//  Created by Nico Prananta on 27.12.21.
//

import Foundation

struct PlistHelper {
  static func getvalueFromInfoPlist(withKey key: String) -> String? {
    if let path = Bundle.main.path(forResource: "Info", ofType: "plist"),
       let keyValue = NSDictionary(contentsOfFile: path)?.value(forKey: key) as? String
    {
      return keyValue
    }
    return nil
  }
}
