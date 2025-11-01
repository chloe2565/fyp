import 'dart:io';

import '../model/reviewDisplayViewModel.dart' show ReviewDisplayData;
import '../service/service.dart';
import '../model/databaseModel.dart';
import '../service/ratingReview.dart';
import '../service/servicePicture.dart';

class ServiceController {
  final RatingReviewService ratingReviewService = RatingReviewService();
  final ServicePictureService pictureService = ServicePictureService();
  late final ServiceService serviceService;

  List<ServiceModel> allServicesData = [];
  bool servicesLoaded = false;

  ServiceController() {
    serviceService = ServiceService(
      ratingReviewService: ratingReviewService,
      servicePictureService: pictureService,
    );
  }

  Future<void> loadServices({bool refresh = false}) async {
    if (servicesLoaded && !refresh) return;

    try {
      allServicesData = await serviceService.getAllServices();
      servicesLoaded = true;
    } catch (e) {
      print('ServiceController Error: $e');
      allServicesData = [];
      servicesLoaded = false;
      rethrow;
    }
  }

  List<ServiceModel> get allServices => allServicesData;

  List<ServiceModel> get servicesForGrid {
    return allServicesData.take(8).toList();
  }

  List<ServiceModel> get popularServicesForList {
    final popular = allServicesData.length > 8
        ? allServicesData.sublist(8)
        : <ServiceModel>[];

    return popular.take(3).toList();
  }

  bool get hasPopularServices => popularServicesForList.isNotEmpty;

  bool get showMoreIconInGrid {
    return servicesForGrid.length >= 7;
  }

  int get serviceIconCountInGrid {
    return servicesForGrid.length < 7 ? servicesForGrid.length : 7;
  }

  int get gridItemCount {
    return serviceIconCountInGrid + (showMoreIconInGrid ? 1 : 0);
  }

  Future<List<ServiceModel>> getAllServices() async {
    if (!servicesLoaded) {
      await loadServices();
    }
    return allServicesData;
  }

  Future<List<ServicePictureModel>> getPicturesForService(
    String serviceID,
  ) async {
    return await pictureService.getPicturesForService(serviceID);
  }

  Future<ServiceAggregates> getServiceAggregates(String serviceID) async {
    return await serviceService.getServiceAggregates(serviceID);
  }

  Future<List<ReviewDisplayData>> getReviewsForService(String serviceID) async {
    return await serviceService.getReviewsForService(serviceID);
  }

  // Employee side
  Future<List<String>> getAssignedHandymanNames(String serviceID) async {
    return await serviceService.getAssignedHandymanNames(serviceID);
  }

  Future<String> generateNextID() async {
    return await serviceService.generateNextID();
  }

  Future<List<ServiceModel>> empGetAllServices() async {
    return await serviceService.empGetAllServices();
  }

  Future<Map<String, String>> getAllHandymenMap() async {
    return await serviceService.getAllHandymenMap();
  }

  Future<void> addNewService(
    ServiceModel service,
    List<String> handymanIDs,
    List<File> photos,
  ) async {
    try {
      final List<String> photoFileNames = [];

      if (photos.isNotEmpty) {
        final copyFutures = photos.asMap().entries.map((entry) async {
          final i = entry.key;
          final photo = entry.value;
          final String extension = photo.path.split('.').last;
          final String newName =
              '${service.serviceID}_${DateTime.now().millisecondsSinceEpoch}_$i.$extension';
          return newName;
        });

        photoFileNames.addAll(await Future.wait(copyFutures));
        print('Images copied locally: $photoFileNames');
      }

      await serviceService.addNewService(service, handymanIDs, photoFileNames);
    } catch (e) {
      print('Error in Controller addNewService: $e');
      rethrow;
    }
  }

  Future<Map<String, String>> getAssignedHandymenMap(String serviceID) async {
    return await serviceService.getAssignedHandymenMap(serviceID);
  }

  Future<void> updateService(
    ServiceModel service,
    List<String> handymanIDs,
    List<File> newPhotos,
  ) async {
    try {
      List<String> newPhotoNames = [];
      for (var i = 0; i < newPhotos.length; i++) {
        final photo = newPhotos[i];
        final String extension = photo.path.split('.').last;
        final String newName =
            '${service.serviceID}_${DateTime.now().millisecondsSinceEpoch}_$i.$extension';
        newPhotoNames.add(newName);
      }
      print('Simulating upload for new photos: $newPhotoNames');

      await serviceService.updateService(service, handymanIDs, newPhotoNames);
    } catch (e) {
      print('Error in Controller updateService: $e');
      rethrow;
    }
  }

  Future<void> deleteService(String serviceID) async {
    return await serviceService.deleteService(serviceID);
  }
}
