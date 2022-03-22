//
//  File.swift
//
//
//  Created by Nico Prananta on 05.01.22.
//

import Foundation

struct UploadFileData: Encodable {
  var token: String
  var records: [Encounter]
  var events: [Encounter]
}
