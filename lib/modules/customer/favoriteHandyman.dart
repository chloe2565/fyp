// ui/favorite_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// Import your models
import '../../model/handyman.dart';
import '../../model/skill.dart';

// Import your service and other UI components
import '../../controller/favoriteHandyman.dart'; // <-- IMPORT THE CONTROLLER
import '../../navigatorBase.dart';

class FavoriteScreen extends StatefulWidget {
  const FavoriteScreen({super.key});

  @override
  State<FavoriteScreen> createState() => _FavoriteScreenState();
}

class _FavoriteScreenState extends State<FavoriteScreen> {
  // The View is responsible for creating and disposing the Controller
  late FavoriteController _controller;

  @override
  void initState() {
    super.initState();
    _controller = FavoriteController();
  }

  @override
  void dispose() {
    _controller.dispose(); // Always dispose of controllers!
    super.dispose();
  }

  void _onItemTapped(int index) {
    // Use pushReplacementNamed to avoid building a stack of pages
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/home');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/request');
        break;
      case 2:
        // Already on Favorite page, do nothing.
        break;
      case 3:
        // Navigator.pushReplacementNamed(context, '/rating'); 
        break;
      case 4:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, child) {
        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                } else {
                  Navigator.pushReplacementNamed(context, '/home');
                }
              },
            ),
            title: const Text(
              'My Favorite List',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            backgroundColor: Colors.white,
            elevation: 1,
            centerTitle: true,
          ),
          body: Column(
            children: [
              _buildDatePickers(context), 
              Expanded(
                child: _buildFavoritesList(),
              ),
            ],
          ),
          bottomNavigationBar: AppNavigationBar(
            currentIndex: 2,
            onTap: _onItemTapped,
          ),
        );
      },
    );
  }

  Widget _buildDatePickers(BuildContext context) {
    String formattedStartDate = DateFormat('dd MMM yyyy').format(_controller.startDate);
    String formattedEndDate = DateFormat('dd MMM yyyy').format(_controller.endDate);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildDatePickerInput(context, formattedStartDate, true),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0),
            child: Text('to', style: TextStyle(fontSize: 16)),
          ),
          _buildDatePickerInput(context, formattedEndDate, false),
        ],
      ),
    );
  }

  Widget _buildDatePickerInput(BuildContext context, String text, bool isStart) {
    return Expanded(
      child: InkWell(
        onTap: () => _controller.selectDate(context, isStart),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Row(
            children: [
              Icon(Icons.calendar_today, color: Colors.grey[600], size: 18),
              const SizedBox(width: 8),
              Text(
                text,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFavoritesList() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _controller.favoritesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text(
              'No favorites found for this date range.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          );
        }

        final favorites = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: favorites.length,
          itemBuilder: (context, index) {
            return _FavoriteItemCard(detailsMap: favorites[index]);
          },
        );
      },
    );
  }
}

// -------------------------------------------------------------------
// The Card Widget (View)
// -------------------------------------------------------------------
class _FavoriteItemCard extends StatelessWidget {
  final Map<String, dynamic> detailsMap;

  const _FavoriteItemCard({required this.detailsMap});

  @override
  Widget build(BuildContext context) {
    final HandymanModel handyman = detailsMap['handyman'] as HandymanModel;
    final SkillModel skill = detailsMap['skill'] as SkillModel;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.pink[50], 
              child: Icon(
                Icons.person,
                size: 30,
                color: Colors.blueGrey[300],
              ),
            ),
            const SizedBox(width: 16),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row 1: Skill + Bookmark
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        skill.skillDesc,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Icon(Icons.bookmark, color: Colors.orange[700]),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Row 2: Handyman Name
                  Text(
                    handyman.handymanName,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Row 3: Rating + Reviews
                  Row(
                    children: [
                      Icon(Icons.star, color: Colors.yellow[700], size: 18),
                      const SizedBox(width: 4),
                      Text(
                        handyman.handymanRating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '| ${handyman.handymanRating} reviews',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}