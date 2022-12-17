//
//  ItauService.swift
//  ItauFramework
//
//  Created by Ana Krieger on 16/12/22.
//

import Foundation
import Security
import CommonCrypto

public enum HTTPMethod: String {
  case post = "POST"
}

@available(macOS 10.14, *)
public class ItauService: NSObject {
    
    public static let shared = ItauService()
    private let baseURL = "https://run.mocky.io/v3/ca30b574-72b5-40ed-b83c-63e547378ebe"
    static let publicKeyHash = "WgoPGXU0SpJ4q65+D5dMK3VNJY9N3ZE9Hi5nVtcGh6I="
    
    let rsa2048Asn1Header:[UInt8] = [
        0x30, 0x82, 0x01, 0x22, 0x30, 0x0d, 0x06, 0x09, 0x2a, 0x86, 0x48, 0x86,
        0xf7, 0x0d, 0x01, 0x01, 0x01, 0x05, 0x00, 0x03, 0x82, 0x01, 0x0f, 0x00
    ]
    
    private override init (){}
    
    private func sha256(data : Data) -> String {
        var keyWithHeader = Data(rsa2048Asn1Header)
        keyWithHeader.append(data)
        var hash = [UInt8](repeating: 0,  count: Int(CC_SHA256_DIGEST_LENGTH))
        
        keyWithHeader.withUnsafeBytes {
            _ = CC_SHA256($0, CC_LONG(keyWithHeader.count), &hash)
        }
        return Data(hash).base64EncodedString()
    }
    
    public func post(body: [String : Any], completed: @escaping (Result<[String : Any]?, Error>) -> Void) {
        let session = URLSession(configuration: .ephemeral, delegate: self, delegateQueue: nil)
        guard let url = URL(string: baseURL) else {
            completed(.failure(ItauError.unableToComplete))
            return
        }
        
        var request = URLRequest(url: url)
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body, options: .prettyPrinted)
         } catch let error {
             print(error.localizedDescription)
             completed(.failure(ItauError.invalidData))
         }
        
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = HTTPMethod.post.rawValue
        
        let task = session.dataTask(with: url) { data, response, error in
            if let _ = error {
                completed(.failure(ItauError.unableToComplete))
            }
            
            guard let data = data else {
                completed(.failure(ItauError.invalidData))
                return
            }
            
            do{
                completed(.success(try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]))
            } catch {
                completed(.failure(ItauError.invalidData))
            }
        }
        task.resume()
    }
}

@available(macOS 12.0, *)
extension ItauService: URLSessionDelegate {
    public func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        guard let serverTrust = challenge.protectionSpace.serverTrust else {
            completionHandler(.cancelAuthenticationChallenge, nil);
            return
        }
        
        if let serverCertificate = SecTrustGetCertificateAtIndex(serverTrust, 0) {
            // Server public key
            let serverPublicKey = SecCertificateCopyKey(serverCertificate)
            let serverPublicKeyData = SecKeyCopyExternalRepresentation(serverPublicKey!, nil )!
            let data:Data = serverPublicKeyData as Data
            // Server Hash key
            let serverHashKey = sha256(data: data)
            // Local Hash Key
            let publickKeyLocal = type(of: self).publicKeyHash
            if (serverHashKey == publickKeyLocal) {
                // Success! This is our server
                print("Public key pinning is successfully completed")
                completionHandler(.useCredential, URLCredential(trust:serverTrust))
                return
            }
        }
    }
}
