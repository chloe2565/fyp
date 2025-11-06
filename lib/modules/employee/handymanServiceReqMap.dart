import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../controller/handyman.dart';

class HandymanServiceReqMapScreen extends StatelessWidget {
  final String reqID;

  const HandymanServiceReqMapScreen({super.key, required this.reqID});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => HandymanController(reqID),
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
    final LatLng initialMapCenter =
        controller.handymanLocation ??
        controller.userLocation ??
        const LatLng(5.4164, 100.3327);

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
          // Map
          FlutterMap(
            mapController: controller.mapController,
            options: MapOptions(
              initialCenter: initialMapCenter,
              initialZoom: 15.0,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.fyp',
              ),
              if (controller.routePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: controller.routePoints,
                      color: Colors.green,
                      strokeWidth: 6.0,
                    ),
                  ],
                ),
              MarkerLayer(
                markers: [
                  // Customer location
                  if (controller.userLocation != null)
                    Marker(
                      width: 80.0,
                      height: 80.0,
                      point: controller.userLocation!,
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.red,
                        size: 40,
                      ),
                    ),
                  // Handyman current location
                  if (controller.handymanLocation != null)
                    Marker(
                      width: 80.0,
                      height: 80.0,
                      point: controller.handymanLocation!,
                      child: const Icon(
                        Icons.construction,
                        color: Colors.orange,
                        size: 40,
                      ),
                    ),
                ],
              ),
            ],
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
                      color: Colors.black.withOpacity(0.2),
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

  Widget buildEtaCardContent(
    BuildContext context,
    HandymanController controller,
  ) {
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
