//
//  AnalyticsManager.swift
//  iot
//
//  Created by Mark Randall on 6/11/20.
//  Copyright © 2020 Mark Randall. All rights reserved.
//

import FirebaseAnalytics

// MARK: - Screen

enum AnalyticsScreen: String {
    case statusView
}

// MARK: - Events

protocol AnalyticsEvent {
    var name: String { get }
    var parameters: [String: Any]? { get }
}

extension AnalyticsEvent {
    var parameters: [String: Any]? { nil }
}

// MARK: - User Properties

protocol AnalyticsUserProperty {
    var name: String { get }
    var value: String? { get }
}

enum UserProperty: AnalyticsUserProperty {

    case authState(AuthState)
    
    var name: String {
        "\(self)".components(separatedBy: "(").first ?? "invalid"
    }
    
    var value: String? {
        switch self {
        case .authState(let authState):
            return ("\(authState)".components(separatedBy: "(").first ?? "invalid").snakeCased()
        }
    }
}

// MARK: - Firebase AnalyticsManager

protocol AnalyticsManager {
    
    func setScreeName(_ screen: AnalyticsScreen)
    func logEvent(_ event: AnalyticsEvent)
    func setUserProperty(_ property: AnalyticsUserProperty)
}

struct FirebaseAnalyticsManager: AnalyticsManager {
    
    func setScreeName(_ screen: AnalyticsScreen) {
        Analytics.setScreenName(screen.rawValue.snakeCased(), screenClass: nil)
    }
    
    func logEvent(_ event: AnalyticsEvent) {
        
        guard let normalizedName = event.name.snakeCased() else { assertionFailure(); return }
        
        guard let parameters = event.parameters else {
            Analytics.logEvent(normalizedName, parameters: nil)
            return
        }
        
        let normalizedParameters: [String: Any] = parameters.reduce(into: [:]) {
            guard let noramilizedKey = $1.key.snakeCased() else { return }
            $0[noramilizedKey] = $1.value
        }
        
        Analytics.logEvent(normalizedName, parameters: normalizedParameters)
    }
    
    func setUserProperty(_ property: AnalyticsUserProperty) {
        Analytics.setUserProperty(property.value, forName: property.name)
    }
}

private extension String {
  
    func snakeCased() -> String? {
        let pattern = "([a-z0-9])([A-Z])"
        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        let range = NSRange(location: 0, length: count)
        return regex?.stringByReplacingMatches(in: self, options: [], range: range, withTemplate: "$1_$2").lowercased()
    }
}
