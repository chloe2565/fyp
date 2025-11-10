import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

enum ImageCategory {
  profiles('images'),
  payments('payments'),
  requests('requests'),
  reviews('reviews'),
  services('services');

  final String path;
  const ImageCategory(this.path);
}

class FirebaseImageService {
  final FirebaseStorage storage = FirebaseStorage.instance;

  Future<File?> compressImage(
    File file, {
    int quality = 70,
    int maxWidth = 800,
  }) async {
    final compressedFilePath =
        '${file.parent.path}/compressed_${file.uri.pathSegments.last}';

    XFile? resultXFile = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      compressedFilePath,
      quality: quality,
      minWidth: maxWidth,
      keepExif: false,
    );

    if (resultXFile == null) {
      return null;
    }

    File resultFile = File(resultXFile.path);

    int fileSize = await resultFile.length();
    int attempt = 0;
    int currentQuality = quality;

    while (fileSize > 200 * 1024 && attempt < 3) {
      currentQuality -= 15;
      if (currentQuality < 20) currentQuality = 20;

      resultXFile = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        compressedFilePath,
        quality: currentQuality,
        minWidth: maxWidth - (attempt * 100),
        keepExif: false,
      );

      if (resultXFile == null) break;
      resultFile = File(resultXFile.path);
      fileSize = await resultFile.length();
      attempt++;
    }

    return resultFile;
  }

  Future<String?> uploadImage({
    required File imageFile,
    required ImageCategory category,
    required String uniqueId,
    String? customFileName,
  }) async {
    try {
      final compressedFile = await compressImage(
        imageFile,
        quality: 70,
        maxWidth: 800,
      );
      if (compressedFile == null) {
        debugPrint('Image compression failed');
        return null;
      }

      final fileExtension = imageFile.path.split('.').last.toLowerCase();

      const supportedExtensions = ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'];
      if (!supportedExtensions.contains(fileExtension)) {
        debugPrint('Unsupported file type: $fileExtension');
        return null;
      }

      final mimeTypes = {
        'jpg': 'image/jpeg',
        'jpeg': 'image/jpeg',
        'png': 'image/png',
        'webp': 'image/webp',
        'bmp': 'image/bmp',
      };
      final contentType =
          mimeTypes[fileExtension] ?? 'application/octet-stream';

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName =
          customFileName ??
          '${category.name}_${uniqueId}_$timestamp.$fileExtension';
      final Reference ref = storage.ref().child('${category.path}/$fileName');

      final metadata = SettableMetadata(
        contentType: contentType,
        customMetadata: {
          'uploadedBy': uniqueId,
          'uploadedAt': DateTime.now().toIso8601String(),
        },
      );

      final UploadTask uploadTask = ref.putFile(compressedFile, metadata);

      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress =
            (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
        debugPrint('Upload progress: ${progress.toStringAsFixed(2)}%');
      });

      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      debugPrint('Image uploaded successfully to: $downloadUrl');
      return downloadUrl;
    } on FirebaseException catch (e) {
      debugPrint('Firebase error uploading image: ${e.code} - ${e.message}');
      return null;
    } catch (e) {
      debugPrint('Error uploading image: $e');
      return null;
    }
  }

  Future<List<String?>> uploadMultipleImages({
    required List<File> imageFiles,
    required ImageCategory category,
    required String uniqueId,
  }) async {
    final List<String?> uploadedUrls = [];

    for (int i = 0; i < imageFiles.length; i++) {
      final ext = imageFiles[i].path.split('.').last.toLowerCase();
      final url = await uploadImage(
        imageFile: imageFiles[i],
        category: category,
        uniqueId: uniqueId,
        customFileName:
            '${category.name}_${uniqueId}_${i}_${DateTime.now().millisecondsSinceEpoch}.$ext',
      );
      uploadedUrls.add(url);
    }

    return uploadedUrls;
  }

  Future<bool> deleteImage(String? imageUrl) async {
    if (imageUrl == null || imageUrl.isEmpty) {
      debugPrint('No image URL provided for deletion');
      return false;
    }

    if (!imageUrl.contains('firebasestorage.googleapis.com')) {
      debugPrint('Not a Firebase Storage URL $imageUrl');
      return false;
    }

    try {
      final Reference ref = storage.refFromURL(imageUrl);
      await ref.delete();
      debugPrint('Image deleted successfully $imageUrl');
      return true;
    } on FirebaseException catch (e) {
      if (e.code == 'object-not-found') {
        debugPrint('Image not found: $imageUrl');
        return true;
      }
      debugPrint('Firebase error deleting image: ${e.code} - ${e.message}');
      return false;
    } catch (e) {
      debugPrint('Error deleting image: $e');
      return false;
    }
  }

  Future<List<bool>> deleteMultipleImages(List<String?> imageUrls) async {
    final List<bool> results = [];

    for (final url in imageUrls) {
      final success = await deleteImage(url);
      results.add(success);
    }

    return results;
  }

  Future<String?> getDownloadUrl(String storagePath) async {
    try {
      final ref = storage.ref().child(storagePath);
      final url = await ref.getDownloadURL();
      return url;
    } catch (e) {
      debugPrint('Error getting download URL: $e');
      return null;
    }
  }

  Future<bool> imageExists(String imageUrl) async {
    try {
      final ref = storage.refFromURL(imageUrl);
      await ref.getMetadata();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<String?> updateImage({
    required File newImageFile,
    required ImageCategory category,
    required String uniqueId,
    String? oldImageUrl,
    String? customFileName,
  }) async {
    final newUrl = await uploadImage(
      imageFile: newImageFile,
      category: category,
      uniqueId: uniqueId,
      customFileName: customFileName,
    );

    if (newUrl != null && oldImageUrl != null) {
      await deleteImage(oldImageUrl);
    }

    return newUrl;
  }

  Future<FullMetadata?> getImageMetadata(String imageUrl) async {
    try {
      final ref = storage.refFromURL(imageUrl);
      return await ref.getMetadata();
    } catch (e) {
      debugPrint('Error getting image metadata: $e');
      return null;
    }
  }

  Future<List<String>> listImagesInCategory(ImageCategory category) async {
    try {
      final ref = storage.ref().child(category.path);
      final result = await ref.listAll();

      final List<String> urls = [];
      for (final item in result.items) {
        final url = await item.getDownloadURL();
        urls.add(url);
      }

      return urls;
    } catch (e) {
      debugPrint('Error listing images: $e');
      return [];
    }
  }

  Future<String> getPlaceholderUrl() async {
    try {
      final ref = storage.ref().child('images/placeholder.jpg');
      return await ref.getDownloadURL();
    } catch (e) {
      debugPrint('Error getting placeholder URL: $e');
      return 'https://via.placeholder.com/400';
    }
  }

  static String get placeholderUrl {
    return 'https://firebasestorage.googleapis.com/v0/b/handymanfyp-51049.firebasestorage.app/o/images%2Fplaceholder.jpg?alt=media&token=a50dc8ac-93e1-48fc-8284-0af3876233cb';
  }
}

// Simple extension using NetworkImage (has built-in memory caching)
extension ImageProviderHelper on String? {
  ImageProvider getImageProvider() {
    if (this == null || this!.isEmpty) {
      return NetworkImage(FirebaseImageService.placeholderUrl);
    }

    if (this!.startsWith('http')) {
      return NetworkImage(this!);
    }

    return AssetImage('assets/images/$this');
  }
}

// Widget helper for displaying images with loading states
extension ImageWidget on String? {
  Widget toNetworkImage({
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    Widget? placeholder,
    Widget? errorWidget,
  }) {
    final imageUrl = this;

    if (imageUrl == null || imageUrl.isEmpty) {
      return Image.network(
        FirebaseImageService.placeholderUrl,
        width: width,
        height: height,
        fit: fit,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return placeholder ??
              Container(
                width: width,
                height: height,
                color: Colors.grey.shade200,
                child: Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                          : null,
                      strokeWidth: 2,
                    ),
                  ),
                ),
              );
        },
        errorBuilder: (context, error, stackTrace) {
          return errorWidget ??
              Container(
                width: width,
                height: height,
                color: Colors.grey.shade200,
                child: const Icon(Icons.broken_image, color: Colors.grey),
              );
        },
      );
    }

    if (imageUrl.startsWith('http')) {
      return Image.network(
        imageUrl,
        width: width,
        height: height,
        fit: fit,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return placeholder ??
              Container(
                width: width,
                height: height,
                color: Colors.grey.shade200,
                child: Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                          : null,
                      strokeWidth: 2,
                    ),
                  ),
                ),
              );
        },
        errorBuilder: (context, error, stackTrace) {
          debugPrint('Error loading image: $error');
          return errorWidget ??
              Image.network(
                FirebaseImageService.placeholderUrl,
                width: width,
                height: height,
                fit: fit,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: width,
                    height: height,
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.broken_image, color: Colors.grey),
                  );
                },
              );
        },
      );
    }

    return Image.asset(
      'assets/images/$imageUrl',
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) =>
          errorWidget ??
          Container(
            width: width,
            height: height,
            color: Colors.grey.shade200,
            child: const Icon(Icons.broken_image, color: Colors.grey),
          ),
    );
  }
}
