import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:osm_nominatim/osm_nominatim.dart';
import 'package:intl/intl.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import '../../model/databaseModel.dart';
import '../../service/firestore_service.dart';
import '../../service/handyman.dart';
import '../../service/serviceRequest.dart';

enum TrackingState { loading, tracking, invalidRequest, notFound, error }

class HandymanController extends ChangeNotifier {
  final FirebaseFirestore db = FirestoreService.instance.db;
  final ServiceRequestService serviceRequest = ServiceRequestService();
  final HandymanService handyman = HandymanService();
  final MapController mapController = MapController();
  final String reqID;

  StreamSubscription? requestSubscription;
  StreamSubscription<Position>? positionStreamSubscription;
  String? currentHandymanId;
  TrackingState state = TrackingState.loading;
  String message = "Initializing...";

  LatLng? userLocation; // Customer's address location
  LatLng? handymanLocation; // Handyman's current location
  List<LatLng> routePoints = [];
  double? routeDistance; // in meters
  double? routeDuration; // in seconds
  int? etaInMinutes;
  String arrivalTime = "";

  String currentAddress = "Finding location...";
  String destinationAddress = "Loading destination...";

  bool isGeocoding = false;
  bool isRouteLoading = false;
  ServiceRequestModel? currentRequest;

  HandymanController(this.reqID) {
    initialize();
  }

  void initialize() {
    requestSubscription?.cancel();
    requestSubscription = serviceRequest
        .getRequestStream(reqID)
        .listen(
          (request) {
            currentRequest = request;
            validateRequestStatus(request);
          },
          onError: (e) {
            setState(TrackingState.notFound, "Error: ${e.toString()}");
          },
        );
  }

  void validateRequestStatus(ServiceRequestModel request) {
    final now = DateTime.now();
    final isToday = DateUtils.isSameDay(request.scheduledDateTime, now);

    if (request.reqStatus == 'departed' && isToday) {
      currentHandymanId = request.handymanID;
      geocodeAddress(request.reqAddress);
    } else {
      positionStreamSubscription?.cancel();
      currentHandymanId = null;
      setState(
        TrackingState.invalidRequest,
        "Tracking is only available for 'departed' requests scheduled for today.\n\nCurrent Status: ${request.reqStatus}",
      );
    }
  }

  Future<void> geocodeAddress(String address) async {
    if (userLocation != null || isGeocoding) return;

    isGeocoding = true;
    setState(TrackingState.loading, "Finding Service Address...");

    try {
      final nominatim = Nominatim(userAgent: 'com.example.fyp');
      final result = await nominatim.searchByName(query: address, limit: 1);
      if (result.isNotEmpty) {
        userLocation = LatLng(result.first.lat, result.first.lon);
        destinationAddress = address;
        isGeocoding = false;

        startLiveLocationUpdates();
      } else {
        throw Exception("Address not found.");
      }
    } catch (e) {
      isGeocoding = false;
      setState(
        TrackingState.error,
        "Error: Could not find address. ${e.toString()}",
      );
    }
  }

  Future<void> startLiveLocationUpdates() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(TrackingState.error, "Location services are disabled.");
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(TrackingState.error, "Location permissions are denied.");
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(
        TrackingState.error,
        "Location permissions are permanently denied.",
      );
      return;
    }
    positionStreamSubscription =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 10,
          ),
        ).listen((Position position) {
          final newLocation = LatLng(position.latitude, position.longitude);

          bool isFirstLocation = handymanLocation == null;
          handymanLocation = newLocation;

          fetchRouteAndEta();
          reverseGeocodeCurrentLocation(newLocation);

          if (currentHandymanId != null) {
            updateHandymanLocationInDb(newLocation);
          }

          if (isFirstLocation) {
            fitMapToRoute();
          } else {
            mapController.move(newLocation, mapController.camera.zoom);
          }

          setState(TrackingState.tracking, "");
        });
  }

  Future<void> updateHandymanLocationInDb(LatLng location) async {
    if (currentHandymanId == null) return;
    await handyman.updateHandymanLocation(
      currentHandymanId!,
      GeoPoint(location.latitude, location.longitude),
    );
  }

  String formatPlacemark(Placemark p) {
    String line1 = [
      p.subThoroughfare ?? '',
      p.thoroughfare ?? '',
    ].where((s) => s.isNotEmpty).join(' ');
    if (line1.isEmpty) {
      line1 = p.street ?? p.name ?? '';
    }
    String line2 = [
      p.locality ?? '',
      p.administrativeArea ?? '',
      p.postalCode ?? '',
    ].where((s) => s.isNotEmpty).join(', ');
    String line3 = p.country ?? '';
    String fullAddress = [
      line1,
      line2,
      line3,
    ].where((s) => s.isNotEmpty).join('\n');
    return fullAddress.isEmpty ? "Unknown Location" : fullAddress;
  }

  Future<void> reverseGeocodeCurrentLocation(LatLng location) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      );
      if (placemarks.isNotEmpty) {
        currentAddress = formatPlacemark(placemarks.first);
        notifyListeners();
      }
    } catch (e) {
      print("Error reverse geocoding current location: $e");
    }
  }

  Future<void> fetchRouteAndEta() async {
    if (handymanLocation == null ||
        userLocation == null ||
        isRouteLoading ||
        (handymanLocation!.latitude == 0 && handymanLocation!.longitude == 0)) {
      return;
    }
    isRouteLoading = true;
    notifyListeners();
    final service = 'https://router.project-osrm.org/route/v1/driving';
    final coords =
        '${handymanLocation!.longitude},${handymanLocation!.latitude};${userLocation!.longitude},${userLocation!.latitude}';
    final url = '$service/$coords?overview=full&geometries=geojson';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final route = data['routes'][0];
        final duration = route['duration'] as double;
        routeDuration = duration;
        etaInMinutes = (duration / 60).round();
        final distance = route['distance'] as double;
        routeDistance = distance;
        final newArrivalTime = DateTime.now().add(
          Duration(minutes: etaInMinutes!),
        );
        arrivalTime = DateFormat('hh:mm a').format(newArrivalTime);
        final geometry = route['geometry']['coordinates'] as List<dynamic>;
        routePoints = geometry
            .map((coord) => LatLng(coord[1] as double, coord[0] as double))
            .toList();
      } else {
        print(
          'Route Error: Failed to load route. Status: ${response.statusCode}',
        );
      }
    } catch (e) {
      print("Route Error: ${e.toString()}");
    } finally {
      isRouteLoading = false;
      notifyListeners();
    }
  }

  void fitMapToRoute() {
    if (handymanLocation == null || userLocation == null) return;
    try {
      double minLat = handymanLocation!.latitude < userLocation!.latitude
          ? handymanLocation!.latitude
          : userLocation!.latitude;
      double maxLat = handymanLocation!.latitude > userLocation!.latitude
          ? handymanLocation!.latitude
          : userLocation!.latitude;
      double minLng = handymanLocation!.longitude < userLocation!.longitude
          ? handymanLocation!.longitude
          : userLocation!.longitude;
      double maxLng = handymanLocation!.longitude > userLocation!.longitude
          ? handymanLocation!.longitude
          : userLocation!.longitude;
      final latPadding = (maxLat - minLat) * 0.2;
      final lngPadding = (maxLng - minLng) * 0.2;
      final bounds = LatLngBounds(
        LatLng(minLat - latPadding, minLng - lngPadding),
        LatLng(maxLat + latPadding, maxLng + lngPadding),
      );
      mapController.fitCamera(
        CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(50.0)),
      );
    } catch (e) {
      print("Error fitting map to route: $e");
    }
  }

  void recenterMap() {
    if (handymanLocation != null) {
      mapController.move(handymanLocation!, 15.0);
    } else if (userLocation != null) {
      mapController.move(userLocation!, 15.0);
    }
  }

  void setState(TrackingState newState, String newMessage) {
    state = newState;
    message = newMessage;
    notifyListeners();
  }

  @override
  void dispose() {
    requestSubscription?.cancel();
    positionStreamSubscription?.cancel();
    mapController.dispose();
    super.dispose();
  }
}
