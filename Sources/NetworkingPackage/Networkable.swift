//
//  File.swift
//
//
//  Created by Temur Chitashvili on 29.08.24.
//

import Foundation

protocol Networkable {
    func sendRequest<T: Decodable>(endPoint: EndPoint, resultHandler: @escaping (Result <T, NetworkError>) -> Void)
}

public final class NetworkService: Networkable {
    public static let shared = NetworkService()
    
    private init() { }
    
    public func sendRequest<T: Decodable>(endPoint endpoint: EndPoint, resultHandler: @escaping (Result<T, NetworkError>) -> Void) {
        
        guard let urlRequest = createRequest(endPoint: endpoint) else {
            return
        }
        
        let urlTask = URLSession.shared.dataTask(with: urlRequest) { data, response, error in
            
            if let error = error {
                print("Error: \(error.localizedDescription)")
                resultHandler(.failure(.invalidURL))
                return
            }

            
            guard let response = response as? HTTPURLResponse else {
                resultHandler(.failure(.unknown))
                return
            }
            
            let statusCode = response.statusCode
            
            guard 200...299 ~= statusCode else {
                print("Received unexpected status code: \(statusCode)")
                resultHandler(.failure(.unexpectedStatusCode(statusCode: statusCode)))
                return
            }
            
            guard let data = data else {
                resultHandler(.failure(.unknown))
                return
            }
            
            do {
                let decodedResponse = try JSONDecoder().decode(T.self, from: data)
                resultHandler(.success(decodedResponse))
            } catch let DecodingError.dataCorrupted(context) {
                print("Data corrupted: \(context.debugDescription)")
                resultHandler(.failure(.decode))
            } catch let DecodingError.keyNotFound(key, context) {
                print("Key '\(key)' not found: \(context.debugDescription)")
                resultHandler(.failure(.decode))
            } catch let DecodingError.typeMismatch(type, context) {
                print("Type '\(type)' mismatch: \(context.debugDescription)")
                resultHandler(.failure(.decode))
            } catch let DecodingError.valueNotFound(value, context) {
                print("Value '\(value)' not found: \(context.debugDescription)")
                resultHandler(.failure(.decode))
            } catch {
                print("Decoding error: \(error.localizedDescription)")
                resultHandler(.failure(.decode))
            }
        }
        urlTask.resume()
    }
        
    public func sendRequestWithNoResponse(endPoint: EndPoint, completion: @escaping (Result<Void, NetworkError>) -> Void) {
        guard let urlRequest = createRequest(endPoint: endPoint) else {
            return
        }
        
        let urlTask = URLSession.shared.dataTask(with: urlRequest) { data, response, error in
            
            if let error = error {
                print("Error: \(error.localizedDescription)")
                completion(.failure(.invalidURL))
                return
            }
            
            guard let response = response as? HTTPURLResponse else {
                completion(.failure(.unknown))
                return
            }
            
            let statusCode = response.statusCode
            
            guard 200...299 ~= statusCode else {
                print("Received unexpected status code: \(statusCode)")
                completion(.failure(.unexpectedStatusCode(statusCode: statusCode)))
                return
            }
            
            guard let data = data else {
                completion(.failure(.unknown))
                return
            }
            
            if statusCode == 201 {
                completion(.success(()))
                return
            }
        }
        urlTask.resume()
    }
}

extension Networkable {
    fileprivate func createRequest(endPoint: EndPoint) -> URLRequest? {
        var urlComponents = URLComponents()
        urlComponents.scheme = endPoint.scheme
        urlComponents.host = endPoint.host
        urlComponents.path = endPoint.path
        
        if let queryParams = endPoint.queryParams {
            urlComponents.queryItems = queryParams.map { URLQueryItem(name: $0.key, value: $0.value) }
        }
        
        guard let url = urlComponents.url else {
            return nil
        }
        
        
        let encoder = JSONEncoder()
        var request = URLRequest(url: url)
        request.httpMethod = endPoint.method.rawValue
        request.allHTTPHeaderFields = endPoint.header
        
        if let body = endPoint.body {
            do {
                let encodedBody = try encoder.encode(body)
                request.httpBody = encodedBody
                
                // Convert the encoded body to a JSON string for printing
                if let jsonString = String(data: encodedBody, encoding: .utf8) {
                    print("Request Body as JSON: \(jsonString)")
                }
            } catch {
                print("Failed to encode body: \(error.localizedDescription)")
            }
        }
        
        return request
    }
}
