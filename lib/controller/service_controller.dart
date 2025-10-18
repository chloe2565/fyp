import '../service/service.dart';
import '../model/service.dart';
import '../model/servicePicture.dart';

class ServiceController {
  final ServiceService _serviceService = ServiceService();
  final ServicePictureService _pictureService = ServicePictureService();

  Future<List<ServiceModel>> getAllServices() async {
    return await _serviceService.getAllServices();
  }

  Future<List<ServicePictureModel>> getPicturesForService(
      String serviceID) async {
    return await _pictureService.getPicturesForService(serviceID);
  }
}