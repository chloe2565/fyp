import 'dart:io';
import '../model/reviewDisplayViewModel.dart' show ReviewDisplayData;
import '../service/service.dart';
import '../model/databaseModel.dart';
import '../service/ratingReview.dart';
import '../service/servicePicture.dart';
import '../service/image_service.dart';

class ServiceController {
  final RatingReviewService ratingReviewService = RatingReviewService();
  final ServicePictureService pictureService = ServicePictureService();
  final FirebaseImageService imageService = FirebaseImageService();
  late final ServiceService serviceService;

  List<ServiceModel> allServicesData = [];
  List<ServiceModel> topPopularServices = [];
  bool servicesLoaded = false;
  Map<String, String> serviceHandymanMap = {};

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
      topPopularServices = await serviceService
          .getTopServicesByCompletedRequests(3);
      servicesLoaded = true;
    } catch (e) {
      print('ServiceController Error: $e');
      allServicesData = [];
      servicesLoaded = false;
      rethrow;
    }
  }

  Future<List<ServiceModel>> loadServicesForEmployeeView(bool isAdmin) async {
    try {
      final services = await serviceService.empGetAllServices();

      if (isAdmin) {
        serviceHandymanMap.clear();
        final futures = services.map((service) async {
          final names = await serviceService.getAssignedHandymanNames(
            service.serviceID,
          );
          final namesString = names.isEmpty ? 'Unassigned' : names.join(', ');
          return MapEntry(service.serviceID, namesString);
        });

        final results = await Future.wait(futures);
        serviceHandymanMap = Map.fromEntries(results);
      }

      return services;
    } catch (e) {
      print('Error in loadServicesForEmployeeView: $e');
      rethrow;
    }
  }

  String? getHandymanNameForService(String serviceID) {
    return serviceHandymanMap[serviceID];
  }

  List<ServiceModel> get allServices => allServicesData;

  List<ServiceModel> get servicesForGrid {
    return allServicesData.take(8).toList();
  }

  List<ServiceModel> get popularServicesForList {
    return topPopularServices;
  }

  bool get hasPopularServices => topPopularServices.isNotEmpty;

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
      final List<String> uploadedUrls = [];

      // Upload images to Firebase Storage
      if (photos.isNotEmpty) {
        print('Uploading ${photos.length} images to Firebase Storage...');
        for (int i = 0; i < photos.length; i++) {
          final photo = photos[i];
          final String? url = await imageService.uploadImage(
            imageFile: photo,
            category: ImageCategory.services,
            uniqueId: service.serviceID,
          );

          if (url != null) {
            uploadedUrls.add(url);
            print('Image ${i + 1} uploaded successfully');
          } else {
            print('Failed to upload image ${i + 1}');
          }
        }
      }

      if (uploadedUrls.isEmpty && photos.isNotEmpty) {
        throw Exception('Failed to upload any images');
      }

      // Save service with Firebase Storage URLs
      await serviceService.addNewService(service, handymanIDs, uploadedUrls);
      print('Service added with ${uploadedUrls.length} images');
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
    List<File> newPhotos, {
    List<String> removedPicUrls = const [],
  }) async {
    try {
      final List<String> uploadedUrls = [];

      // Upload new images to Firebase Storage
      if (newPhotos.isNotEmpty) {
        print(
          'Uploading ${newPhotos.length} new images to Firebase Storage...',
        );
        for (int i = 0; i < newPhotos.length; i++) {
          final photo = newPhotos[i];
          final String? url = await imageService.uploadImage(
            imageFile: photo,
            category: ImageCategory.services,
            uniqueId: service.serviceID,
          );

          if (url != null) {
            uploadedUrls.add(url);
            print('New image ${i + 1} uploaded successfully');
          } else {
            print('Failed to upload new image ${i + 1}');
          }
        }
      }

      // Delete removed images from Firebase Storage
      if (removedPicUrls.isNotEmpty) {
        print(
          'Deleting ${removedPicUrls.length} images from Firebase Storage...',
        );
        await imageService.deleteMultipleImages(removedPicUrls);
      }

      // Update service
      await serviceService.updateService(
        service,
        handymanIDs,
        uploadedUrls,
        removedPicUrls: removedPicUrls,
      );
      print('Service updated with ${uploadedUrls.length} new images');
    } catch (e) {
      print('Error in Controller updateService: $e');
      rethrow;
    }
  }

  Future<void> deleteService(String serviceID) async {
    return await serviceService.deleteService(serviceID);
  }
}
