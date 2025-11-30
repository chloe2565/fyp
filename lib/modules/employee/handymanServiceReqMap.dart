import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../../controller/handyman.dart';

class HandymanServiceReqMapScreen extends StatelessWidget {
  final String reqID;

  const HandymanServiceReqMapScreen({super.key, required this.reqID});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => HandymanController(reqID, userRole: 'handyman'),
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
      controller.handymanLocation?.latitude ??
          controller.userLocation?.latitude ??
          5.4164,
      controller.handymanLocation?.longitude ??
          controller.userLocation?.longitude ??
          100.3327,
    );

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacementNamed(context, '/empHome');
            }
          },
        ),
        title: const Text(
          'Route to Destination',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location, color: Colors.black),
            tooltip: 'Recenter Map',
            onPressed: () {
              controller.recenterMap();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Google Map
          GoogleMap(
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

          DraggableScrollableSheet(
            initialChildSize: 0.25,
            minChildSize: 0.1,
            maxChildSize: 0.5,
            builder: (BuildContext context, ScrollController scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 5,
                        margin: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),

                    buildEtaCardContent(context, controller),
                    buildAddressCardContent(context, controller),

                    if (controller.routeDistance != null &&
                        controller.routeDuration != null)
                      buildRouteInfoCard(controller),
                    const SizedBox(height: 20),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Set<Marker> buildMarkers(HandymanController controller) {
    final Set<Marker> markers = {};

    // Customer location marker
    if (controller.userLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('customer_location'),
          position: LatLng(
            controller.userLocation!.latitude,
            controller.userLocation!.longitude,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: const InfoWindow(title: 'Customer Location'),
        ),
      );
    }

    // Handyman current location marker
    if (controller.handymanLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('handyman_location'),
          position: LatLng(
            controller.handymanLocation!.latitude,
            controller.handymanLocation!.longitude,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
          infoWindow: const InfoWindow(title: 'Handyman Location'),
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
          points: controller.routePoints
              .map((point) => LatLng(point.latitude, point.longitude))
              .toList(),
          color: Colors.green,
          width: 6,
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
        padding: const EdgeInsets.symmetric(vertical: 10.0),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.green.shade200)
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 30),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Arrived!",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                Text(
                  "At destination",
                  style: TextStyle(fontSize: 14, color: Colors.green.shade700),
                ),
              ],
            ),
          ],
        ),
      );
    }

    String arrivalTimeText = "Calculating...";
    String etaText = "Calculating ETA...";
    final bool isRouteLoading = controller.isRouteLoading;

    if (controller.arrivalTime.isNotEmpty) {
      arrivalTimeText = controller.arrivalTime;
    }
    if (controller.etaInMinutes != null) {
      etaText = "in ${controller.etaInMinutes} minutes";
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        children: [
          if (isRouteLoading)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          if (isRouteLoading) const SizedBox(width: 16),
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 20,
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                    children: [
                      const TextSpan(text: 'Arrive in '),
                      TextSpan(
                        text: isRouteLoading ? "..." : arrivalTimeText,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isRouteLoading ? "Calculating route..." : etaText,
                  style: const TextStyle(fontSize: 15, color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildAddressCardContent(
    BuildContext context,
    HandymanController controller,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 4.0, left: 4.0),
                child: Icon(Icons.circle, color: Colors.blue, size: 12),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  controller.currentAddress,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          // Dotted line
          Padding(
            padding: const EdgeInsets.only(left: 10.0, top: 4.0, bottom: 4.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                height: 20,
                width: 2,
                color: Colors.grey.shade300,
              ),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 4.0, left: 4.0),
                child: Icon(Icons.location_on, color: Colors.red, size: 14),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  controller.destinationAddress,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildRouteInfoCard(HandymanController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(
            children: [
              const Icon(Icons.route, color: Colors.blue),
              const SizedBox(height: 4),
              Text(
                '${(controller.routeDistance! / 1000).toStringAsFixed(1)} km',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const Text(
                'Distance',
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
          Container(height: 40, width: 1, color: Colors.grey[300]),
          Column(
            children: [
              const Icon(Icons.access_time, color: Colors.orange),
              const SizedBox(height: 4),
              Text(
                '${(controller.routeDuration! / 60).round()} min',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const Text(
                'Duration',
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
        ],
      ),
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