import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../model/databaseModel.dart';
import '../../controller/favoriteHandyman.dart';
import '../../shared/custNavigatorBase.dart';

class FavoriteScreen extends StatefulWidget {
  const FavoriteScreen({super.key});

  @override
  State<FavoriteScreen> createState() => FavoriteScreenState();
}

class FavoriteScreenState extends State<FavoriteScreen> {
  int currentIndex = 2;
  late FavoriteController controller;

  @override
  void initState() {
    super.initState();
    controller = FavoriteController();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void onNavBarTap(int index) async {
    if (index == currentIndex) {
      return;
    }

    String? routeToPush;

    switch (index) {
      case 0:
        Navigator.pop(context);
        return;
      case 1:
        routeToPush = '/request';
        break;
      case 2:
        break;
      case 3:
        routeToPush = '/rating';
        break;
      // More menu (index 4) is handled in the navigation bar itself
    }

    if (routeToPush != null) {
      await Navigator.pushNamed(context, routeToPush);

      if (mounted) {
        setState(() {
          currentIndex = 2;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, child) {
        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                } else {
                  Navigator.pushReplacementNamed(context, '/custHome');
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
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            elevation: 1,
            centerTitle: true,
          ),
          body: !controller.isInitialized
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    buildDatePickers(context),
                    Expanded(child: buildFavoritesList()),
                  ],
                ),
          bottomNavigationBar: CustNavigationBar(
            currentIndex: currentIndex,
            onTap: onNavBarTap,
          ),
        );
      },
    );
  }

  Widget buildDatePickers(BuildContext context) {
    String formattedStartDate = DateFormat(
      'dd MMM yyyy',
    ).format(controller.startDate);
    String formattedEndDate = DateFormat(
      'dd MMM yyyy',
    ).format(controller.endDate);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          buildDatePickerInput(context, formattedStartDate, true),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0),
            child: Text('to', style: TextStyle(fontSize: 16)),
          ),
          buildDatePickerInput(context, formattedEndDate, false),
        ],
      ),
    );
  }

  Widget buildDatePickerInput(BuildContext context, String text, bool isStart) {
    return Expanded(
      child: InkWell(
        onTap: () => controller.selectDate(context, isStart),
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
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildFavoritesList() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: controller.favoritesFuture,
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
            return FavoriteItemCard(detailsMap: favorites[index]);
          },
        );
      },
    );
  }
}

class FavoriteItemCard extends StatelessWidget {
  final Map<String, dynamic> detailsMap;

  const FavoriteItemCard({required this.detailsMap});

  @override
  Widget build(BuildContext context) {
    final HandymanModel handyman = detailsMap['handyman'] as HandymanModel;
    // final SkillModel skill = detailsMap['skill'] as SkillModel;
    final String? userPicName = detailsMap['userPicName'] as String?;
    final String handymanName = detailsMap['handymanName'] as String;
    final int reviewCount = detailsMap['reviewCount'] as int;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: Colors.pink[50],
                borderRadius: BorderRadius.circular(8),
                image: DecorationImage(
                  image: (userPicName != null && userPicName.isNotEmpty)
                      ? AssetImage('assets/images/$userPicName')
                      : const AssetImage('assets/images/profile.jpg'),
                  fit: BoxFit.cover,
                ),
              ),
            ),

            const SizedBox(width: 16),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row 1: Skill + Bookmark
                  // Row(
                  //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  //   children: [
                  //     Text(
                  //       skill.skillName,
                  //       style: const TextStyle(
                  //         fontSize: 18,
                  //         fontWeight: FontWeight.bold,
                  //       ),
                  //     ),
                  //     Icon(Icons.bookmark, color: Colors.orange[700]),
                  //   ],
                  // ),
                  // const SizedBox(height: 4),
                  // Row 2: Handyman Name
                  Text(
                    handymanName,
                    style: TextStyle(fontSize: 16, color: Colors.grey[700]),
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
                        '| ${reviewCount} reviews',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
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
