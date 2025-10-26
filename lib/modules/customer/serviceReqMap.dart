import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../controller/handyman.dart';

class ServiceReqMapScreen extends StatelessWidget {
  final String reqID;

  const ServiceReqMapScreen({super.key, required this.reqID});

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
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacementNamed(context, '/home');
            }
          },
        ),
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
                child: FlutterMap(
                  mapController: controller.mapController,
                  options: MapOptions(
                    initialCenter:
                        controller.userLocation ??
                        const LatLng(5.4164, 100.3327),
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
                            color: Colors.blue,
                            strokeWidth: 5,
                          ),
                        ],
                      ),
                    MarkerLayer(
                      markers: [
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
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildEtaCardContent(
    BuildContext context,
    HandymanController controller,
  ) {
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
              "Estimated Time Arrival to destination",
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
                      text: '$arrivalTimeText',
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
