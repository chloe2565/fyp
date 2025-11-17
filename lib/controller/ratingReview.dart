import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../model/rateReviewHistoryDetailViewModel.dart';
import '../service/ratingReview.dart';
import '../model/databaseModel.dart';
import '../service/reviewReply.dart';
import '../service/user.dart';
import '../service/serviceRequest.dart';

class RatingReviewController with ChangeNotifier {
  final RatingReviewService service = RatingReviewService();
  final ReviewReplyService replyService = ReviewReplyService();
  final UserService userService = UserService();
  final ServiceRequestService serviceRequestService = ServiceRequestService();
  RatingReviewModel? existingReview;

  bool isLoading = true;
  String? error;
  String? currentEmpType;

  // Customer side
  List<Map<String, dynamic>> allPendingData = [];
  List<Map<String, dynamic>> allHistoryData = [];
  List<Map<String, dynamic>> filteredPending = [];
  List<Map<String, dynamic>> filteredHistory = [];
  Map<String, String> allAvailableServices = {};

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

  List<String> existingPhotoUrls = [];
  List<String> deletedPhotoUrls = [];

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

      await loadAllAvailableServices();
    } catch (e) {
      error = "Failed to load reviews: $e";
      print(e);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadAllAvailableServices() async {
    try {
      final List<ServiceModel> services = await serviceRequestService
          .getAllServices();
      allAvailableServices = {};

      for (var service in services) {
        allAvailableServices[service.serviceID] = service.serviceName;
      }

      print('Loaded ${allAvailableServices.length} services');
    } catch (e) {
      print("Error loading all services: $e");

      final servicesMap = <String, String>{};
      for (var item in allPendingData) {
        final service = item['service'] as ServiceModel?;
        if (service != null) {
          servicesMap[service.serviceID] = service.serviceName;
        }
      }

      for (var item in allHistoryData) {
        final service = item['service'] as ServiceModel?;
        if (service != null) {
          servicesMap[service.serviceID] = service.serviceName;
        }
      }

      allAvailableServices = servicesMap;
      print(
        'Fallback: Loaded ${allAvailableServices.length} services from existing data',
      );
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

      // Fetch customer user data and reply status for each review
      for (var reviewData in allReviewsData) {
        final review = reviewData['review'] as RatingReviewModel?;
        final request = reviewData['request'] as ServiceRequestModel?;
        
        // Fetch reply status
        if (review != null) {
          try {
            final reply = await replyService.getReplyForReview(review.rateID);
            reviewData['hasReply'] = reply != null;
            reviewData['reply'] = reply;
          } catch (e) {
            reviewData['hasReply'] = false;
            reviewData['reply'] = null;
          }
        }
        
        // Fetch customer user data
        if (request != null) {
          try {
            final customerUser = await service.fetchCustomerUserModel(request.custID);
            reviewData['customerUser'] = customerUser;
          } catch (e) {
            reviewData['customerUser'] = null;
            print('Error fetching customer user for custID ${request.custID}: $e');
          }
        }
      }

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
        final handymanUser = item['handymanUser'] as UserModel?;
        final customerUser = item['customerUser'] as UserModel?;
        final request = item['request'] as ServiceRequestModel?;
        final review = item['review'] as RatingReviewModel?;
        final service = item['service'] as ServiceModel?;
        return (review?.rateID.toLowerCase().contains(lowerQuery) ?? false) ||
            (request?.reqID.toLowerCase().contains(lowerQuery) ?? false) ||
            (handymanUser?.userName.toLowerCase().contains(lowerQuery) ?? false) ||
            (customerUser?.userName.toLowerCase().contains(lowerQuery) ?? false) ||
            (service?.serviceName.toLowerCase().contains(lowerQuery) ?? false);
      }).toList();
    }
    notifyListeners();
  }

  void applyFilters({
    String? searchQuery,
    String? replyFilter,
    Map<String, String>? serviceFilter,
    DateTime? startDate,
    DateTime? endDate,
    double? minRating,
    double? maxRating,
  }) {
    // Employee side
    filteredAllReviews = allReviewsData.where((item) {
      // Search query filter
      if (searchQuery != null && searchQuery.isNotEmpty) {
        final lowerQuery = searchQuery.toLowerCase();
        final handymanUser = item['handymanUser'] as UserModel?;
        final customerUser = item['customerUser'] as UserModel?;
        final request = item['request'] as ServiceRequestModel?;
        final review = item['review'] as RatingReviewModel?;
        final service = item['service'] as ServiceModel?;
        final matchesSearch =
            (review?.rateID.toLowerCase().contains(lowerQuery) ?? false) ||
            (request?.reqID.toLowerCase().contains(lowerQuery) ?? false) ||
            (handymanUser?.userName.toLowerCase().contains(lowerQuery) ?? false) ||
            (customerUser?.userName.toLowerCase().contains(lowerQuery) ?? false) ||
            (service?.serviceName.toLowerCase().contains(lowerQuery) ?? false);
        if (!matchesSearch) return false;
      }

      // Reply filter
      if (replyFilter != null) {
        final hasReply = item['hasReply'] as bool? ?? false;
        if (replyFilter == 'with' && !hasReply) return false;
        if (replyFilter == 'without' && hasReply) return false;
      }

      // Date range filter
      final request = item['request'] as ServiceRequestModel?;
      if (request != null) {
        final scheduledDate = request.scheduledDateTime;

        if (startDate != null) {
          final startDateOnly = DateTime(
            startDate.year,
            startDate.month,
            startDate.day,
          );
          final scheduledDateOnly = DateTime(
            scheduledDate.year,
            scheduledDate.month,
            scheduledDate.day,
          );
          if (scheduledDateOnly.isBefore(startDateOnly)) return false;
        }

        if (endDate != null) {
          final endDateOnly = DateTime(
            endDate.year,
            endDate.month,
            endDate.day,
            23,
            59,
            59,
          );
          if (scheduledDate.isAfter(endDateOnly)) return false;
        }
      }

      // Rating filter
      final review = item['review'] as RatingReviewModel?;
      if (review != null) {
        final rating = review.ratingNum;

        if (minRating != null && rating < minRating) return false;
        if (maxRating != null && rating > maxRating) return false;
      }

      return true;
    }).toList();

    // Customer side
    final lowerQuery = searchQuery?.toLowerCase() ?? '';

    filteredPending = allPendingData.where((item) {
      // Search query filter
      if (searchQuery != null && searchQuery.isNotEmpty) {
        final service = item['service'] as ServiceModel?;
        final user = item['handymanUser'] as UserModel?;
        final request = item['request'] as ServiceRequestModel?;
        final matchesSearch =
            (service?.serviceName.toLowerCase().contains(lowerQuery) ??
                false) ||
            (user?.userName.toLowerCase().contains(lowerQuery) ?? false) ||
            (request?.reqID.toLowerCase().contains(lowerQuery) ?? false);
        if (!matchesSearch) return false;
      }

      // Service filter
      if (serviceFilter != null && serviceFilter.isNotEmpty) {
        final service = item['service'] as ServiceModel?;
        if (service == null || !serviceFilter.containsKey(service.serviceID)) {
          return false;
        }
      }

      // Date range filter for pending
      final request = item['request'] as ServiceRequestModel?;
      if (request?.reqCompleteTime != null) {
        final completedDate = request!.reqCompleteTime!;

        if (startDate != null) {
          final startDateOnly = DateTime(
            startDate.year,
            startDate.month,
            startDate.day,
          );
          final completedDateOnly = DateTime(
            completedDate.year,
            completedDate.month,
            completedDate.day,
          );
          if (completedDateOnly.isBefore(startDateOnly)) return false;
        }

        if (endDate != null) {
          final endDateOnly = DateTime(
            endDate.year,
            endDate.month,
            endDate.day,
            23,
            59,
            59,
          );
          if (completedDate.isAfter(endDateOnly)) return false;
        }
      }

      return true;
    }).toList();

    filteredHistory = allHistoryData.where((item) {
      // Search query filter
      if (searchQuery != null && searchQuery.isNotEmpty) {
        final service = item['service'] as ServiceModel?;
        final user = item['handymanUser'] as UserModel?;
        final request = item['request'] as ServiceRequestModel?;
        final matchesSearch =
            (service?.serviceName.toLowerCase().contains(lowerQuery) ??
                false) ||
            (user?.userName.toLowerCase().contains(lowerQuery) ?? false) ||
            (request?.reqID.toLowerCase().contains(lowerQuery) ?? false);
        if (!matchesSearch) return false;
      }

      // Service filter
      if (serviceFilter != null && serviceFilter.isNotEmpty) {
        final service = item['service'] as ServiceModel?;
        if (service == null || !serviceFilter.containsKey(service.serviceID)) {
          return false;
        }
      }

      // Date range filter for history
      final review = item['review'] as RatingReviewModel?;
      if (review?.ratingCreatedAt != null) {
        final createdDate = review!.ratingCreatedAt;

        if (startDate != null) {
          final startDateOnly = DateTime(
            startDate.year,
            startDate.month,
            startDate.day,
          );
          final createdDateOnly = DateTime(
            createdDate.year,
            createdDate.month,
            createdDate.day,
          );
          if (createdDateOnly.isBefore(startDateOnly)) return false;
        }

        if (endDate != null) {
          final endDateOnly = DateTime(
            endDate.year,
            endDate.month,
            endDate.day,
            23,
            59,
            59,
          );
          if (createdDate.isAfter(endDateOnly)) return false;
        }
      }

      // Rating filter for history
      if (review != null) {
        final rating = review.ratingNum;

        if (minRating != null && rating < minRating) return false;
        if (maxRating != null && rating > maxRating) return false;
      }

      return true;
    }).toList();

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
      existingPhotoUrls = List.from(existingReview!.ratingPicName ?? []);
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
            existingPhotoUrls.length +
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
    if (index >= 0 && index < existingPhotoUrls.length) {
      final removedUrl = existingPhotoUrls.removeAt(index);
      deletedPhotoUrls.add(removedUrl);
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
    existingPhotoUrls.clear();
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

    try {
      await service.updateRateReview(
        rateID: existingReview!.rateID,
        rating: currentRating,
        text: reviewController.text,
        existingPhotoUrls: existingPhotoUrls,
        newImages: uploadedImages,
        deletedPhotoUrls: deletedPhotoUrls,
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