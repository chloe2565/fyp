import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../../controller/handyman.dart';

class ProviderServiceReqMapScreen extends StatelessWidget {
  final String reqID;

  const ProviderServiceReqMapScreen({super.key, required this.reqID});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => HandymanController(reqID, userRole: 'admin'),
      child: Consumer<HandymanController>(
        builder: (context, controller, child) {
          switch (controller.state) {
            case TrackingState.loading:
              return buildLoadingScaffold(controller.message);
            case TrackingState.invalidRequest:
            case TrackingState.notFound:
            case TrackingState.error:
              return buildErrorScaffold(controller.message);
            case TrackingState.tracking:
              return buildMapUI(context, controller);
          }
        },
      ),
    );
  }

  Widget buildMapUI(BuildContext context, HandymanController controller) {
    final LatLng initialMapCenter = LatLng(
      controller.userLocation?.latitude ?? 5.4164,
      controller.userLocation?.longitude ?? 100.3327,
    );

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacementNamed(context, '/custHome');
            }
          },
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: const Text(
          'Handyman Location',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: buildEtaCardContent(context, controller),
              ),
            ),
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12.0),
                child: GoogleMap(
                  onMapCreated: (GoogleMapController mapController) {
                    controller.setGoogleMapController(mapController);
                  },
                  initialCameraPosition: CameraPosition(
                    target: initialMapCenter,
                    zoom: 15.0,
                  ),
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  markers: buildMarkers(controller),
                  polylines: buildPolylines(controller),
                  mapType: MapType.normal,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Set<Marker> buildMarkers(HandymanController controller) {
    final Set<Marker> markers = {};

    // Customer location marker (red pin)
    if (controller.userLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('customer_location'),
          position: controller.userLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: const InfoWindow(title: 'Customer Location'),
        ),
      );
    }

    // Handyman current location marker (orange)
    if (controller.handymanLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('handyman_location'),
          position: controller.handymanLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueOrange,
          ),
          infoWindow: const InfoWindow(title: 'Handyman'),
        ),
      );
    }

    return markers;
  }

  Set<Polyline> buildPolylines(HandymanController controller) {
    final Set<Polyline> polylines = {};

    if (controller.routePoints.isNotEmpty) {
      polylines.add(
        Polyline(
          polylineId: const PolylineId('route'),
          points: controller.routePoints,
          color: Colors.blue,
          width: 5,
        ),
      );
    }

    return polylines;
  }

  Widget buildEtaCardContent(
    BuildContext context,
    HandymanController controller,
  ) {
    if (controller.hasArrived) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 5.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 30),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Handyman has arrived!",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                Text(
                  "At customer location",
                  style: TextStyle(fontSize: 14, color: Colors.green.shade700),
                ),
              ],
            ),
          ],
        ),
      );
    }

    String etaText = "Calculating ETA...";
    String arrivalTimeText = controller.arrivalTime;
    final bool isRouteLoading = controller.isRouteLoading;

    if (controller.etaInMinutes != null) {
      etaText = "in ${controller.etaInMinutes} minutes";
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isRouteLoading)
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        if (isRouteLoading) const SizedBox(width: 16),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Estimated Time Arrival to Destination",
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),
            const SizedBox(height: 4),
            RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
                children: [
                  TextSpan(text: '$etaText : '),
                  if (arrivalTimeText.isNotEmpty)
                    TextSpan(
                      text: arrivalTimeText,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Scaffold buildLoadingScaffold(String message) {
    return Scaffold(
      appBar: AppBar(title: const Text("Handyman Location")),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(message),
          ],
        ),
      ),
    );
  }

  Scaffold buildErrorScaffold(String message) {
    return Scaffold(
      appBar: AppBar(title: const Text("Tracking Error")),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, color: Colors.black54),
          ),
        ),
      ),
    );
  }
}
