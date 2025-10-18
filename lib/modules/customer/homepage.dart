import 'package:flutter/material.dart';
import '../../controller/user.dart';
import '../../helper.dart';
import '../../model/user.dart';
import '../../navigatorBase.dart';
import '../../controller/service.dart';
import '../../model/service.dart';
import 'all_services.dart';
import 'service_detail.dart';

class CustHomepage extends StatefulWidget {
  const CustHomepage({super.key});

  @override
  State<CustHomepage> createState() => _CustHomepageState();
}

class _CustHomepageState extends State<CustHomepage> {
  late UserController _userController;
  late Future<UserModel?> _userFuture;

  bool _isMenuOpen = false;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _userController = UserController(
      showErrorSnackBar: (message) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(message)));
        }
      },
    );
    _userFuture = _getCurrentUser();
  }

  void _handleLogout(BuildContext context) async {
    print("Logout selected");
    if (!mounted) return;

    await ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Logging you out...'))).closed;

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<UserModel?> _getCurrentUser() async {
    return await _userController.getCurrentUser();
  }

  void _onNavBarTap(int index) {
    setState(() {
      _currentIndex = index;
    });

    switch (index) {
      case 0:
        break;
      case 1:
        Navigator.pushNamed(context, '/home');
        break;
      case 2:
        Navigator.pushNamed(context, '/home');
        break;
      case 3:
        Navigator.pushNamed(context, '/home');
        break;
      // More menu (index 4) is handled in the navigation bar itself
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 70,
        automaticallyImplyLeading: false,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        title: Row(
          children: [
            const CircleAvatar(
              radius: 26,
              backgroundImage: AssetImage('assets/images/profile.jpg'),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Good Morning,',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
                ),
                FutureBuilder<UserModel?>(
                  future: _userFuture,
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
        ),
        actions: [
          Stack(
            alignment: Alignment.topRight,
            children: [
              const Icon(
                Icons.notifications_none_outlined,
                color: Colors.black,
                size: 30,
              ),
              Container(
                margin: const EdgeInsets.only(top: 4, right: 2),
                width: 15,
                height: 15,
                decoration: BoxDecoration(
                  color: Colors.orange,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Center(
                  child: Text(
                    '1',
                    style: TextStyle(
                      fontSize: 8,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Container(
            decoration: BoxDecoration(
              color: _isMenuOpen ? Colors.grey.shade300 : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'logout') _handleLogout(context);
                setState(() => _isMenuOpen = false);
              },
              onOpened: () => setState(() => _isMenuOpen = true),
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
      body: const HomepageScreen(),
      bottomNavigationBar: AppNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onNavBarTap,
      ),
    );
  }
}

class HomepageScreen extends StatefulWidget {
  const HomepageScreen({super.key});

  @override
  State<HomepageScreen> createState() => _HomepageScreenState();
}

class _HomepageScreenState extends State<HomepageScreen> {
  late Future<List<ServiceModel>> _servicesFuture;
  List<ServiceModel> _allServices = [];
  List<ServiceModel> _popularServices = [];

  @override
  void initState() {
    super.initState();
    _servicesFuture = _loadServices();
  }

  Future<List<ServiceModel>> _loadServices() async {
    try {
      final services = await ServiceController().getAllServices();
      print('Homepage: Loaded ${services.length} services');
      return services;
    } catch (e) {
      print('Homepage Error: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ServiceModel>>(
      future: _servicesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
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

        _allServices = snapshot.data!;
        // Get first 8 services for category icons, rest for popular
        _popularServices = _allServices.length > 8
            ? _allServices.sublist(8)
            : [];

        return RefreshIndicator(
          onRefresh: () => _servicesFuture = _loadServices(),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              const SizedBox(height: 10),
              _buildServicesSection(_allServices.take(8).toList()),
              const SizedBox(height: 24),
              _buildPopularServicesSection(),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildServicesSection(List<ServiceModel> services) {
    // Determine how many actual service icons to show (max 7)
    final int serviceIconCount = services.length < 7 ? services.length : 7;
    // Determine if we need to show the 'More' icon
    final bool showMoreIcon =
        services.length >= 7; // Show 'More' if 7 or more services exist

    // Total items in the grid will be the service icons + 'More' icon if needed
    final int gridItemCount = serviceIconCount + (showMoreIcon ? 1 : 0);

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
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
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
                print('Tapped: ${service.serviceName}'); // ✅ DEBUG
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ServiceDetailPage(service: service),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildPopularServicesSection() {
    if (_popularServices.isEmpty) {
      return const SizedBox.shrink();
    }

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
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AllServicesScreen(),
                ),
              ),
              child: Text(
                'View all',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        ..._popularServices
            .take(3)
            .map(
              (service) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: ServiceCard(
                  title: service.serviceName,
                  provider: 'Service Team',
                  price: 'RM ${service.servicePrice.toStringAsFixed(0)} / hour',
                  rating: 4.8,
                  reviews: 80,
                  imageUrl: 'assets/images/profile.jpg',
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
  final String provider;
  final String price;
  final double rating;
  final int reviews;
  final String imageUrl;

  const ServiceCard({
    required this.title,
    required this.provider,
    required this.price,
    required this.rating,
    required this.reviews,
    required this.imageUrl,
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
            color: Colors.grey.withOpacity(0.1),
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
              image: DecorationImage(
                image: AssetImage(imageUrl),
                fit: BoxFit.cover,
              ),
            ),
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
                Text(
                  provider,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      price,
                      style: const TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    const Icon(Icons.star, color: Colors.amber, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '$rating | $reviews reviews',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
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
