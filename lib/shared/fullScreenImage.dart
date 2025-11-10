import 'package:flutter/material.dart';

import '../service/image_service.dart';

class FullScreenGalleryViewer extends StatefulWidget {
  final List<String> imagePaths;
  final int initialIndex;
  final String? basePath;

  const FullScreenGalleryViewer({
    super.key,
    required this.imagePaths,
    required this.initialIndex,
    this.basePath,
  });

  @override
  State<FullScreenGalleryViewer> createState() =>
      FullScreenGalleryViewerState();
}

class FullScreenGalleryViewerState extends State<FullScreenGalleryViewer> {
  late PageController pageController;
  late int currentIndex;

  @override
  void initState() {
    super.initState();
    pageController = PageController(initialPage: widget.initialIndex);
    currentIndex = widget.initialIndex;
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  ImageProvider getImageProvider(String imagePath) {
    if (imagePath.startsWith('http')) {
      return NetworkImage(imagePath);
    }

    if (widget.basePath != null) {
      final assetPath = '${widget.basePath}/${imagePath.trim().toLowerCase()}';
      return AssetImage(assetPath);
    }

    return AssetImage('assets/images/${imagePath.trim().toLowerCase()}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          '${currentIndex + 1} of ${widget.imagePaths.length}',
          style: const TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: PageView.builder(
        controller: pageController,
        itemCount: widget.imagePaths.length,
        onPageChanged: (index) {
          setState(() {
            currentIndex = index;
          });
        },
        itemBuilder: (context, index) {
          final imagePath = widget.imagePaths[index];

          return InteractiveViewer(
            panEnabled: true,
            minScale: 1.0,
            maxScale: 4.0,
            child: Center(
              child: Image(
                image: getImageProvider(imagePath),
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Center(
                    child: Image(
                      image: NetworkImage(FirebaseImageService.placeholderUrl),
                      fit: BoxFit.contain,
                      errorBuilder: (context, err, stack) {
                        return const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.broken_image,
                              color: Colors.white,
                              size: 64,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Failed to load image',
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
