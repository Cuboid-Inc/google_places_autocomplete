import Flutter
import UIKit
import GooglePlaces
import CoreLocation
import os.log

// MARK: - Logging Extension
private let logger = OSLog(subsystem: "com.cuboid.google_places_autocomplete", category: "GooglePlacesPlugin")

public class GooglePlacesAutocompletePlugin: NSObject, FlutterPlugin {
    
    // MARK: - Constants
    private static let channelName = "com.cuboid.google_places_autocomplete"
    
    // MARK: - Properties
    private var placesClient: GMSPlacesClient?
    private var sessionToken: GMSAutocompleteSessionToken?

    // MARK: - Plugin Registration
    public static func register(with registrar: FlutterPluginRegistrar) {
        os_log(.info, log: logger, "register: Registering plugin")
        let channel = FlutterMethodChannel(name: channelName, binaryMessenger: registrar.messenger())
        let instance = GooglePlacesAutocompletePlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
        os_log(.info, log: logger, "register: Plugin registered successfully")
    }

    // MARK: - Method Call Handler
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        os_log(.debug, log: logger, "handle: method=%{public}@", call.method)
        
        switch call.method {
        case "initialize":
            initialize(call, result: result)
        case "getPredictions":
            getPredictions(call, result: result)
        case "getPlaceDetails":
            getPlaceDetails(call, result: result)
        default:
            os_log(.error, log: logger, "handle: Method not implemented - %{public}@", call.method)
            result(FlutterMethodNotImplemented)
        }
    }

    // MARK: - Initialize
    private func initialize(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        os_log(.info, log: logger, "initialize: Starting initialization")
        
        var apiKey: String? = nil
        var keySource = "none"
        
        // Try to get API key from arguments first
        if let args = call.arguments as? [String: Any],
           let key = args["apiKey"] as? String, !key.isEmpty {
            apiKey = key
            keySource = "MethodCall"
            os_log(.debug, log: logger, "initialize: API key found in MethodCall arguments")
        }
        
        // Fallback: read from Info.plist - GooglePlacesAPIKey
        if apiKey == nil {
            if let key = Bundle.main.object(forInfoDictionaryKey: "GooglePlacesAPIKey") as? String, !key.isEmpty {
                apiKey = key
                keySource = "Info.plist (GooglePlacesAPIKey)"
                os_log(.debug, log: logger, "initialize: API key found in Info.plist (GooglePlacesAPIKey)")
            }
        }
        
        // Try GOOGLE_PLACES_API_KEY (used in this app's Info.plist)
        if apiKey == nil {
            if let key = Bundle.main.object(forInfoDictionaryKey: "GOOGLE_PLACES_API_KEY") as? String, !key.isEmpty {
                apiKey = key
                keySource = "Info.plist (GOOGLE_PLACES_API_KEY)"
                os_log(.debug, log: logger, "initialize: API key found in Info.plist (GOOGLE_PLACES_API_KEY)")
            }
        }
        
        // Double fallback: try the Google Maps API key (some apps use same key)
        if apiKey == nil {
            if let key = Bundle.main.object(forInfoDictionaryKey: "GMSApiKey") as? String, !key.isEmpty {
                apiKey = key
                keySource = "Info.plist (GMSApiKey)"
                os_log(.debug, log: logger, "initialize: API key found in Info.plist (GMSApiKey)")
            }
        }
        
        guard let key = apiKey, !key.isEmpty else {
            os_log(.error, log: logger, "initialize: API Key not found in any source")
            result(FlutterError(
                code: "MISSING_API_KEY",
                message: "API Key not found. Please provide it via initialize() method or Info.plist",
                details: [
                    "checkedKeys": ["GooglePlacesAPIKey", "GOOGLE_PLACES_API_KEY", "GMSApiKey"],
                    "suggestion": "Add API key to Info.plist or pass it in initialize()"
                ]
            ))
            return
        }
        
        os_log(.info, log: logger, "initialize: Using API key from %{public}@", keySource)
        
        do {
            GMSPlacesClient.provideAPIKey(key)
            placesClient = GMSPlacesClient.shared()
            sessionToken = GMSAutocompleteSessionToken.init()
            os_log(.info, log: logger, "initialize: Places SDK initialized successfully")
            result(nil)
        } catch {
            os_log(.error, log: logger, "initialize: Failed to initialize Places SDK - %{public}@", error.localizedDescription)
            result(FlutterError(
                code: "INITIALIZATION_ERROR",
                message: "Failed to initialize Places SDK: \(error.localizedDescription)",
                details: buildErrorDetails(error)
            ))
        }
    }

    // MARK: - Get Predictions
    private func getPredictions(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        os_log(.debug, log: logger, "getPredictions: Starting prediction request")
        
        guard let client = placesClient else {
            os_log(.error, log: logger, "getPredictions: Places client not initialized")
            result(FlutterError(
                code: "NOT_INITIALIZED",
                message: "Places Client not initialized. Call initialize() first.",
                details: nil
            ))
            return
        }

        guard let args = call.arguments as? [String: Any],
              let query = args["query"] as? String else {
            os_log(.error, log: logger, "getPredictions: Query is missing from arguments")
            result(FlutterError(
                code: "INVALID_ARGUMENT",
                message: "Query is required but was not provided",
                details: nil
            ))
            return
        }
        
        let countries = args["countries"] as? [String]
        let placeTypes = args["placeTypes"] as? [String]
        
        os_log(.debug, log: logger, "getPredictions: query='%{public}@', countries=%{public}@, placeTypes=%{public}@",
               query,
               countries?.joined(separator: ",") ?? "nil",
               placeTypes?.joined(separator: ",") ?? "nil")
        
        // Ensure session token exists
        if sessionToken == nil {
            sessionToken = GMSAutocompleteSessionToken.init()
            os_log(.debug, log: logger, "getPredictions: Created new session token")
        }

        let filter = GMSAutocompleteFilter()
        
        if let countries = countries, !countries.isEmpty {
            filter.countries = countries
            os_log(.debug, log: logger, "getPredictions: Set countries filter")
        }
        
        if let placeTypes = placeTypes, !placeTypes.isEmpty {
            filter.types = placeTypes
            os_log(.debug, log: logger, "getPredictions: Set place types filter")
        }
        
        if let lat = args["originLat"] as? Double,
           let lng = args["originLng"] as? Double {
            filter.origin = CLLocation(latitude: lat, longitude: lng)
            os_log(.debug, log: logger, "getPredictions: Set origin location - lat=%{public}f, lng=%{public}f", lat, lng)
        }

        os_log(.debug, log: logger, "getPredictions: Sending request to Places API")
        
        client.findAutocompletePredictions(fromQuery: query, filter: filter, sessionToken: sessionToken, callback: { [weak self] (predictions, error) in
            if let error = error {
                os_log(.error, log: logger, "getPredictions: API error - %{public}@", error.localizedDescription)
                result(FlutterError(
                    code: "PREDICTION_ERROR",
                    message: self?.getUserFriendlyErrorMessage(error) ?? error.localizedDescription,
                    details: self?.buildErrorDetails(error)
                ))
                return
            }

            let predictionCount = predictions?.count ?? 0
            os_log(.info, log: logger, "getPredictions: Success - %d predictions received", predictionCount)
            
            do {
                let mappedPredictions = try predictions?.map { prediction -> [String: Any?] in
                    return [
                        "placeId": prediction.placeID,
                        "distanceMeters": prediction.distanceMeters?.intValue,
                        "structuredFormat": [
                            "mainText": ["text": prediction.attributedPrimaryText.string],
                            "secondaryText": ["text": prediction.attributedSecondaryText?.string ?? ""]
                        ]
                    ]
                } ?? []
                
                result(mappedPredictions)
            } catch {
                os_log(.error, log: logger, "getPredictions: Error mapping predictions - %{public}@", error.localizedDescription)
                result(FlutterError(
                    code: "MAPPING_ERROR",
                    message: "Failed to map predictions: \(error.localizedDescription)",
                    details: self?.buildErrorDetails(error)
                ))
            }
        })
    }

    // MARK: - Get Place Details
    private func getPlaceDetails(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        os_log(.debug, log: logger, "getPlaceDetails: Starting place details request")
        
        guard let client = placesClient else {
            os_log(.error, log: logger, "getPlaceDetails: Places client not initialized")
            result(FlutterError(
                code: "NOT_INITIALIZED",
                message: "Places Client not initialized. Call initialize() first.",
                details: nil
            ))
            return
        }

        guard let args = call.arguments as? [String: Any],
              let placeId = args["placeId"] as? String else {
            os_log(.error, log: logger, "getPlaceDetails: Place ID is missing from arguments")
            result(FlutterError(
                code: "INVALID_ARGUMENT",
                message: "Place ID is required but was not provided",
                details: nil
            ))
            return
        }
        
        os_log(.debug, log: logger, "getPlaceDetails: placeId=%{public}@", placeId)

        // Specify all available fields for comprehensive place details
        let fields: GMSPlaceField = [
            .name,
            .placeID,
            .formattedAddress,
            .coordinate,
            .phoneNumber,
            .website,
            .rating,
            .userRatingsTotal,
            .addressComponents,
            .openingHours,
            .utcOffsetMinutes,
            .businessStatus,
            .types
        ]
        
        os_log(.debug, log: logger, "getPlaceDetails: Requesting place fields, sending request to Places API")

        client.fetchPlace(fromPlaceID: placeId, placeFields: fields, sessionToken: sessionToken, callback: { [weak self] (place, error) in
            // Reset session token
            self?.sessionToken = nil
            os_log(.debug, log: logger, "getPlaceDetails: Session token consumed and cleared")
            
            if let error = error {
                os_log(.error, log: logger, "getPlaceDetails: API error - %{public}@", error.localizedDescription)
                result(FlutterError(
                    code: "PLACE_DETAILS_ERROR",
                    message: self?.getUserFriendlyErrorMessage(error) ?? error.localizedDescription,
                    details: self?.buildErrorDetails(error)
                ))
                return
            }

            guard let place = place else {
                os_log(.error, log: logger, "getPlaceDetails: Place not found for placeId=%{public}@", placeId)
                result(FlutterError(
                    code: "PLACE_NOT_FOUND",
                    message: "Place not found for the given ID",
                    details: ["placeId": placeId]
                ))
                return
            }
            
            os_log(.info, log: logger, "getPlaceDetails: Success - place details received for %{public}@", place.name ?? "unknown")
            
            do {
                var details: [String: Any?] = [:]
                
                // Basic fields
                details["placeId"] = place.placeID
                details["name"] = place.name
                details["formattedAddress"] = place.formattedAddress
                
                os_log(.debug, log: logger, "getPlaceDetails: Mapped basic fields - id=%{public}@, name=%{public}@",
                       place.placeID ?? "nil", place.name ?? "nil")
                
                // Phone numbers - iOS SDK only provides one phone number field
                // We'll use it for both national and formatted phone number
                details["nationalPhoneNumber"] = place.phoneNumber
                details["internationalPhoneNumber"] = place.phoneNumber
                details["formattedPhoneNumber"] = place.phoneNumber
                
                // URLs
                if let website = place.website {
                    details["websiteUri"] = website.absoluteString
                }
                
                // Google Maps URI - construct from placeId since iOS SDK doesn't provide it directly
                if let pid = place.placeID {
                    details["googleMapsUri"] = "https://www.google.com/maps/place/?q=place_id:\(pid)"
                }
                
                // Ratings
                details["rating"] = place.rating
                details["userRatingsTotal"] = Int(place.userRatingsTotal)
                
                // Location
                details["location"] = [
                    "latitude": place.coordinate.latitude,
                    "longitude": place.coordinate.longitude
                ]
                os_log(.debug, log: logger, "getPlaceDetails: Location mapped - lat=%{public}f, lng=%{public}f",
                       place.coordinate.latitude, place.coordinate.longitude)
                
                // Address components - serialize as list of maps
                if let addressComponents = place.addressComponents {
                    let componentsList = addressComponents.map { component -> [String: Any?] in
                        return [
                            "longText": component.name,
                            "shortText": component.shortName,
                            "types": component.types
                        ]
                    }
                    details["addressComponents"] = componentsList
                    os_log(.debug, log: logger, "getPlaceDetails: Address components mapped - count=%d", componentsList.count)
                }
                
                // Business status
                switch place.businessStatus {
                case .operational:
                    details["businessStatus"] = "OPERATIONAL"
                case .closedTemporarily:
                    details["businessStatus"] = "CLOSED_TEMPORARILY"
                case .closedPermanently:
                    details["businessStatus"] = "CLOSED_PERMANENTLY"
                default:
                    details["businessStatus"] = nil
                }
                
                // Types
                details["types"] = place.types
                
                // UTC offset
                if place.utcOffsetMinutes != nil {
                    details["utcOffset"] = Int(truncating: place.utcOffsetMinutes!)
                }
                
                // Viewport - not available in iOS SDK v10.6.0, construct from coordinate
                // The iOS SDK does not expose viewport, so we create a small viewport around the coordinate
                let delta = 0.01 // Approximately 1km
                details["viewport"] = [
                    "northeast": [
                        "latitude": place.coordinate.latitude + delta,
                        "longitude": place.coordinate.longitude + delta
                    ],
                    "southwest": [
                        "latitude": place.coordinate.latitude - delta,
                        "longitude": place.coordinate.longitude - delta
                    ]
                ]
                
                os_log(.info, log: logger, "getPlaceDetails: All fields mapped successfully, returning result")
                result(details)
            } catch {
                os_log(.error, log: logger, "getPlaceDetails: Error mapping place details - %{public}@", error.localizedDescription)
                result(FlutterError(
                    code: "MAPPING_ERROR",
                    message: "Failed to map place details: \(error.localizedDescription)",
                    details: self?.buildErrorDetails(error)
                ))
            }
        })
    }
    
    // MARK: - Error Handling Helpers
    
    /// Builds detailed error information dictionary for debugging
    private func buildErrorDetails(_ error: Error) -> [String: Any] {
        var details: [String: Any] = [
            "errorType": String(describing: type(of: error)),
            "localizedDescription": error.localizedDescription
        ]
        
        let nsError = error as NSError
        details["domain"] = nsError.domain
        details["code"] = nsError.code
        
        if let underlyingError = nsError.userInfo[NSUnderlyingErrorKey] as? NSError {
            details["underlyingErrorDomain"] = underlyingError.domain
            details["underlyingErrorCode"] = underlyingError.code
            details["underlyingErrorMessage"] = underlyingError.localizedDescription
        }
        
        // Add Places-specific error info if available
        if nsError.domain == "com.google.places" || nsError.domain == "GMSPlacesErrorDomain" {
            details["placesErrorCode"] = nsError.code
            details["isPlacesError"] = true
            
            // Map common Places error codes
            switch nsError.code {
            case -1: // GMSPlacesErrorCodeNetworkError
                details["errorCategory"] = "NETWORK_ERROR"
            case -2: // GMSPlacesErrorCodeServerError
                details["errorCategory"] = "SERVER_ERROR"
            case -3: // GMSPlacesErrorCodeInternalError
                details["errorCategory"] = "INTERNAL_ERROR"
            case -4: // GMSPlacesErrorCodeKeyInvalid
                details["errorCategory"] = "KEY_INVALID"
            case -5: // GMSPlacesErrorCodeKeyExpired
                details["errorCategory"] = "KEY_EXPIRED"
            case -6: // GMSPlacesErrorCodeUsageLimitExceeded
                details["errorCategory"] = "USAGE_LIMIT_EXCEEDED"
            case -7: // GMSPlacesErrorCodeRateLimitExceeded
                details["errorCategory"] = "RATE_LIMIT_EXCEEDED"
            case -9: // GMSPlacesErrorCodeAccessNotConfigured
                details["errorCategory"] = "ACCESS_NOT_CONFIGURED"
            case -10: // GMSPlacesErrorCodeDeviceRateLimitExceeded
                details["errorCategory"] = "DEVICE_RATE_LIMIT_EXCEEDED"
            default:
                details["errorCategory"] = "UNKNOWN"
            }
        }
        
        os_log(.debug, log: logger, "buildErrorDetails: domain=%{public}@, code=%d", nsError.domain, nsError.code)
        
        return details
    }
    
    /// Returns a user-friendly error message based on the error type
    private func getUserFriendlyErrorMessage(_ error: Error) -> String {
        let nsError = error as NSError
        
        // Handle Places-specific errors
        if nsError.domain == "com.google.places" || nsError.domain == "GMSPlacesErrorDomain" {
            switch nsError.code {
            case -1:
                return "Network error - please check your internet connection"
            case -2:
                return "Server error - please try again later"
            case -3:
                return "Internal error occurred"
            case -4:
                return "Invalid API key - please check your configuration"
            case -5:
                return "API key has expired"
            case -6:
                return "API usage limit exceeded - please try again later"
            case -7:
                return "Too many requests - please slow down"
            case -9:
                return "Places API not configured - check Google Cloud Console"
            case -10:
                return "Device rate limit exceeded - please wait before retrying"
            default:
                break
            }
        }
        
        // Handle general network errors
        if nsError.domain == NSURLErrorDomain {
            switch nsError.code {
            case NSURLErrorNotConnectedToInternet:
                return "No internet connection"
            case NSURLErrorTimedOut:
                return "Request timed out - please try again"
            case NSURLErrorNetworkConnectionLost:
                return "Network connection lost"
            default:
                return "Network error: \(error.localizedDescription)"
            }
        }
        
        return error.localizedDescription
    }
}
