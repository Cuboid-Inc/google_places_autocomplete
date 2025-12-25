import Flutter
import UIKit
import GooglePlaces
import CoreLocation

public class GooglePlacesAutocompletePlugin: NSObject, FlutterPlugin {
    private var placesClient: GMSPlacesClient?
    private var sessionToken: GMSAutocompleteSessionToken?

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "com.cuboid.google_places_autocomplete", binaryMessenger: registrar.messenger())
        let instance = GooglePlacesAutocompletePlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "initialize":
            initialize(call, result: result)
        case "getPredictions":
            getPredictions(call, result: result)
        case "getPlaceDetails":
            getPlaceDetails(call, result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func initialize(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        var apiKey: String? = nil
        
        // Try to get API key from arguments first
        if let args = call.arguments as? [String: Any],
           let key = args["apiKey"] as? String, !key.isEmpty {
            apiKey = key
        }
        
        // Fallback: read from Info.plist
        if apiKey == nil {
            apiKey = Bundle.main.object(forInfoDictionaryKey: "GooglePlacesAPIKey") as? String
        }
        
        // Try GOOGLE_PLACES_API_KEY (used in this app's Info.plist)
        if apiKey == nil {
            apiKey = Bundle.main.object(forInfoDictionaryKey: "GOOGLE_PLACES_API_KEY") as? String
        }
        
        // Double fallback: try the Google Maps API key (some apps use same key)
        if apiKey == nil {
            apiKey = Bundle.main.object(forInfoDictionaryKey: "GMSApiKey") as? String
        }
        
        guard let key = apiKey, !key.isEmpty else {
            result(FlutterError(code: "MISSING_API_KEY", message: "API Key not found in arguments or Info.plist (GooglePlacesAPIKey or GMSApiKey)", details: nil))
            return
        }
        
        GMSPlacesClient.provideAPIKey(key)
        placesClient = GMSPlacesClient.shared()
        sessionToken = GMSAutocompleteSessionToken.init()
        result(nil)
    }

    private func getPredictions(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let client = placesClient else {
            result(FlutterError(code: "NOT_INITIALIZED", message: "Places Client not initialized", details: nil))
            return
        }

        guard let args = call.arguments as? [String: Any],
              let query = args["query"] as? String else {
            result(FlutterError(code: "INVALID_ARGUMENT", message: "Query is missing", details: nil))
            return
        }
        
        // Ensure session token exists
        if sessionToken == nil {
            sessionToken = GMSAutocompleteSessionToken.init()
        }

        let filter = GMSAutocompleteFilter()
        
        if let countries = args["countries"] as? [String] {
            filter.countries = countries
        }
        
        if let placeTypes = args["placeTypes"] as? [String] {
            // Mapping strings to GMSPlaceType?
            // The REST API uses strings like "restaurant", "geocode".
            // iOS SDK uses specific strings or simple types.
            // filter.types expects an array of strings.
            filter.types = placeTypes
        }
        
        if let lat = args["originLat"] as? Double,
           let lng = args["originLng"] as? Double {
            filter.origin = CLLocation(latitude: lat, longitude: lng)
        }

        client.findAutocompletePredictions(fromQuery: query, filter: filter, sessionToken: sessionToken, callback: { (predictions, error) in
            if let error = error {
                result(FlutterError(code: "PREDICTION_ERROR", message: error.localizedDescription, details: nil))
                return
            }

            let mappedPredictions = predictions?.map { prediction -> [String: Any?] in
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
        })
    }

    private func getPlaceDetails(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let client = placesClient else {
            result(FlutterError(code: "NOT_INITIALIZED", message: "Places Client not initialized", details: nil))
            return
        }

        guard let args = call.arguments as? [String: Any],
              let placeId = args["placeId"] as? String else {
            result(FlutterError(code: "INVALID_ARGUMENT", message: "Place ID is missing", details: nil))
            return
        }

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

        client.fetchPlace(fromPlaceID: placeId, placeFields: fields, sessionToken: sessionToken, callback: { (place, error) in
            // Reset session token
            self.sessionToken = nil
            
            if let error = error {
                result(FlutterError(code: "PLACE_DETAILS_ERROR", message: error.localizedDescription, details: nil))
                return
            }

            guard let place = place else {
                result(FlutterError(code: "PLACE_NOT_FOUND", message: "Place not found", details: nil))
                return
            }
            
            var details: [String: Any?] = [:]
            
            // Basic fields
            details["placeId"] = place.placeID
            details["name"] = place.name
            details["formattedAddress"] = place.formattedAddress
            
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
            
            result(details)
        })
    }
}
