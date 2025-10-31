import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../model/rateReviewHistoryDetailViewModel.dart';
import '../service/ratingReview.dart';
import '../model/databaseModel.dart';

class RatingReviewController with ChangeNotifier {
  final RatingReviewService service = RatingReviewService();
  RatingReviewModel? existingReview;

  bool isLoading = true;
  String? error;

  List<Map<String, dynamic>> allPendingData = [];
  List<Map<String, dynamic>> allHistoryData = [];
  List<Map<String, dynamic>> filteredPending = [];
  List<Map<String, dynamic>> filteredHistory = [];

  bool detailIsLoading = true;
  RatingReviewDetailViewModel? detailViewModel;
  String? detailError;

  Map<String, dynamic>? formHeaderData;
  double currentRating = 0;
  List<File> uploadedImages = [];
  final ImagePicker picker = ImagePicker();
  bool isPickingImages = false;
  String? photoErrorText;
  final TextEditingController reviewController = TextEditingController();

  List<String> existingPhotoNames = [];

  RatingReviewController() {
    initialize();
  }

  Future<void> initialize() async {
    try {
      isLoading = true;
      error = null;
      notifyListeners();

      final result = await service.getRatingReviewPageData();
      allPendingData = result['pending'] ?? [];
      allHistoryData = result['history'] ?? [];

      filteredPending = List.from(allPendingData);
      filteredHistory = List.from(allHistoryData);
    } catch (e) {
      error = "Failed to load reviews: $e";
      print(e);
    } finally {
      isLoading = false;
      notifyListeners(); 
    }
  }

  void onSearchChanged(String query) {
    if (query.isEmpty) {
      filteredPending = List.from(allPendingData);
      filteredHistory = List.from(allHistoryData);
    } else {
      filteredPending = allPendingData.where((item) {
        final service = item['service'] as ServiceModel?;
        final user = item['handymanUser'] as UserModel?;
        return (service?.serviceName.toLowerCase().contains(query) ?? false) ||
            (user?.userName.toLowerCase().contains(query) ?? false);
      }).toList();

      filteredHistory = allHistoryData.where((item) {
        final service = item['service'] as ServiceModel?;
        final user = item['handymanUser'] as UserModel?;
        return (service?.serviceName.toLowerCase().contains(query) ?? false) ||
            (user?.userName.toLowerCase().contains(query) ?? false);
      }).toList();
    }
    notifyListeners();
  }

  Future<void> loadReviewDetails(String reqID) async {
    detailIsLoading = true;
    detailError = null;
    detailViewModel = null;
    notifyListeners();

    try {
      detailViewModel = await service.getReviewDetails(reqID);
    } catch (e) {
      detailError = "Failed to load review details.";
    } finally {
      detailIsLoading = false;
      notifyListeners();
    }
  }

  void clearReviewDetails() {
    detailViewModel = null;
    detailError = null;
  }

  void prepareFormForNewReview(Map<String, dynamic> data) {
    formHeaderData = data;
    currentRating = 0;
    reviewController.clear();
    clearPhotos();
  }

  void prepareFormForEdit(Map<String, dynamic> data) {
    formHeaderData = data;
    existingReview = data['review'] as RatingReviewModel?;

    if (existingReview != null) {
      currentRating = existingReview!.ratingNum;
      reviewController.text = existingReview!.ratingText;
      existingPhotoNames = List.from(existingReview!.ratingPicName ?? []);
      uploadedImages.clear();
      photoErrorText = null;
    } else {
      prepareFormForNewReview(data);
    }
    notifyListeners();
  }

  void setRating(double rating) {
    currentRating = rating;
    notifyListeners();
  }

  Future<void> handleUploadPhoto() async {
    if (isPickingImages) return;
    isPickingImages = true;
    photoErrorText = null;
    notifyListeners();

    try {
      final List<XFile> pickedFiles = await picker.pickMultiImage(
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFiles.isNotEmpty) {
        final total =
            existingPhotoNames.length + uploadedImages.length + pickedFiles.length;
        if (total > 5) {
          photoErrorText = "You can only upload a maximum of 5 photos.";
        } else {
          uploadedImages.addAll(pickedFiles.map((f) => File(f.path)));
        }
      }
    } catch (e) {
      photoErrorText = "Failed to pick images";
      print("Image pick error: $e");
    } finally {
      isPickingImages = false;
      notifyListeners();
    }
  }

  void removeExistingPhoto(int index) {
    if (index >= 0 && index < existingPhotoNames.length) {
      existingPhotoNames.removeAt(index);
      notifyListeners();
    }
  }

  // Remove image from add review file
  void removePhoto(int index) {
    if (index >= 0 && index < uploadedImages.length) {
      uploadedImages.removeAt(index);
      notifyListeners();
    }
  }

  void clearPhotos() {
    existingPhotoNames.clear();
    uploadedImages.clear();
    photoErrorText = null;
  }

  Future<bool> submitNewReview() async {
    if (currentRating == 0) return false;
    if (formHeaderData == null) return false;

    final request = formHeaderData!['request'] as ServiceRequestModel;
    final reqID = request.reqID;

    try {
      await service.addNewRateReview(
        reqID: reqID,
        rating: currentRating,
        text: reviewController.text,
        newImages: uploadedImages,
      );

      await initialize(); 
      return true;
    } catch (e) {
      print("Submit error: $e");
      return false;
    }
  }

  Future<bool> submitUpdateReview() async {
    if (currentRating == 0) return false;
    if (existingReview == null) return false;

    final newPhotoNames = uploadedImages.map((f) => p.basename(f.path)).toList();
    final finalPhotoList = [...existingPhotoNames, ...newPhotoNames];

    try {
      await service.updateRateReview(
        rateID: existingReview!.rateID,
        rating: currentRating,
        text: reviewController.text,
        finalPhotoList: finalPhotoList,
      );

      await initialize();
      await loadReviewDetails(existingReview!.reqID);
      return true;
    } catch (e) {
      print("Update error: $e");
      return false;
    }
  }

  Future<bool> deleteReview(String reqID) async {
    try {
      await service.deleteRateReview(reqID);
      await initialize(); 
      return true;
    } catch (e) {
      print("Delete error: $e");
      return false;
    }
  }

  @override
  void dispose() {
    reviewController.dispose();
    super.dispose();
  }
}
