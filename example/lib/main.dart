import 'package:flutter/material.dart';
import 'package:google_places_autocomplete/google_places_autocomplete.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Google Places Autocomplete Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const PlacesAutocompleteScreen(),
    );
  }
}

class PlacesAutocompleteScreen extends StatefulWidget {
  const PlacesAutocompleteScreen({super.key});

  @override
  State<PlacesAutocompleteScreen> createState() =>
      _PlacesAutocompleteScreenState();
}

class _PlacesAutocompleteScreenState extends State<PlacesAutocompleteScreen> {
  final _searchController = TextEditingController();
  late GooglePlacesAutocomplete _placesService;

  List<Prediction> _predictions = [];
  bool _isLoading = false;
  PlaceDetails? _selectedPlace;
  bool _isInitialized = false;

  // Example user location (San Francisco)
  // In production, get this from Geolocator or location services
  static const double _userLat = 37.7749;
  static const double _userLng = -122.4194;

  @override
  void initState() {
    super.initState();
    // Initialize the places service
    // Note: Initialization is async and connects to the native platform
    _initPlacesService();
  }

  Future<void> _initPlacesService() async {
    _placesService = GooglePlacesAutocomplete(
      // 1. API Key:
      // The package will automatically read 'com.google.android.geo.API_KEY' from AndroidManifest
      // and 'GOOGLE_PLACES_API_KEY' from Info.plist.
      // You can also pass it explicitly here:
      // apiKey: 'YOUR_API_KEY',

      // 2. Distance:
      // Provide user location to get distance metrics in predictions
      originLat: _userLat,
      originLng: _userLng,

      // 3. Filters:
      // Optional: Filter by country (ISO 3166-1 Alpha-2)
      countries: ['us'],
      // Optional: Filter by place types
      // placeTypes: ['restaurant'],

      // 4. UI Updates:
      debounceTime: 500, // Smoother typing experience
      predictionsListener: (predictions) {
        if (mounted) {
          setState(() => _predictions = predictions);
        }
      },
      loadingListener: (isLoading) {
        if (mounted) {
          setState(() => _isLoading = isLoading);
        }
      },
      // 5. Error Handling:
      // Handle errors gracefully with the onError callback
      onError: (error) {
        debugPrint('Places API Error: ${error.code} - ${error.message}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${error.message}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
    );

    try {
      await _placesService.initialize();
      if (mounted) {
        setState(() => _isInitialized = true);
      }
    } catch (e) {
      debugPrint("Failed to initialize Places Service: $e");
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _placesService.dispose(); // Important: dispose the places service
    super.dispose();
  }

  Future<void> _onPredictionTap(Prediction prediction) async {
    if (prediction.placeId == null) return;

    final details = await _placesService.getPlaceDetails(prediction.placeId!);

    if (mounted && details != null) {
      setState(() {
        _selectedPlace = details;
        _predictions = [];
        _searchController.text = prediction.title ?? '';
      });
    }
  }

  /// Format distance in a human-readable way
  String _formatDistance(int meters) {
    if (meters >= 1000) {
      final km = meters / 1000;
      return km >= 10 ? '${km.round()} km' : '${km.toStringAsFixed(1)} km';
    }
    return '$meters m';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Places Autocomplete'),
        centerTitle: true,
      ),
      body: !_isInitialized
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Search Field
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search for a place...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _isLoading
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          : _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _predictions = []);
                                  },
                                )
                              : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: (value) {
                      if (value.isNotEmpty) {
                        _placesService.getPredictions(value);
                      } else {
                        setState(() => _predictions = []);
                      }
                    },
                  ),

                  const SizedBox(height: 16),

                  // Predictions List
                  Expanded(
                    child: _predictions.isEmpty
                        ? _buildEmptyState()
                        : ListView.separated(
                            itemCount: _predictions.length,
                            separatorBuilder: (_, __) => const Divider(),
                            itemBuilder: (context, index) {
                              final prediction = _predictions[index];
                              return _buildPredictionTile(prediction);
                            },
                          ),
                  ),

                  // Selected Place Details
                  if (_selectedPlace != null) ...[
                    const Divider(height: 32),
                    _buildPlaceDetails(_selectedPlace!, theme),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Text(
        _searchController.text.isEmpty
            ? 'Start typing to search'
            : 'No results found',
        style: TextStyle(color: Colors.grey[600]),
      ),
    );
  }

  Widget _buildPredictionTile(Prediction prediction) {
    return ListTile(
      leading: const CircleAvatar(
        child: Icon(Icons.location_on, size: 20),
      ),
      title: Text(
        prediction.title ?? '',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        prediction.description ?? '',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: Colors.grey[600]),
      ),
      // NEW: Distance badge
      trailing: prediction.distanceMeters != null
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _formatDistance(prediction.distanceMeters!),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            )
          : null,
      onTap: () => _onPredictionTap(prediction),
    );
  }

  Widget _buildPlaceDetails(PlaceDetails details, ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              details.name ?? 'Selected Place',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            if (details.formattedAddress != null)
              Row(
                children: [
                  const Icon(Icons.location_on, size: 16, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(child: Text(details.formattedAddress!)),
                ],
              ),
            if (details.location != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.pin_drop, size: 16, color: Colors.purple),
                  const SizedBox(width: 8),
                  Text(
                    '${details.location!.lat.toStringAsFixed(4)}, ${details.location!.lng.toStringAsFixed(4)}',
                    style: const TextStyle(fontFamily: 'monospace'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
