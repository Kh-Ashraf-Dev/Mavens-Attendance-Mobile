import 'package:geolocator/geolocator.dart';

class LocationService {
  Future<Map<String, dynamic>> capture() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw Exception('Turn on location services to check in on site.');
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw Exception(
        'Location permission is required. Enable it in your device settings.',
      );
    }
    final p = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 25),
      ),
    );
    return {
      'latitude': p.latitude,
      'longitude': p.longitude,
      'accuracy': p.accuracy,
      'capturedAt': p.timestamp.toUtc().toIso8601String(),
      'mocked': p.isMocked,
    };
  }
}
