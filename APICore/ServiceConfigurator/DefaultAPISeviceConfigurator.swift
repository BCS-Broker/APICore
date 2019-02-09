//
//  DefaultAPISeviceConfigurator.swift
//  APICore
//
//  Created by alexej_ne on 29/01/2019.
//  Copyright © 2019 BCS. All rights reserved.
//

open class DefaultAPIServiceConfigurator: APIServiceConfiguratorType, AuthTokenProvider {
    
    public var sessionManager: SessionManager
    public var bodyEncoding: MethodBodyEncoding
    public var baseUrl: URL
    public var plugins: [Plugin] = []
    public weak var authTokenProvider: AuthTokenProvider? = nil
    public private(set) var token: AuthToken?
    
    public init(baseUrl: URL) {
        self.baseUrl = baseUrl
        sessionManager = SessionManager.instance
        bodyEncoding = { _ in JSONEncoding.default }
    }
    
    public init(baseUrl: URL,
                sessionManager: SessionManager = SessionManager.instance,
                bodyEncoding: @escaping MethodBodyEncoding = { _ in JSONEncoding.default },
                plugins: [Plugin] = []) {
        
        self.baseUrl = baseUrl
        self.sessionManager = sessionManager
        self.bodyEncoding = bodyEncoding
        self.plugins = plugins
    }
    
    public func setTokenProviderToSelf(with token: AuthToken) {
        authTokenProvider = self
        self.token = token
    }
}


