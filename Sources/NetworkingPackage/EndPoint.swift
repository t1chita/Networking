//
//  EndPoint.swift
//
//
//  Created by Temur Chitashvili on 29.08.24.
//

import Foundation

public protocol EndPoint {
    var host: String { get }
    var scheme: String { get }
    var path: String { get }
    var method: RequestMethod { get }
    var header: [String: String]? { get }
    var body: [String: AnyEncodable]? { get }
    var queryParams: [String: String]? { get } // Added for query parameters
    var pathParams: [String: String]? { get }  // Added for path parameters
}

extension EndPoint {
    var scheme: String {
        return "https"
    }
    var host: String {
        return ""
    }
}

extension Encodable {
    fileprivate func encode(to container: inout SingleValueEncodingContainer) throws {
        try container.encode(self)
    }
}

public struct AnyEncodable : Encodable {
    var value: Encodable
    
    init(_ value: Encodable) {
        self.value = value
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try value.encode(to: &container)
    }
}



