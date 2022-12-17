//
//  ItauService.swift
//  ItauFramework
//
//  Created by Ana Krieger on 16/12/22.
//

import Foundation

public enum HTTPMethod: String {
  case post = "POST"
}

public class ItauService {
    
    public static let shared = ItauService()
    private let baseURL = "https://run.mocky.io/v3/ca30b574-72b5-40ed-b83c-63e547378ebe"
    
    private init (){}
    
    public func post(body: [String : Any], completed: @escaping (Result<[String : Any]?, Error>) -> Void) {
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
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
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
