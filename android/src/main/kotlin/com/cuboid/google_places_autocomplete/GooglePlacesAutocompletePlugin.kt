package com.cuboid.google_places_autocomplete

import android.content.Context
import android.content.pm.PackageManager
import android.util.Log
import androidx.annotation.NonNull
import com.google.android.gms.common.api.ApiException
import com.google.android.gms.common.api.Status
import com.google.android.libraries.places.api.Places
import com.google.android.libraries.places.api.model.AutocompleteSessionToken
import com.google.android.libraries.places.api.model.Place
import com.google.android.libraries.places.api.model.PlaceTypes
import com.google.android.libraries.places.api.net.FetchPlaceRequest
import com.google.android.libraries.places.api.net.FindAutocompletePredictionsRequest
import com.google.android.libraries.places.api.net.PlacesClient
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/** GooglePlacesAutocompletePlugin */
class GooglePlacesAutocompletePlugin: FlutterPlugin, MethodCallHandler {
    
    companion object {
        private const val TAG = "GooglePlacesPlugin"
        private const val CHANNEL_NAME = "com.cuboid.google_places_autocomplete"
    }
    
    private lateinit var channel: MethodChannel
    private lateinit var context: Context
    private lateinit var placesClient: PlacesClient
    private var sessionToken: AutocompleteSessionToken? = null

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        Log.d(TAG, "onAttachedToEngine: Initializing plugin")
        try {
            channel = MethodChannel(flutterPluginBinding.binaryMessenger, CHANNEL_NAME)
            channel.setMethodCallHandler(this)
            context = flutterPluginBinding.applicationContext
            Log.d(TAG, "onAttachedToEngine: Plugin initialized successfully")
        } catch (e: Exception) {
            Log.e(TAG, "onAttachedToEngine: Failed to initialize plugin", e)
        }
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        Log.d(TAG, "onMethodCall: method=${call.method}, arguments=${call.arguments}")
        try {
            when (call.method) {
                "initialize" -> initialize(call, result)
                "getPredictions" -> getPredictions(call, result)
                "getPlaceDetails" -> getPlaceDetails(call, result)
                else -> {
                    Log.w(TAG, "onMethodCall: Method not implemented - ${call.method}")
                    result.notImplemented()
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "onMethodCall: Unexpected error handling method ${call.method}", e)
            result.error(
                "UNEXPECTED_ERROR",
                "An unexpected error occurred: ${e.message}",
                mapOf(
                    "method" to call.method,
                    "exceptionType" to e.javaClass.simpleName,
                    "stackTrace" to e.stackTraceToString()
                )
            )
        }
    }

    private fun initialize(call: MethodCall, result: Result) {
        Log.d(TAG, "initialize: Starting initialization")
        
        try {
            // If already initialized, just return success to avoid recreating the client
            if (::placesClient.isInitialized) {
                Log.d(TAG, "initialize: Places client already initialized")
                // Ensure session token exists
                if (sessionToken == null) {
                    sessionToken = AutocompleteSessionToken.newInstance()
                    Log.d(TAG, "initialize: Created new session token for existing client")
                }
                result.success(null)
                return
            }

            val apiKey = call.argument<String>("apiKey") ?: getApiKeyFromManifest()
            Log.d(TAG, "initialize: API key source=${if (call.argument<String>("apiKey") != null) "MethodCall" else "Manifest"}, present=${apiKey != null}")

            if (apiKey == null) {
                Log.e(TAG, "initialize: API Key not found in MethodCall or Manifest")
                result.error(
                    "MISSING_API_KEY",
                    "API Key not found. Please provide it via initialize() method or AndroidManifest.xml",
                    mapOf(
                        "manifestKey" to "com.google.android.geo.API_KEY",
                        "suggestion" to "Add API key to AndroidManifest.xml or pass it in initialize()"
                    )
                )
                return
            }

            if (!Places.isInitialized()) {
                Log.d(TAG, "initialize: Initializing Places SDK")
                Places.initialize(context, apiKey)
                Log.d(TAG, "initialize: Places SDK initialized successfully")
            } else {
                Log.d(TAG, "initialize: Places SDK already initialized")
            }
            
            placesClient = Places.createClient(context)
            Log.d(TAG, "initialize: Places client created successfully")
            
            // Create a new session token for the start
            sessionToken = AutocompleteSessionToken.newInstance()
            Log.d(TAG, "initialize: Session token created")
            
            result.success(null)
        } catch (e: Exception) {
            Log.e(TAG, "initialize: Failed to initialize Places SDK", e)
            result.error(
                "INITIALIZATION_ERROR",
                "Failed to initialize Places SDK: ${e.message}",
                mapOf(
                    "exceptionType" to e.javaClass.simpleName,
                    "stackTrace" to e.stackTraceToString()
                )
            )
        }
    }

    private fun getPredictions(call: MethodCall, result: Result) {
        Log.d(TAG, "getPredictions: Starting prediction request")
        
        try {
            if (!::placesClient.isInitialized) {
                Log.e(TAG, "getPredictions: Places client not initialized")
                result.error(
                    "NOT_INITIALIZED",
                    "Places Client not initialized. Call initialize() first.",
                    null
                )
                return
            }

            val query = call.argument<String>("query") ?: ""
            val countries = call.argument<List<String>>("countries")
            val placeTypes = call.argument<List<String>>("placeTypes")
            
            Log.d(TAG, "getPredictions: query='$query', countries=$countries, placeTypes=$placeTypes")

            // Ensure session token exists
            if (sessionToken == null) {
                sessionToken = AutocompleteSessionToken.newInstance()
                Log.d(TAG, "getPredictions: Created new session token")
            }

            val requestBuilder = FindAutocompletePredictionsRequest.builder()
                .setSessionToken(sessionToken)
                .setQuery(query)

            if (countries != null && countries.isNotEmpty()) {
                requestBuilder.setCountries(countries)
                Log.d(TAG, "getPredictions: Set countries filter: $countries")
            }
            
            if (placeTypes != null && placeTypes.isNotEmpty()) {
                requestBuilder.setTypesFilter(placeTypes)
                Log.d(TAG, "getPredictions: Set place types filter: $placeTypes")
            }

            val request = requestBuilder.build()
            Log.d(TAG, "getPredictions: Sending request to Places API")

            placesClient.findAutocompletePredictions(request)
                .addOnSuccessListener { response ->
                    Log.d(TAG, "getPredictions: Success - ${response.autocompletePredictions.size} predictions received")
                    try {
                        val predictions = response.autocompletePredictions.map { prediction ->
                            mapOf(
                                "placeId" to prediction.placeId,
                                "distanceMeters" to prediction.distanceMeters,
                                "structuredFormat" to mapOf(
                                    "mainText" to mapOf("text" to prediction.getPrimaryText(null).toString()),
                                    "secondaryText" to mapOf("text" to prediction.getSecondaryText(null).toString())
                                )
                            )
                        }
                        result.success(predictions)
                    } catch (e: Exception) {
                        Log.e(TAG, "getPredictions: Error mapping predictions", e)
                        result.error(
                            "MAPPING_ERROR",
                            "Failed to map predictions: ${e.message}",
                            mapOf("stackTrace" to e.stackTraceToString())
                        )
                    }
                }
                .addOnFailureListener { exception ->
                    handlePlacesApiError(TAG, "getPredictions", exception, result, "PREDICTION_ERROR")
                }
        } catch (e: Exception) {
            Log.e(TAG, "getPredictions: Unexpected error", e)
            result.error(
                "PREDICTION_ERROR",
                "Unexpected error getting predictions: ${e.message}",
                mapOf(
                    "exceptionType" to e.javaClass.simpleName,
                    "stackTrace" to e.stackTraceToString()
                )
            )
        }
    }

    private fun getPlaceDetails(call: MethodCall, result: Result) {
        Log.d(TAG, "getPlaceDetails: Starting place details request")
        
        try {
            if (!::placesClient.isInitialized) {
                Log.e(TAG, "getPlaceDetails: Places client not initialized")
                result.error(
                    "NOT_INITIALIZED",
                    "Places Client not initialized. Call initialize() first.",
                    null
                )
                return
            }

            val placeId = call.argument<String>("placeId")
            Log.d(TAG, "getPlaceDetails: placeId=$placeId")
            
            if (placeId == null) {
                Log.e(TAG, "getPlaceDetails: Place ID is missing")
                result.error(
                    "INVALID_ARGUMENT",
                    "Place ID is required but was not provided",
                    null
                )
                return
            }

            // Request all available fields for comprehensive place details
            val placeFields = listOf(
                Place.Field.ID,
                Place.Field.DISPLAY_NAME,
                Place.Field.FORMATTED_ADDRESS,
                Place.Field.LOCATION,
                Place.Field.NATIONAL_PHONE_NUMBER,
                Place.Field.INTERNATIONAL_PHONE_NUMBER,
                Place.Field.WEBSITE_URI,
                Place.Field.GOOGLE_MAPS_URI,
                Place.Field.RATING,
                Place.Field.USER_RATING_COUNT,
                Place.Field.ADDRESS_COMPONENTS,
                Place.Field.TYPES,
                Place.Field.BUSINESS_STATUS,
                Place.Field.OPENING_HOURS,
                Place.Field.UTC_OFFSET,
                Place.Field.PLUS_CODE,
                Place.Field.VIEWPORT
            )
            
            Log.d(TAG, "getPlaceDetails: Requesting ${placeFields.size} fields")

            val request = FetchPlaceRequest.builder(placeId, placeFields)
                .setSessionToken(sessionToken)
                .build()

            Log.d(TAG, "getPlaceDetails: Sending request to Places API")

            placesClient.fetchPlace(request)
                .addOnSuccessListener { response ->
                    Log.d(TAG, "getPlaceDetails: Success - place details received")
                    try {
                        // Session Token consumed, nullify it so next search creates a new one
                        sessionToken = null
                        Log.d(TAG, "getPlaceDetails: Session token consumed and cleared")
                        
                        val place = response.place
                        val details = mutableMapOf<String, Any?>()
                        
                        // Basic fields
                        details["placeId"] = place.id
                        details["name"] = place.displayName
                        details["formattedAddress"] = place.formattedAddress
                        
                        Log.d(TAG, "getPlaceDetails: Mapped basic fields - id=${place.id}, name=${place.displayName}")
                        
                        // Phone numbers - use correct key names matching Dart model
                        details["nationalPhoneNumber"] = place.nationalPhoneNumber
                        details["internationalPhoneNumber"] = place.internationalPhoneNumber
                        
                        // URLs
                        details["websiteUri"] = place.websiteUri?.toString()
                        details["googleMapsUri"] = place.googleMapsUri?.toString()
                        
                        // Ratings
                        details["rating"] = place.rating
                        details["userRatingsTotal"] = place.userRatingCount
                        
                        // Location
                        if (place.location != null) {
                            details["location"] = mapOf(
                                "latitude" to place.location!!.latitude,
                                "longitude" to place.location!!.longitude
                            )
                            Log.d(TAG, "getPlaceDetails: Location mapped - lat=${place.location!!.latitude}, lng=${place.location!!.longitude}")
                        }
                        
                        // Address components - serialize as list of maps
                        val addressComponentsList = place.addressComponents?.asList()?.map { component ->
                            mapOf(
                                "longText" to component.name,
                                "shortText" to component.shortName,
                                "types" to component.types
                            )
                        }
                        details["addressComponents"] = addressComponentsList
                        Log.d(TAG, "getPlaceDetails: Address components mapped - count=${addressComponentsList?.size ?: 0}")
                        
                        // Business status
                        details["businessStatus"] = place.businessStatus?.name
                        
                        // Types
                        details["types"] = place.placeTypes
                        
                        // UTC offset
                        details["utcOffset"] = place.utcOffsetMinutes
                        
                        // Plus code
                        if (place.plusCode != null) {
                            details["plusCode"] = mapOf(
                                "globalCode" to place.plusCode?.globalCode,
                                "compoundCode" to place.plusCode?.compoundCode
                            )
                        }
                        
                        // Viewport
                        if (place.viewport != null) {
                            details["viewport"] = mapOf(
                                "northeast" to mapOf(
                                    "latitude" to place.viewport?.northeast?.latitude,
                                    "longitude" to place.viewport?.northeast?.longitude
                                ),
                                "southwest" to mapOf(
                                    "latitude" to place.viewport?.southwest?.latitude,
                                    "longitude" to place.viewport?.southwest?.longitude
                                )
                            )
                        }
                        
                        Log.d(TAG, "getPlaceDetails: All fields mapped successfully, returning result")
                        result.success(details)
                    } catch (e: Exception) {
                        Log.e(TAG, "getPlaceDetails: Error mapping place details", e)
                        result.error(
                            "MAPPING_ERROR",
                            "Failed to map place details: ${e.message}",
                            mapOf("stackTrace" to e.stackTraceToString())
                        )
                    }
                }
                .addOnFailureListener { exception ->
                    handlePlacesApiError(TAG, "getPlaceDetails", exception, result, "PLACE_DETAILS_ERROR")
                }
        } catch (e: Exception) {
            Log.e(TAG, "getPlaceDetails: Unexpected error", e)
            result.error(
                "PLACE_DETAILS_ERROR",
                "Unexpected error getting place details: ${e.message}",
                mapOf(
                    "exceptionType" to e.javaClass.simpleName,
                    "stackTrace" to e.stackTraceToString()
                )
            )
        }
    }
    
    /**
     * Handles Places API errors with detailed logging and error reporting.
     */
    private fun handlePlacesApiError(
        tag: String,
        method: String,
        exception: Exception,
        result: Result,
        errorCode: String
    ) {
        val errorDetails = mutableMapOf<String, Any?>()
        errorDetails["exceptionType"] = exception.javaClass.simpleName
        
        // Extract status code and message from ApiException if available
        if (exception is ApiException) {
            val status: Status = exception.status
            errorDetails["statusCode"] = status.statusCode
            errorDetails["statusMessage"] = status.statusMessage
            errorDetails["isSuccess"] = status.isSuccess
            errorDetails["isCanceled"] = status.isCanceled
            errorDetails["isInterrupted"] = status.isInterrupted
            errorDetails["hasResolution"] = status.hasResolution()
            
            Log.e(tag, "$method: ApiException - statusCode=${status.statusCode}, " +
                    "statusMessage=${status.statusMessage}, " +
                    "message=${exception.message}")
            
            // Provide more specific error messages based on status code
            val userMessage = when (status.statusCode) {
                0 -> "Success (but marked as failure)"
                1 -> "Sign in required"
                2 -> "Invalid account"
                3 -> "Resolution required"
                4 -> "Network error - please check your internet connection"
                5 -> "Internal error"
                6 -> "Developer error - check API configuration"
                7 -> "API error"
                8 -> "Timeout - request took too long"
                9 -> "Quota exceeded - API usage limit reached"
                10 -> "Over query limit - too many requests"
                else -> exception.message ?: "Unknown Places API error"
            }
            
            result.error(errorCode, userMessage, errorDetails)
        } else {
            Log.e(tag, "$method: Error - ${exception.message}", exception)
            errorDetails["stackTrace"] = exception.stackTraceToString()
            result.error(
                errorCode,
                exception.message ?: "Unknown error occurred",
                errorDetails
            )
        }
    }

    private fun getApiKeyFromManifest(): String? {
        Log.d(TAG, "getApiKeyFromManifest: Attempting to retrieve API key from manifest")
        return try {
            val appInfo = context.packageManager.getApplicationInfo(
                context.packageName,
                PackageManager.GET_META_DATA
            )
            val apiKey = appInfo.metaData?.getString("com.google.android.geo.API_KEY")
            if (apiKey != null) {
                Log.d(TAG, "getApiKeyFromManifest: API key found in manifest")
            } else {
                Log.w(TAG, "getApiKeyFromManifest: API key not found in manifest metadata")
            }
            apiKey
        } catch (e: PackageManager.NameNotFoundException) {
            Log.e(TAG, "getApiKeyFromManifest: Package not found", e)
            null
        } catch (e: Exception) {
            Log.e(TAG, "getApiKeyFromManifest: Error retrieving API key", e)
            null
        }
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        Log.d(TAG, "onDetachedFromEngine: Cleaning up plugin")
        try {
            channel.setMethodCallHandler(null)
            sessionToken = null
            Log.d(TAG, "onDetachedFromEngine: Plugin cleanup completed")
        } catch (e: Exception) {
            Log.e(TAG, "onDetachedFromEngine: Error during cleanup", e)
        }
    }
}
