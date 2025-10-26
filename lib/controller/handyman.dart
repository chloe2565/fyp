import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:osm_nominatim/osm_nominatim.dart';
import 'package:intl/intl.dart';
import '../../model/databaseModel.dart';
import '../service/firestore_service.dart';
import '../service/handyman.dart';
import '../service/serviceRequest.dart';

enum TrackingState { loading, tracking, invalidRequest, notFound, error }

class HandymanController extends ChangeNotifier {
  final FirebaseFirestore db = FirestoreService.instance.db;
  final ServiceRequestService serviceRequest = ServiceRequestService();
  final HandymanService handyman = HandymanService();
  final MapController mapController = MapController();
  final String reqID;

  StreamSubscription? requestSubscription;
  StreamSubscription? handymanSubscription;
  String? currentHandymanId;
  TrackingState state = TrackingState.loading;
  String message = "Initializing...";

  LatLng? userLocation;
  LatLng? handymanLocation;
  List<LatLng> routePoints = [];
  int? etaInMinutes;
  String arrivalTime = "";

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
      geocodeAddress(request.reqAddress, request.handymanID);
    } else {
      handymanSubscription?.cancel();
      currentHandymanId = null;
      setState(
        TrackingState.invalidRequest,
        "Tracking is only available for 'departed' requests scheduled for today.\n\nCurrent Status: ${request.reqStatus}",
      );
    }
  }

  Future<void> geocodeAddress(String address, String handymanID) async {
    if (userLocation != null || isGeocoding) return;

    isGeocoding = true;
    setState(TrackingState.loading, "Finding Service Address...");

    try {
      final nominatim = Nominatim(userAgent: 'com.example.fyp');
      final result = await nominatim.searchByName(query: address, limit: 1);
      if (result.isNotEmpty) {
        userLocation = LatLng(result.first.lat, result.first.lon);
        isGeocoding = false;

        subscribeToHandymanLocation(handymanID);
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

  void subscribeToHandymanLocation(String handymanID) {
    if (currentHandymanId == handymanID) return;

    handymanSubscription?.cancel();
    currentHandymanId = handymanID;

    handymanSubscription = handyman
        .getHandymanStream(handymanID)
        .listen(
          (handyman) {
            final newLocation = LatLng(
              handyman.currentLocation.latitude,
              handyman.currentLocation.longitude,
            );

            if (newLocation.latitude == 0 && newLocation.longitude == 0) {
              setState(TrackingState.tracking, "");
              return;
            }

            if (newLocation != handymanLocation) {
              handymanLocation = newLocation;
              fetchRouteAndEta();
            }
            setState(TrackingState.tracking, "");
          },
          onError: (e) {
            setState(
              TrackingState.error,
              "Error tracking handyman: ${e.toString()}",
            );
          },
        );
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
        etaInMinutes = (duration / 60).round();

        final newArrivalTime = DateTime.now().add(
          Duration(minutes: etaInMinutes!),
        );
        arrivalTime = DateFormat('hh:mm a').format(newArrivalTime);

        final geometry = route['geometry']['coordinates'] as List<dynamic>;
        routePoints = geometry
            .map((coord) => LatLng(coord[1] as double, coord[0] as double))
            .toList();

        final bounds = LatLngBounds(handymanLocation!, userLocation!);

        mapController.fitCamera(
          CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(50.0)),
        );
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

  void setState(TrackingState newState, String newMessage) {
    state = newState;
    message = newMessage;
    notifyListeners();
  }

  @override
  void dispose() {
    requestSubscription?.cancel();
    handymanSubscription?.cancel();
    mapController.dispose();
    super.dispose();
  }
}
