//
//  APIService.swift
//  APICore
//
//  Created by alexej_ne on 28/01/2019.
//  Copyright © 2019 BCS. All rights reserved.
//
import Moya

open class APIService<TMethod, TConfigurator>: APIServiceType where TMethod: APIServiceMethod, TConfigurator:APIServiceConfiguratorType   {
 
    public typealias Method = TMethod
    public typealias Configurator = TConfigurator
    private var actualMocks: [Method.MockKey: Data] = [:]
    open var allServiceBodyEncoding: MethodBodyEncoding?
    open var useMocksIfSetted: Bool = true
    open var urlServicePathComponent: String { return "" }
    open var serviceHeaders:[String: String]? { return nil }
    open var authStrategy: AuthStrategy { return .withoutAuth }
    
    private var configuratorStrong: Configurator {
        guard let serviceConfigurator = APIService<TMethod, TConfigurator>.configurator else {
            fatal("ServiceConfigurator is nil")
        }
        return serviceConfigurator
    }
    
    lazy public var provider: MoyaProvider<TMethod> = {
        let configurator = configuratorStrong
        return MoyaProvider<TMethod>(endpointClosure: endpointBuilder,
                                     stubClosure: stubBehaviorBuilder,
                                     manager: configurator.sessionManager,
                                     plugins: configurator.plugins)
 
    }()
    
    required public init() {}
}

//MARK: Public+
public extension  APIService {
    func setMock(for key: Method.MockKey, value: String) {
        if let data = value.data(using: .utf8) {
            actualMocks[key] = data
        }
    }
    
    func setMock(for key: Method.MockKey, value: Data) {
        actualMocks[key] = value
    }
    
    func removeMock(for key: Method.MockKey) {
        actualMocks.removeValue(forKey: key)
    }
}

//MARK: Public+
public extension APIService where TMethod.MockKey: MockSampleData {
    public func setMockFromSample(for key: Method.MockKey) {
        guard let sample = key.sampleData else { return }
        setMock(for: key, value: sample)
    }
}

//MARK: Private
fileprivate extension APIService {
    
    func endpointBuilder(_ method: Method) -> Endpoint {
        
        let fullUrl = buildFullUrl(method)
        let fullHeaders = buildFullHeader(method)
        let mockClosure = buildMockClosure(method)
        
        return Endpoint(url: fullUrl.absoluteString,
                        sampleResponseClosure: mockClosure,
                        method: method.methodPath.0,
                        task: buildTask(method),
                        httpHeaderFields: fullHeaders)
        
    }
    
    func buildTask(_ method: Method) -> Task {
        var methodParams = method.params
        print("url: \(authStrategy)")
        
        if case let AuthStrategy.addTokenToUrl(urlParamName: authUrlTokenKey) = authStrategy,
           let token = configuratorStrong.authTokenProvider?.token {
            methodParams.url(authUrlTokenKey, token)
        }
        
        if let multipartData = method.multipart {
            let formData = MultipartFormData(provider: .data(multipartData.data),
                                             name: "file",
                                             fileName: "file.jpg",
                                             mimeType: multipartData.mimeType)
            return .uploadCompositeMultipart([formData], urlParameters: methodParams.urlParams)
        }
        
        return .requestCompositeParameters(bodyParameters: methodParams.bodyParams,
                                           bodyEncoding: getBodyEncoding(method),
                                           urlParameters: methodParams.urlParams)
    }
    
    func getBodyEncoding(_ method: Method) -> ParameterEncoding {
        if let methodBodyEncoding = method.overrideBodyEncoding {
            return methodBodyEncoding
        }
        
        let httpMethod = method.methodPath.0
        if let allServiceBodyEncoding = allServiceBodyEncoding {
            return allServiceBodyEncoding(httpMethod)
        }
        
        return configuratorStrong.bodyEncoding(httpMethod)
    }
    
    func buildFullHeader(_ method: Method) -> [String: String] {
        var fullHeaders: [String: String] = configuratorStrong.baseHeaders ?? [:]
        
        if let serviceHeaders = serviceHeaders {
            fullHeaders = fullHeaders.merging(serviceHeaders,
                                              uniquingKeysWith: {( _, serv) in serv })
        }
        
        if let methodHeaders = method.headers {
            fullHeaders = fullHeaders.merging(methodHeaders,
                                              uniquingKeysWith: {( _, meth) in meth })
        }
        
        print("header: \(authStrategy)")
        if case let AuthStrategy.addTokenToHeader(headerName: headerTokenKey) = authStrategy,
            let token = configuratorStrong.authTokenProvider?.token {
            fullHeaders[headerTokenKey] = token 
        }
        
        return fullHeaders
    }
    
    func buildMockClosure(_ method: Method) -> Endpoint.SampleResponseClosure {
        return { [weak self] in
            guard let key = method.mockKey, let data = self?.actualMocks[key] else {
                return .networkResponse(200, method.sampleData)
            }
            
            return .networkResponse(200, data)
        }
    }
    
    private func stubBehaviorBuilder(_ method: Method) -> StubBehavior {
        guard useMocksIfSetted, let key = method.mockKey else { return .never }
        return actualMocks.keys.contains(key) ? .delayed(seconds: 1) : .never
    }
    
    
    private func buildFullUrl(_ method: Method) -> URL {
        let fullUrl = configuratorStrong.baseUrl
            .appendingPathComponent(urlServicePathComponent)
            .appendingPathComponent(method.methodPath.1)
        
        return fullUrl
    }
}
