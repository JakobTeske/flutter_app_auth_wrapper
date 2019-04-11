import Flutter
import UIKit
import AppAuth

public class SwiftFlutterAppAuthWrapperPlugin: NSObject, FlutterPlugin {
	
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "flutter_app_auth_wrapper", binaryMessenger: registrar.messenger())
	let eventChannel = FlutterEventChannel(name: "oauth_completion_events", binaryMessenger: registrar.messenger())
	
	let currentVC = (registrar.messenger() as? FlutterEngine)?.viewController
	
	let instance = SwiftFlutterAppAuthWrapperPlugin(with: currentVC)
	
	
	eventChannel.setStreamHandler(instance)
    registrar.addMethodCallDelegate(instance, channel: channel)
  }
	
	private var viewController :UIViewController?
	
	init(with vc: UIViewController?) {
		super.init()
		self.viewController = vc
	}
	
	var eventSink: FlutterEventSink?

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
	switch(call.method){
	case "startOAuth":
		print("on startOAuth")
		guard let json = call.arguments as? String,
			let authConfig = AuthConfig(json) else {
				handle(error: FlutterAppAuthWrapperError.invalidParameters)
				result(true)
				return
		}
		startOAuthBy(result, authConfig: authConfig)
	default: break
//		result
	}
	
  }
	
	var authRequest: OIDAuthorizationRequest?
	public static var authFlow:OIDExternalUserAgentSession?
	
	func startOAuthBy(_ result: FlutterResult, authConfig: AuthConfig) {
		guard let authEndpoint = URL(string: authConfig.endpoint.auth),
			let tokenEndpoint = URL(string: authConfig.endpoint.token),
			let redirectURL = URL(string: authConfig.redirectURL) else {
				handle(error: FlutterAppAuthWrapperError.invalidURLs)
				result(true)
				return
		}
		
		guard let vc = UIApplication.shared.keyWindow?.rootViewController else {
			handle(error: FlutterAppAuthWrapperError.noViewController)
			result(true)
			return
		}
		
		let config = OIDServiceConfiguration(authorizationEndpoint: authEndpoint, tokenEndpoint: tokenEndpoint)
		var additionalParameters = [String: String]()
		if authConfig.prompt.count > 0 {
			additionalParameters["prompt"] = authConfig.prompt
		}
		if let parameters = authConfig.customParameters {
			var mapped = [String: String]()
			for (k, v) in parameters {
				mapped["\(k)"] = "\(v)"
			}
			additionalParameters.merge(mapped) { current, new in
				return current
			}
		}
		
		authRequest = OIDAuthorizationRequest(configuration: config,
											  clientId: authConfig.clientID,
											  clientSecret: authConfig.clientSecret,
											  scopes: authConfig.scopes ?? [],
											  redirectURL: redirectURL,
											  responseType: OIDResponseTypeCode,
											  additionalParameters: additionalParameters)
		SwiftFlutterAppAuthWrapperPlugin.authFlow = OIDAuthState.authState(byPresenting: authRequest!, presenting: vc) { authState, error in
			print("auth callback")
			if let authState = authState,
				let response = authState.lastTokenResponse {
				print("auth state: \(String(describing: authState))")
				var dict: [AnyHashable: Any] = [:]
				dict["access_token"] = response.accessToken ?? ""
				dict["expires_at"] = Int((response.accessTokenExpirationDate?.timeIntervalSince1970 ?? 0) * 1000)
				dict["refresh_token"] = response.refreshToken ?? ""
				do {
					let data = try JSONSerialization.data(withJSONObject: dict, options: JSONSerialization.WritingOptions.init(rawValue: 0))
					let string = String(data: data, encoding: .utf8)
					self.eventSink?(string)
				} catch {
					self.handle(error: error)
				}
			} else if let error = error {
				self.handle(error: error)
				print("auth error: \(String(describing: error))")
			}
			self.authRequest = nil
		}
		result(true)
	}
	
	func handle(error: Error) {
		let flutterError = FlutterError(code: "OAuthError", message: error.localizedDescription, details: "No details")
		eventSink?(flutterError)
	}

}

/// Errors may happen in `SwiftFlutterAppAuthWrapperPlugin`.
public enum FlutterAppAuthWrapperError: Error, LocalizedError {
	/// Invalid parameters.
	case invalidParameters
	/// Invalid URLs.
	case invalidURLs
	/// No view controller to present the web view to authenticate users.
	case noViewController
	
	public var errorDescription: String? {
		switch self {
		case .invalidParameters:
			return "Invalid parameters."
		case .invalidURLs:
			return "Invalid URLs."
		case .noViewController:
			return "No view controllers."
		}
	}
}


extension SwiftFlutterAppAuthWrapperPlugin: FlutterStreamHandler {
	
	public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
		self.eventSink = events
		return nil
	}
	
	public func onCancel(withArguments arguments: Any?) -> FlutterError? {
		self.eventSink = nil
		return nil
	}
}

