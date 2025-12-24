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

        val placeFields = listOf(
            Place.Field.ID,
            Place.Field.NAME,
            Place.Field.ADDRESS,
            Place.Field.LAT_LNG,
            Place.Field.PHONE_NUMBER,
            Place.Field.WEBSITE_URI,
            Place.Field.RATING,
            Place.Field.USER_RATINGS_TOTAL,
            Place.Field.ADDRESS_COMPONENTS
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
                details["placeId"] = place.id
                details["name"] = place.name
                details["formattedAddress"] = place.address
                details["phoneNumber"] = place.phoneNumber
                details["websiteUri"] = place.websiteUri?.toString()
                details["rating"] = place.rating
                details["userRatingsTotal"] = place.userRatingsTotal

                if (place.latLng != null) {
                    details["location"] = mapOf(
                        "lat" to place.latLng!!.latitude,
                        "lng" to place.latLng!!.longitude
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
