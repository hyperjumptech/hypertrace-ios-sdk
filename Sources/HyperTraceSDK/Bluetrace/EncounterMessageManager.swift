import Foundation

class EncounterMessageManager {
  let userDefaultsTempIdKey = "BROADCAST_MSG"
  let userDefaultsTempIdArrayKey = "BROAD_MSG_ARRAY"
  let userDefaultsAdvtKey = "ADVT_DATA"
  let userDefaultsAdvtExpiryKey = "ADVT_EXPIRY"
  
  static let shared = EncounterMessageManager()
  
  var tempId: String? {
    guard var tempIds = UserDefaults.standard.array(forKey: userDefaultsTempIdArrayKey) as! [[String: Any]]? else {
      return "not_found"
    }
    
    if let bmExpiry = tempIds.first?["expiryTime"] as? Date {
      while Date() > bmExpiry {
        tempIds.removeFirst()
      }
    }
    
    guard let validBm = tempIds.first?["tempID"] as? String else { return "" }
    return validBm
  }
  
  var advtPayload: Data? {
    return UserDefaults.standard.data(forKey: userDefaultsAdvtKey)
  }
  
  // This variable stores the expiry date of the broadcast message. At the same time, we will use this expiry date as the expiry date for the encryted advertisement payload
  var advtPayloadExpiry: Date? {
    return UserDefaults.standard.object(forKey: userDefaultsAdvtExpiryKey) as? Date
  }
  
  func setup() {
    // Check payload validity
    if advtPayloadExpiry == nil ||  Date() > advtPayloadExpiry! {
      
      fetchBatchTempIds { [unowned self](error: Error?, resp: (tempIds: [TempId], refreshDate: Date)?) in
        guard let response = resp else {
          Logger.DLog("No response, Error: \(String(describing: error))")
          return
        }
        _ = self.setAdvtPayloadIntoUserDefaultsv2(response)
        UserDefaults.standard.set(response.tempIds.map { $0.asDictionary() }, forKey: self.userDefaultsTempIdArrayKey)
        
      }
    }
  }
  
  func getTempId(onComplete: @escaping (String?) -> Void) {
    // Check refreshDate
    if advtPayloadExpiry == nil ||  Date() > advtPayloadExpiry! {
      fetchBatchTempIds { [unowned self](error: Error?, resp: (tempIds: [TempId], refreshDate: Date)?) in
        guard let response = resp else {
          Logger.DLog("No response, Error: \(String(describing: error))")
          return
        }
        
        _ = self.setAdvtPayloadIntoUserDefaultsv2(response)
        UserDefaults.standard.set(response.tempIds.map { $0.asDictionary() }, forKey: self.userDefaultsTempIdArrayKey)
        UserDefaults.standard.set(response.refreshDate, forKey: self.userDefaultsAdvtExpiryKey)
        
        var dataArray = response
        
        let bmExpiry = Date(timeIntervalSinceReferenceDate: dataArray.tempIds.first!.expiryTime)
        while Date() > bmExpiry {
          dataArray.tempIds.removeFirst()
        }
        
        guard let validBm = dataArray.tempIds.first?.tempID else { return }
        UserDefaults.standard.set(validBm, forKey: self.userDefaultsTempIdKey)
        
        onComplete(validBm)
        return
        
      }
    }
    
    // We know that tempIdBatch array has not expired, now find the latest usable tempId
    if let msg = tempId {
      onComplete(msg)
    } else {
      // This is not part of usual expected flow, just run setup
      setup()
      onComplete(nil)
    }
  }
  
  func fetchTempId(onComplete: ((Error?, (String, Date)?) -> Void)?) {
    Logger.DLog("Fetching tempId")
    API.shared().getBroadcastMessage(onComplete)
    
  }
  
  func fetchBatchTempIds(onComplete: ((Error?, ([TempId], Date)?) -> Void)?) {
    Logger.DLog("Fetching Batch of tempIds")
    API.shared().getTempIDs(onComplete)
  }
  
  func setAdvtPayloadIntoUserDefaultsv2(_ response: (tempIds: [TempId], refreshDate: Date)) -> Data? {
    
    var dataArray = response
    
    // Pop out expired tempId
    let bmExpiry = Date(timeIntervalSinceReferenceDate: dataArray.tempIds.first!.expiryTime)
    while Date() > bmExpiry {
      dataArray.tempIds.removeFirst()
    }
    
    guard let validBm = dataArray.tempIds.first?.tempID else { return nil }
    
    let peripheralCharStruct = PeripheralCharacteristicsDataV2(mp: Device.current.description, id: validBm, o: BluetraceConfig.OrgID, v: BluetraceConfig.ProtocolVersion)
    
    do {
      let encodedPeriCharStruct = try JSONEncoder().encode(peripheralCharStruct)
      if let string = String(data: encodedPeriCharStruct, encoding: .utf8) {
        Logger.DLog("UserDefaultsv2 \(string)")
      } else {
        print("not a valid UTF-8 sequence")
      }
      
      UserDefaults.standard.set(encodedPeriCharStruct, forKey: self.userDefaultsAdvtKey)
      UserDefaults.standard.set(response.refreshDate, forKey: self.userDefaultsAdvtExpiryKey)
      return encodedPeriCharStruct
    } catch {
      Logger.DLog("Error: \(error)")
    }
    
    return nil
  }
  
}
