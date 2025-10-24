import '../model/reviewDisplayViewModel.dart' show ReviewDisplayData;
import '../service/service.dart';
import '../../model/database_model.dart';
import '../service/ratingReview.dart';
import '../service/servicePicture.dart';

class ServiceController {
  final RatingReviewService ratingReviewService = RatingReviewService();
  final ServicePictureService pictureService = ServicePictureService();
  late final ServiceService serviceService;

  List<ServiceModel> allServicesData = [];
  bool servicesLoaded = false;

  ServiceController() {
    serviceService = ServiceService(ratingReviewService: ratingReviewService);
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
}