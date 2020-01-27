//
//  APIServiceType+.swift
//  BrokerAPIServices
//
//  Created by alexej_ne on 16.07.2019.
//  Copyright © 2019 BCS. All rights reserved.
//
 
public extension APIServiceType {
    static func request(for method: Self.Method) -> RequestBuilder<Self> {
        return RequestBuilder(Self.self, method)
    }
}

