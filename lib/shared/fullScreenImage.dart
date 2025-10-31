import 'package:flutter/material.dart';

class FullScreenGalleryViewer extends StatefulWidget {
  final List<String> imagePaths;
  final int initialIndex;
  final String basePath;

  const FullScreenGalleryViewer({
    super.key,
    required this.imagePaths,
    required this.initialIndex,
    required this.basePath,
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

  String _buildAssetPath(String picName) {
    return '${widget.basePath}/${picName.trim().toLowerCase()}';
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
          final assetPath = _buildAssetPath(widget.imagePaths[index]);
          return InteractiveViewer(
            panEnabled: true,
            minScale: 1.0,
            maxScale: 4.0,
            child: Center(
              child: Image.asset(
                assetPath,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Center(
                    child: Image.asset(
                      'assets/images/placeholder.jpg',
                      fit: BoxFit.contain,
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
