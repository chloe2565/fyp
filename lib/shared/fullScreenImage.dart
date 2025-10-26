import 'package:flutter/material.dart';

class FullScreenGalleryViewer extends StatefulWidget {
  final List<String> imagePaths; // Filenames
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
      _FullScreenGalleryViewerState();
}

class _FullScreenGalleryViewerState extends State<FullScreenGalleryViewer> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialIndex);
    _currentIndex = widget.initialIndex;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // Helper to build the correct asset path
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
        iconTheme: const IconThemeData(color: Colors.white), // Back button
        title: Text(
          // Show "Image 3 of 10"
          '${_currentIndex + 1} of ${widget.imagePaths.length}',
          style: const TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.imagePaths.length,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        itemBuilder: (context, index) {
          final assetPath = _buildAssetPath(widget.imagePaths[index]);
          return InteractiveViewer( // Allows zooming and panning
            panEnabled: true,
            minScale: 1.0,
            maxScale: 4.0,
            child: Center(
              child: Image.asset(
                assetPath,
                fit: BoxFit.contain, // Show the whole image
                errorBuilder: (context, error, stackTrace) {
                  // Fallback placeholder
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