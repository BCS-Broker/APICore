//
//  ReqresMethod.swift
//  APICoreTests
//
//  Created by alexej_ne on 31/01/2019.
//  Copyright © 2019 BCS. All rights reserved.
//

import APICore

enum ReqresUserMethods: APIServiceMethod {

    var methodPath: MethodPath {
        switch self {
        case .list: return (.get, "users")
        case .single(let id): return (.get, "users/\(id)")
        }
    }
    
    var params: MethodParams? {
        switch self {
        case .list(let page): return MethodParams(inUrl: ["page": page])
        default: return nil
        }
    }
    
    case list(page: Int)
    case single(id: Int)
}

extension ReqresUserMethods {
    
    enum MockKey: String, MockKeyType {
        case list
        case single
    }
    
    var mockKey: MockKey? {
        switch self {
        case .list: return .list
        case .single: return .single
        }
    }
}
