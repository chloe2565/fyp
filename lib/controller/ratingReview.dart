import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../model/rateReviewHistoryDetailViewModel.dart';
import '../service/ratingReview.dart';
import '../model/databaseModel.dart';
import '../service/reviewReply.dart';
import '../service/user.dart';

class RatingReviewController with ChangeNotifier {
  final RatingReviewService service = RatingReviewService();
  final ReviewReplyService replyService = ReviewReplyService();
  final UserService userService = UserService();
  RatingReviewModel? existingReview;

  bool isLoading = true;
  String? error;
  String? currentEmpType;

  // Customer side
  List<Map<String, dynamic>> allPendingData = [];
  List<Map<String, dynamic>> allHistoryData = [];
  List<Map<String, dynamic>> filteredPending = [];
  List<Map<String, dynamic>> filteredHistory = [];

  // Employee side
  List<Map<String, dynamic>> allReviewsData = [];
  List<Map<String, dynamic>> filteredAllReviews = [];

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
    // initialize();
  }

  // Customer side
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

  // Employee side
  Future<void> initializeForEmployee() async {
    try {
      isLoading = true;
      error = null;
      notifyListeners();

      final empInfo = await userService.getCurrentEmployeeInfo();
      currentEmpType = empInfo?['empType'];

      final result = await service.getRatingReviewPageDataForEmployee();
      allReviewsData = result['allReviews'] ?? [];
      filteredAllReviews = List.from(allReviewsData);
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
      filteredAllReviews = List.from(allReviewsData);
    } else {
      final lowerQuery = query.toLowerCase();

      filteredPending = allPendingData.where((item) {
        final service = item['service'] as ServiceModel?;
        final user = item['handymanUser'] as UserModel?;
        final request = item['request'] as ServiceRequestModel?;
        return (service?.serviceName.toLowerCase().contains(lowerQuery) ??
                false) ||
            (user?.userName.toLowerCase().contains(lowerQuery) ?? false) ||
            (request?.reqID.toLowerCase().contains(lowerQuery) ?? false);
      }).toList();

      filteredHistory = allHistoryData.where((item) {
        final service = item['service'] as ServiceModel?;
        final user = item['handymanUser'] as UserModel?;
        final request = item['request'] as ServiceRequestModel?;
        return (service?.serviceName.toLowerCase().contains(lowerQuery) ??
                false) ||
            (user?.userName.toLowerCase().contains(lowerQuery) ?? false) ||
            (request?.reqID.toLowerCase().contains(lowerQuery) ?? false);
      }).toList();

      filteredAllReviews = allReviewsData.where((item) {
        final user = item['handymanUser'] as UserModel?;
        final request = item['request'] as ServiceRequestModel?;
        final review = item['review'] as RatingReviewModel?;
        return (review?.rateID.toLowerCase().contains(lowerQuery) ?? false) ||
            (request?.reqID.toLowerCase().contains(lowerQuery) ?? false) ||
            (request?.handymanID.toLowerCase().contains(lowerQuery) ?? false) ||
            (user?.userName.toLowerCase().contains(lowerQuery) ?? false);
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
            existingPhotoNames.length +
            uploadedImages.length +
            pickedFiles.length;
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

    final newPhotoNames = uploadedImages
        .map((f) => p.basename(f.path))
        .toList();
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

  Future<void> submitReply(String rateID, String replyText) async {
    if (replyText.isEmpty) {
      throw Exception("Reply text cannot be empty.");
    }
    try {
      if (detailViewModel?.reply?.replyID != null) {
        await replyService.updateReply(
          replyID: detailViewModel!.reply!.replyID,
          replyText: replyText,
        );
      } else {
        await replyService.addReplyToReview(
          rateID: rateID,
          replyText: replyText,
        );
      }

      if (detailViewModel != null) {
        await loadReviewDetails(detailViewModel!.reqID);
      }
    } catch (e) {
      print("Error submitting/updating reply: $e");
      rethrow;
    }
  }

  Future<void> updateReply(String replyID, String replyText) async {
    try {
      await replyService.updateReply(replyID: replyID, replyText: replyText);
      if (detailViewModel != null) {
        await loadReviewDetails(detailViewModel!.reqID);
      }
    } catch (e) {
      print("Error updating reply: $e");
      rethrow;
    }
  }

  Future<void> deleteReply(String replyID) async {
    try {
      await replyService.deleteReply(replyID);
      if (detailViewModel != null) {
        await loadReviewDetails(detailViewModel!.reqID);
      }
    } catch (e) {
      print("Error deleting reply: $e");
      rethrow;
    }
  }

  @override
  void dispose() {
    reviewController.dispose();
    super.dispose();
  }
}
