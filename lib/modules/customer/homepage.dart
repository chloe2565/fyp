import 'package:flutter/material.dart';
import 'package:fyp/service/image_service.dart';
import '../../controller/user.dart';
import '../../shared/helper.dart';
import '../../model/databaseModel.dart';
import '../../shared/custNavigatorBase.dart';
import '../../controller/service.dart';
import 'allServices.dart';
import 'serviceDetail.dart';

class CustHomepage extends StatefulWidget {
  const CustHomepage({super.key});

  @override
  State<CustHomepage> createState() => CustHomepageState();
}

class CustHomepageState extends State<CustHomepage> {
  late UserController userController;
  late Future<UserModel?> userFuture;

  bool isMenuOpen = false;
  int currentIndex = 0;

  @override
  void initState() {
    super.initState();
    userController = UserController(
      showErrorSnackBar: (message) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(message)));
        }
      },
    );
    userFuture = getCurrentUser();
  }

  void handleLogout(BuildContext context) async {
    print("Logout selected");
    if (!mounted) return;

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await userController.logout(context, setState);
    } catch (e) {
      // Dismiss loading dialog
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Logout failed: $e')));
      }
    }
  }

  Future<UserModel?> getCurrentUser() async {
    return await userController.getCurrentUser();
  }

  void onNavBarTap(int index) async {
    if (index == currentIndex) {
      return;
    }

    String? routeToPush;

    switch (index) {
      case 0:
        break;
      case 1:
        routeToPush = '/request';
        break;
      case 2:
        routeToPush = '/rating';
        break;
      case 3:
        routeToPush = '/profile';
        break;
    }

    if (routeToPush != null) {
      await Navigator.pushNamed(context, routeToPush);

      if (mounted) {
        setState(() {
          currentIndex = 0;
        });
      }
    }
  }

  @override
  void dispose() {
    userController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 70,
        automaticallyImplyLeading: false,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        title: FutureBuilder<UserModel?>(
          future: userFuture,
          builder: (context, snapshot) {
            ImageProvider profileImage = NetworkImage(
              FirebaseImageService.placeholderUrl,
            );

            if (snapshot.hasData && snapshot.data != null) {
              final user = snapshot.data!;
              profileImage = user.userPicName.getImageProvider();
            }

            return Row(
              children: [
                CircleAvatar(radius: 26, backgroundImage: profileImage),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome,',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                    FutureBuilder<UserModel?>(
                      future: userFuture,
                      builder: (context, snapshot) {
                        if (snapshot.hasData && snapshot.data != null) {
                          return Text(
                            snapshot.data!.userName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.black,
                            ),
                          );
                        } else {
                          return const Text(
                            "Guest",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.black,
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ],
            );
          },
        ),
        actions: [
          // Stack(
          //   alignment: Alignment.topRight,
          //   children: [
          //     const Icon(
          //       Icons.notifications_none_outlined,
          //       color: Colors.black,
          //       size: 30,
          //     ),
          //     Container(
          //       margin: const EdgeInsets.only(top: 4, right: 2),
          //       width: 15,
          //       height: 15,
          //       decoration: BoxDecoration(
          //         color: Colors.orange,
          //         shape: BoxShape.circle,
          //         border: Border.all(color: Colors.white, width: 2),
          //       ),
          //       child: const Center(
          //         child: Text(
          //           '1',
          //           style: TextStyle(
          //             fontSize: 8,
          //             color: Colors.white,
          //             fontWeight: FontWeight.bold,
          //           ),
          //         ),
          //       ),
          //     ),
          //   ],
          // ),
          // const SizedBox(width: 16),
          Container(
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
            child: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'logout') handleLogout(context);
                setState(() => isMenuOpen = false);
              },
              onOpened: () => setState(() => isMenuOpen = true),
              offset: const Offset(0, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(
                  value: 'logout',
                  child: Text('Logout Account'),
                ),
              ],
              icon: const Icon(Icons.more_vert, color: Colors.black),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: HomepageScreen(controller: ServiceController()),
      bottomNavigationBar: CustNavigationBar(
        currentIndex: currentIndex,
        onTap: onNavBarTap,
      ),
    );
  }
}

class HomepageScreen extends StatefulWidget {
  final ServiceController controller;
  const HomepageScreen({required this.controller, super.key});

  @override
  State<HomepageScreen> createState() => HomepageScreenState();
}

class HomepageScreenState extends State<HomepageScreen> {
  late Future<void> servicesLoadFuture;
  late final ServiceController serviceController;

  @override
  void initState() {
    super.initState();
    serviceController = widget.controller;
    servicesLoadFuture = loadServices();
  }

  Future<void> loadServices({bool refresh = false}) async {
    try {
      // Call the controller to load and cache the data
      await serviceController.loadServices(refresh: refresh);
      print('Homepage: Controller loaded services');
    } catch (e) {
      print('Homepage Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load services: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: servicesLoadFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'Failed to load services',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        // Check if the load was successful but returned no data
        if (serviceController.allServices.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No services available right now',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            final newFuture = loadServices(refresh: true);
            setState(() {
              servicesLoadFuture = newFuture;
            });
            await newFuture;
          },
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              const SizedBox(height: 10),
              buildServicesSection(),
              const SizedBox(height: 24),
              buildPopularServicesSection(),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget buildServicesSection() {
    final int serviceIconCount = serviceController.serviceIconCountInGrid;
    final bool showMoreIcon = serviceController.showMoreIconInGrid;
    final int gridItemCount = serviceController.gridItemCount;
    final List<ServiceModel> services = serviceController.servicesForGrid;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Services',
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                fontSize: 20,
                color: Colors.black,
              ),
            ),
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AllServicesScreen(),
                ),
              ),
              child: Text(
                'View all',
                style: Theme.of(
                  context,
                ).textTheme.displayMedium?.copyWith(color: Colors.orange),
              ),
            ),
          ],
        ),
        GridView.builder(
          itemCount: gridItemCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 80,
            mainAxisSpacing: 10,
            crossAxisSpacing: 20,
            childAspectRatio: 0.70,
          ),
          itemBuilder: (context, index) {
            if (showMoreIcon && index == serviceIconCount) {
              return ServiceIcon(
                icon: Icons.more_horiz,
                label: 'More',
                color: const Color(0xFFFFA7A7),
                iconColor: Colors.black,
                onPressed: (context) => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AllServicesScreen(),
                  ),
                ),
              );
            }

            final service = services[index];
            return ServiceIcon(
              icon: ServiceHelper.getIconForService(service.serviceName),
              label: service.serviceName,
              color: ServiceHelper.getColorForService(service.serviceName),
              iconColor: Colors.black,
              onPressed: (context) {
                print('Tapped: ${service.serviceName}');
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ServiceDetailScreen(service: service),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget buildPopularServicesSection() {
    if (!serviceController.hasPopularServices) {
      return const SizedBox.shrink();
    }

    final popularServices = serviceController.popularServicesForList;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Most Popular Services',
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                fontSize: 20,
                color: Colors.black,
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        ...popularServices.map(
          (service) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: ServiceCard(
              title: service.serviceName,
              price: service.servicePrice != null
                  ? 'RM ${service.servicePrice!.toStringAsFixed(0)} / hour'
                  : 'Price not available',
              imageUrl: 'assets/images/profile.jpg',
              icon: ServiceHelper.getIconForService(service.serviceName),
              color: ServiceHelper.getColorForService(service.serviceName),
            ),
          ),
        ),
      ],
    );
  }
}

class ServiceIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color iconColor;
  final Function(BuildContext) onPressed;

  const ServiceIcon({
    required this.icon,
    required this.label,
    required this.color,
    required this.iconColor,
    required this.onPressed,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onPressed(context),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 55,
            height: 55,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: iconColor, size: 30),
          ),
          const SizedBox(height: 8),
          Flexible(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

class ServiceCard extends StatelessWidget {
  final String title;
  final String price;
  final String imageUrl;
  final IconData icon;
  final Color color;

  const ServiceCard({
    required this.title,
    required this.price,
    required this.imageUrl,
    required this.icon,
    required this.color,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: color,
            ),
            child: Icon(icon, size: 36, color: Colors.black),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      price,
                      style: const TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
