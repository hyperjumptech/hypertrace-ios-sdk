//
//  File.swift
//  
//
//  Created by Nico Prananta on 27.12.21.
//

import Foundation

enum APIPath: String {
  case getHandshakePin
  case getTempIDs
  case getBroadcastMessage
  case getUploadToken
  case uploadData
}

class API {
  private static var sharedAPI: API?
  private let baseUrl: String
  var uid: String = ""
  
  static func shared(baseUrl: String = "http://localhost:3000/api") -> API {
    if sharedAPI == nil {
      sharedAPI = API(baseUrl: baseUrl)
    }
    return sharedAPI!
  }
  
  init (baseUrl: String) {
    self.baseUrl = baseUrl
  }
  
  func getHandshakePin(_ onComplete: ( (Error?, (String)?) -> Void)?) {
    sendData(url: "\(baseUrl)/\(APIPath.getHandshakePin)") { (error: Error?, resp: HandshakePINResponse?) -> Void in
      onComplete?(error, (resp != nil) ? resp!.pin : nil)
    }
  }
  
  func getBroadcastMessage(_ onComplete: ( (Error?, (String, Date)?) -> Void)?) {
    sendData(url: "\(baseUrl)/\(APIPath.getBroadcastMessage)") { (error: Error?, resp: BroadcastMessageResponse?) -> Void in
      onComplete?(error, (resp != nil) ? (resp!.bm, Date(timeIntervalSince1970: resp!.refreshTime)) : nil)
    }
  }
  
  func getTempIDs(_ onComplete: ( (Error?, ([TempId], Date)?) -> Void)?) {
    sendData(url: "\(baseUrl)/\(APIPath.getTempIDs)") { (error: Error?, resp: TempIDsResponse?) -> Void in
      onComplete?(error, (resp != nil) ? (resp!.tempIDs, Date(timeIntervalSince1970: resp!.refreshTime)) : nil)
    }
  }
  
  func getUploadToken(code: String, _ onComplete: ( (Error?, String?) -> Void)?) {
    sendData(url: "\(baseUrl)/\(APIPath.getUploadToken)?data=\(code)") { (error: Error?, resp: UploadTokenResponse?) -> Void in
      onComplete?(error, resp?.token)
    }
  }
  
  func uploadData(token: String, traces: [Encounter], _ onComplete: ( (Error?, String?) -> Void)?) {
    let uploadBody = UploadBody(uid: uid, uploadToken: token, traces: traces)
    let url = "\(baseUrl)/\(APIPath.uploadData)"
    var urlRequest = URLRequest(url: URL(string: url)!)
    urlRequest.httpMethod = "POST"
    urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
    do {
      let body = try JSONEncoder().encode(uploadBody)
      Logger.DLog(String(data: body, encoding: .utf8) ?? "")
      urlRequest.httpBody = body
    } catch {
      Logger.DLog("JSONEncoder error: \(error)")
      onComplete?(APIError.encodingError(message: error.localizedDescription), nil)
    }
    
    URLSession.shared.dataTask(with: urlRequest, completionHandler: { data, response, error in
      let anError = isError(error: error, data: data, response: response as? HTTPURLResponse)
      guard anError == nil else {
        onComplete?(anError, nil)
        return
      }
            
      Logger.DLog(String(data: data!, encoding: .utf8) ?? "")
      
      do {
        let resp = try JSONDecoder().decode(BasicResponse.self, from: data!)
        onComplete?(nil, resp.status.rawValue)
      } catch {
        Logger.DLog("JSONDecoder error: \(error)")
        onComplete?(APIError.decodingError(message: error.localizedDescription), nil)
      }
    }).resume()
  }
  
  func sendData<ResponseType: Decodable>(url: String, onComplete: ((Error?, ResponseType?) -> Void)? ) {
    var components = URLComponents(string: url)
    if components?.queryItems == nil {
      components?.queryItems = []
    }
    components?.queryItems?.append(URLQueryItem(name: "uid", value: uid))
    URLSession.shared.dataTask(with: (components?.url)!, completionHandler: { data, response, error in
      let anError = isError(error: error, data: data, response: response as? HTTPURLResponse)
      guard anError == nil else {
        onComplete?(anError, nil)
        return
      }
      
      do {
        let resp = try JSONDecoder().decode(ResponseType.self, from: data!)
        onComplete?(nil, resp)
      } catch {
        Logger.DLog("JSONDecoder error: \(error)")
        onComplete?(APIError.decodingError(message: error.localizedDescription), nil)
      }
    }).resume()
  }
}

func isError(error: Error?, data: Data?, response: HTTPURLResponse?) -> Error? {
  guard error == nil else {
    Logger.DLog("API Error: \(error!)")
    return error
  }
  
  guard let httpResponse = response else {
    Logger.DLog("API Error: Empty response")
    return APIError.emptyData
  }
  
  guard httpResponse.statusCode == 200 else {
    Logger.DLog("API Error: HTTP Status \(httpResponse.statusCode)")
    let message = data != nil ? String(data: data!, encoding: .utf8) ?? "None" : "None"
    return APIError.not200(message: "HTTP Status: \(httpResponse.statusCode). Message: \(message)")
  }
  
  guard let _ = data else {
    return APIError.emptyData
  }
  
  return nil
}

enum APIError: Error {
  case emptyData
  case networkError(message: String)
  case decodingError(message: String)
  case encodingError(message: String)
  case not200(message: String)
}

enum ResponseStatus: String, Codable {
  case Success = "SUCCESS"
  case Failure = "FAILURE"
}
struct BasicResponse: Codable {
  let status: ResponseStatus
}

struct HandshakePINResponse: Codable {
  let pin: String
  let status: ResponseStatus
}

struct TempId: Codable {
  let expiryTime: TimeInterval
  let startTime: TimeInterval
  let tempID: String
}

extension TempId {
  func asDictionary() -> [String: Any] {
    return (try? JSONSerialization.jsonObject(with: JSONEncoder().encode(self))) as? [String: Any] ?? [:]
  }
}

struct TempIDsResponse: Codable {
  let refreshTime: TimeInterval
  let status: ResponseStatus
  let tempIDs: [TempId]
}

struct BroadcastMessageResponse: Codable {
  let bm: String
  let refreshTime: TimeInterval
}

struct UploadTokenResponse: Codable {
  let token: String
}

struct UploadBody: Encodable {
  let uid: String
  let uploadToken: String
  let traces: [Encounter]
}
