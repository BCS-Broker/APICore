//
//  APICoreTests.swift
//  APICoreTests
//
//  Created by alexej_ne on 28/01/2019.
//  Copyright © 2019 BCS. All rights reserved.
//

@testable import APICore
import XCTest
import RxSwift
import RxBlocking
import Alamofire
import Moya

class APICoreTests: XCTestCase, AuthTokenProvider {
    
    override func setUp() {
        let config = ReqresServicesConfigurator()
        config.authTokenProvider = self
        APICoreObjectContainer.instanceLazyInit.register(config)
        bag = DisposeBag()
        noInternetConnectionExpectation = XCTestExpectation()
        requestErrorExpectation = XCTestExpectation()
        requestSuccessExpectation = XCTestExpectation()
    }
    
    var noInternetConnectionExpectation = XCTestExpectation()
    var requestErrorExpectation = XCTestExpectation()
    var requestSuccessExpectation = XCTestExpectation()
    var bag = DisposeBag()
    
    var token: AuthToken? = "token"
    
    override func tearDown() {
        APICoreObjectContainer.releaseInstance()
    }
    
    func test_customConfigurationForService() {
        // запрос должен отвалиться потомучту мы переопределим конфигурацию для сервиса и укажем в ней некорректный url
        let configurator = ReqresServicesConfigurator(baseUrl: "https://my.broker2.ru") // плохой url
        APICoreObjectContainer.instanceLazyInit.register(configurator: configurator, for: ReqresUserAPI.self)
        
        let request = RequestBuilder(ReqresUserAPI.self, .single(id: 2)).request()
        let result = request.toBlocking().materialize()
        
        switch result {
        case .completed: XCTFail("No expected result")
        case let .failed(_, error):
            XCTAssert(error.asApiCoreError?.isHostNotFound ?? false)
        }
    }

    
    func test_noInternetConnection() {
        let configurator = ReqresServicesConfigurator(baseUrl: "https://google.com")
        APICoreObjectContainer.instanceLazyInit.register(configurator: configurator, for: ReqresUserAPI.self)
        
        let behavior: RequestErrorBehavior = .autoRepeatWhen(nsUrlErrorDomainCodeIn: [NSURLErrorNotConnectedToInternet],
                                                             maxRepeatCount: 3,
                                                             repeatAfter: .seconds(3))
        
        APICoreManager.shared.requestHttpErrors
            .subscribe(onNext: { error in
                XCTAssertTrue(error.asApiCoreError?.isNotInternetConnectionError ?? false)
                self.requestErrorExpectation.fulfill()
            })
            .disposed(by: bag)
        
        APICoreManager.shared.internetConnection
            .subscribe(onNext: { status in
                XCTAssertTrue(status == .notReachable)
                self.noInternetConnectionExpectation.fulfill()
            })
            .disposed(by: bag)
        
        let request = RequestBuilder(ReqresUserAPI.self, .single(id: 2)).request(forceErrorBehavior: behavior)
        let result = request.toBlocking().materialize()
        
        wait(for: [noInternetConnectionExpectation, requestErrorExpectation], timeout: 10)
        
        switch result {
        case .completed: XCTFail("No expected result")
        case let .failed(_, error: error):
            let apiCoreError = error.asApiCoreError
            XCTAssertTrue(apiCoreError?.isNotInternetConnectionError ?? false)
        }
        
        
    }
    
    func test_request_resource_not_found_error() {
        
        APICoreManager.shared.requestHttpErrors
            .subscribe(onNext: { error in
                XCTAssert(error.asApiCoreError?.isHTTPResourceNotFounde404 ?? false)
                self.requestErrorExpectation.fulfill()
            })
            .disposed(by: bag)
        
        do {
            let request:Single<User> = RequestBuilder(ReqresUserAPI.self, .unexistedResource)
                .request()
                .apiCoreFilterSuccessfulStatusCodes()
                .mapTo()
            let _ = try request.toBlocking().first()
        } catch let error as ApiCoreRequestError {
            XCTAssert(error.isHTTPResourceNotFounde404)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }

        wait(for: [requestErrorExpectation], timeout: 10)
    }
    
    func test_request_decode_error() {
        
        APICoreManager.shared.requestHttpErrors
            .subscribe(onNext: { error in
                XCTAssertNotNil(error.asApiCoreDecodingError)
                self.requestErrorExpectation.fulfill()
            })
            .disposed(by: bag)
        
        do {
            let request:Single<User> = RequestBuilder(ReqresUserAPI.self, .single(id: 2)).request().mapTo()
            let _ = try request.toBlocking().first()
        } catch let _ as ApiCoreDecodingError {
            XCTAssert(true)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
        wait(for: [requestErrorExpectation], timeout: 10)
    }
    
    func test_metrics() { 
        AF.request("https://google.com").response { response in
            debugPrint("duration: \(response.metrics?.taskInterval.duration)")
            debugPrint(response.metrics)
            self.requestSuccessExpectation.fulfill()
        }
        wait(for: [requestSuccessExpectation], timeout: 10)
    }
    
    func test_request_decode_array() {
        do {
            let request:Single<Root<[User]>> = RequestBuilder(ReqresUserAPI.self, .list(page: 1)).request().mapTo()
            let result = try request.toBlocking().first()
            XCTAssertNotNil(result, "Data model is nil")
        } catch {
            XCTFail("Catched error: \(error)")
        }
    }
    
    func test_request_decode() {
        
        do {
            let request:Single<Root<User>> = RequestBuilder(ReqresUserAPI.self, .single(id: 2)).request().mapTo()
            let result = try request.toBlocking().first()
            XCTAssertNotNil(result, "Data model is nil")
        } catch {
            XCTFail("Catched error: \(error)")
        }
    }
    
    func test_mock_request() {
        do {
            let response = """
            {
            \"data\" : {
            \"id\" : 222,
            \"last_name\" : \"Weaver\",
            \"first_name\" : \"Janet\",
            \"avatar\" : \"\"
            }
            }
            """
            ReqresUserAPI.shared.useMocksIfSetted = true
            ReqresUserAPI.shared.setMock(for: .single, value: response)
            
            let request:Single<Root<User>> = RequestBuilder(ReqresUserAPI.self, .single(id: 2)).request().mapTo()
            let result = try request.toBlocking().first()
            XCTAssertEqual(result?.data.id, 222, "NO mocks")
        } catch {
            XCTFail("Catched error: \(error)")
        }
    }
    
    func test_decode_empty_array() {
        do {
            let response = """
            {
            \"data\" : [1]
            }
            """
            ReqresUserAPI.shared.useMocksIfSetted = true
            ReqresUserAPI.shared.setMock(for: .list, value: response)
            
            let request:Single<Root<[User]>> = RequestBuilder(ReqresUserAPI.self, .list(page: 1)).request().mapTo()
            let _ = try request.toBlocking().first()
            XCTFail()
        } catch {
            XCTAssertNotNil(error.asApiCoreDecodingError)
        }
    }
 
}

