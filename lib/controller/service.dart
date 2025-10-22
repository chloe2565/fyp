import '../service/service.dart';
import '../model/service.dart';
import '../model/servicePicture.dart';
import '../service/ratingReview.dart';
import '../service/servicePicture.dart'; 

class ServiceController {
  final ServiceService _serviceService = ServiceService();
  final ServicePictureService _pictureService = ServicePictureService();
  final RatingReviewService _ratingReviewService = RatingReviewService();

  Future<List<ServiceModel>> getAllServices() async {
    return await _serviceService.getAllServices();
  }

  Future<List<ServicePictureModel>> getPicturesForService(
      String serviceID) async {
    return await _pictureService.getPicturesForService(serviceID);
  }

  // Add new method to get detailed reviews
  Future<List> getReviewsForService(
      String serviceID) async {
    return await _ratingReviewService.getAllRatingReview(serviceID);
  }
}