//
//  Aliases.swift
//  APICore
//
//  Created by alexej_ne on 31/01/2019.
//  Copyright © 2019 BCS. All rights reserved.
//

import Moya
import Alamofire

public typealias SessionManager = Alamofire.SessionManager
public typealias BodyEncoding = ParameterEncoding
public typealias MethodBodyEncoding = (APIHTTPMethod) -> BodyEncoding
public typealias APIHTTPMethod = HTTPMethod
public typealias MethodPath = (APIHTTPMethod, String)
public typealias JSONEncoding = Alamofire.JSONEncoding
public typealias Plugin = PluginType


public extension SessionManager {
    public static var instance: SessionManager {
        let configuration = URLSessionConfiguration.default
        configuration.httpAdditionalHeaders =  SessionManager.defaultHTTPHeaders
        let sessionManager = SessionManager(configuration: configuration)
        sessionManager.startRequestsImmediately = false
        return sessionManager
    }
}
