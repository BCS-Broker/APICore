//
//  ApiServiceDelegate.swift
//  APICore
//
//  Created by alexej_ne on 28/01/2019.
//  Copyright © 2019 BCS. All rights reserved.
//

import Moya
import RxSwift

public protocol APIServiceConfiguratorType: class {
    var baseUrl: URL { get }
    var baseHeaders: [String: String]? { get }
    var sessionManager: SessionManager { get }
    var plugins: [Plugin] { get }
    var bodyEncoding: MethodBodyEncoding { get }
    var requestsErrorBehavior: RequestErrorBehavior? { get }
    var delegate: APIServiceConfiguratorDelegate? { get set }
    
    func isUnauthorized(response: Response) -> Bool
}

public protocol APIServiceConfiguratorDelegate: class {
    var token: AuthToken? { get set }

    func tryRestoreAccess(response: Response) -> Single<Void>
}

public extension APIServiceConfiguratorDelegate {
    func tryRestoreAccess(response: Response) -> Single<Void> { return .just(()) }
}
