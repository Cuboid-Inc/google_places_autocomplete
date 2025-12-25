package com.cuboid.google_places_autocomplete

import android.content.Context
import android.content.pm.PackageManager
import androidx.annotation.NonNull
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
    private lateinit var channel: MethodChannel
    private lateinit var context: Context
    private lateinit var placesClient: PlacesClient
    private var sessionToken: AutocompleteSessionToken? = null

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "com.cuboid.google_places_autocomplete")
        channel.setMethodCallHandler(this)
        context = flutterPluginBinding.applicationContext
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        when (call.method) {
            "initialize" -> initialize(call, result)
            "getPredictions" -> getPredictions(call, result)
            "getPlaceDetails" -> getPlaceDetails(call, result)
            else -> result.notImplemented()
        }
    }

    private fun initialize(call: MethodCall, result: Result) {
        // If already initialized, just return success to avoid recreating the client
        if (::placesClient.isInitialized) {
            // Ensure session token exists
            if (sessionToken == null) {
                sessionToken = AutocompleteSessionToken.newInstance()
            }
            result.success(null)
            return
        }

        val apiKey = call.argument<String>("apiKey") ?: getApiKeyFromManifest()

        if (apiKey == null) {
            result.error("MISSING_API_KEY", "API Key not found in MethodCall or Manifest", null)
            return
        }

        if (!Places.isInitialized()) {
            Places.initialize(context, apiKey)
        }
        placesClient = Places.createClient(context)
        // Create a new session token for the start
        sessionToken = AutocompleteSessionToken.newInstance()
        result.success(null)
    }

    private fun getPredictions(call: MethodCall, result: Result) {
        if (!::placesClient.isInitialized) {
            result.error("NOT_INITIALIZED", "Places Client not initialized", null)
            return
        }

        val query = call.argument<String>("query") ?: ""
        val countries = call.argument<List<String>>("countries")
        val placeTypes = call.argument<List<String>>("placeTypes")

        // Ensure session token exists
        if (sessionToken == null) {
             sessionToken = AutocompleteSessionToken.newInstance()
        }

        val requestBuilder = FindAutocompletePredictionsRequest.builder()
            .setSessionToken(sessionToken)
            .setQuery(query)

        if (countries != null && countries.isNotEmpty()) {
            requestBuilder.setCountries(countries)
        }
        
        if (placeTypes != null && placeTypes.isNotEmpty()) {
             requestBuilder.setTypesFilter(placeTypes)
        }

        placesClient.findAutocompletePredictions(requestBuilder.build())
            .addOnSuccessListener { response ->
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
            }
            .addOnFailureListener { exception ->
                result.error("PREDICTION_ERROR", exception.message, null)
            }
    }

    private fun getPlaceDetails(call: MethodCall, result: Result) {
        if (!::placesClient.isInitialized) {
            result.error("NOT_INITIALIZED", "Places Client not initialized", null)
            return
        }

        val placeId = call.argument<String>("placeId")
        if (placeId == null) {
            result.error("INVALID_ARGUMENT", "Place ID is missing", null)
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

        val request = FetchPlaceRequest.builder(placeId, placeFields)
            .setSessionToken(sessionToken)
            .build()

        placesClient.fetchPlace(request)
            .addOnSuccessListener { response ->
                // Session Token consumed, nullify it so next search creates a new one
                sessionToken = null
                
                val place = response.place
                val details = mutableMapOf<String, Any?>()
                
                // Basic fields
                details["placeId"] = place.id
                details["name"] = place.displayName
                details["formattedAddress"] = place.formattedAddress
                
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
                
                result.success(details)
            }
            .addOnFailureListener { exception ->
                result.error("PLACE_DETAILS_ERROR", exception.message, null)
            }
    }

    private fun getApiKeyFromManifest(): String? {
        return try {
            val appInfo = context.packageManager.getApplicationInfo(
                context.packageName,
                PackageManager.GET_META_DATA
            )
            appInfo.metaData?.getString("com.google.android.geo.API_KEY")
        } catch (e: Exception) {
            null
        }
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}
