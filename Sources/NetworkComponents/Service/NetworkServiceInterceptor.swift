//
//  NetworkServiceInterceptor.swift
//  
//
//
//

import Foundation

/// Inspector used for intercepting pre and post processing of network requests.
public protocol NetworkServiceInterceptor {
    
    /// Called before a networkRequest is processed to allow for inpsection
    /// - Parameter request: The Network Request submitted for processing
    func inspect(request: NetworkRequest)
    
    /// Called before a network request is processed to attach additional HTTP headers for security purposes
    /// - Parameters:
    ///   - request: the `NetworkRequest` submitted for processing
    ///   - body: the boyd of the request
    /// - Returns: additional headers releated to security
    func securityHeaders(for request: NetworkRequest, containing body: Data?) -> [String: String]?
    
    /// Called after a Network Response is received to allow for inspection and postprocessing of network requests
    /// - Parameters:
    ///   - response: The`NetworkResponse`
    ///   - request: The NetworkRequest submitted for processing
    func inspect(response: NetworkResponse, for request: NetworkRequest)
    
    /// Called during a NetworkRequest to allow for processing of HTTP authentication challenges
    /// - Parameter challenge: the given challenge to handle
    /// - Returns: the credential to pass to the URLSession completionHandler
    func inspect(challenge: URLAuthenticationChallenge) -> URLCredential?
    
    /// Called during a NetworkRequest to validate certificate during authentication challenges
    /// - Parameter challenge: the given challenge to handle
    /// - Returns: a boolean specifying whether the certificate is valid or not
    func validatePinning(challenge: URLAuthenticationChallenge) -> Bool
}

public typealias NetworkResponseHandler = (NetworkResponse) -> Void

/// Network service provider protocol used for processing service requests.
public protocol NetworkServiceProvider: NSObjectProtocol {
    
    /// Get or set the NetworkRequest/NetworkResponse inspector
    var interceptor: NetworkServiceInterceptor? { get set }
    
    /// Get or set the headers used with every request. Individual requests can override with their own headers.
    var headers: [String: String] { get set }
    
    /// Process a request.
    /// - Parameters:
    ///   - request: The configured NetworkRequest
    ///   - content: The optional content to be sent in the request payload. This can be a dictionary of
    ///   parameters for form submission or data in the request body. How this is interprested is based on
    ///   the "Content-Type" header.
    ///   - completionHandler: The handler to be called when the Network Response when the request has been processed.
    func process(_ request: NetworkRequest, content: Any?) async throws -> AsyncToken
    
    func process(_ request: NetworkRequest, content: Any?, completionHandler: NetworkResponseHandler?) throws -> AsyncToken
}

