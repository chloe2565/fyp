import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../model/user.dart';
import '../../navigatorBase.dart';
import '../../service/firestore_service.dart';
import 'all_services.dart';
import 'package:fyp/navigatorBase.dart';

class CustHomepage extends StatefulWidget {
  const CustHomepage({super.key});

  @override
  State<CustHomepage> createState() => _CustHomepageState();
}

class _CustHomepageState extends State<CustHomepage> {
  final FirestoreService _firestoreService = FirestoreService();
  bool _isMenuOpen = false;
  int _currentIndex = 0;

  void _handleLogout(BuildContext context) async {
    print("Logout selected");
    if (!mounted) return;

    await ScaffoldMessenger.of(context)
        .showSnackBar(
      const SnackBar(content: Text('Logging you out...')),
    )
        .closed;

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<UserModel?> _getCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    return await _firestoreService.getUserByAuthID(user.uid);
  }

  void _onNavBarTap(int index) {
    setState(() {
      _currentIndex = index;
    });

    switch (index) {
      case 0:
      // Already on homepage
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
    // Note: More menu (index 4) is handled in the navigation bar itself
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
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
                ),
                FutureBuilder<UserModel?>(
                  future: _getCurrentUser(),
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
                if (value == 'logout') {
                  _handleLogout(context);
                }
                setState(() {
                  _isMenuOpen = false;
                });
              },
              onOpened: () {
                setState(() {
                  _isMenuOpen = true;
                });
              },
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

class _ServiceItem {
  final IconData icon;
  final String label;
  final Color color;
  final Function(BuildContext) onPressed;

  _ServiceItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });
}

class HomepageScreen extends StatelessWidget {
  const HomepageScreen({super.key});

  static final List<_ServiceItem> _services = [
    _ServiceItem(icon: Icons.local_shipping, label: 'Moving', color: const Color(0xFF96D6D5), onPressed: (context) {}),
    _ServiceItem(icon: Icons.electrical_services, label: 'Electric', color: const Color(0xFFFFD2AA), onPressed: (context) {}),
    _ServiceItem(icon: Icons.plumbing, label: 'Plumbing', color: const Color(0xFFAAE8FF), onPressed: (context) {}),
    _ServiceItem(icon: Icons.wc, label: 'Toilet', color: const Color(0xFFAAD0FF), onPressed: (context) {}),
    _ServiceItem(icon: Icons.local_laundry_service, label: 'Laundry', color: const Color(0xFFF2B5F8), onPressed: (context) {}),
    _ServiceItem(icon: Icons.format_paint, label: 'Painting', color: const Color(0xFFDFD9FF), onPressed: (context) {}),
    _ServiceItem(icon: Icons.cleaning_services, label: 'Cleaning', color: const Color(0xFFC6E3B4), onPressed: (context) {}),
    _ServiceItem(icon: Icons.carpenter, label: 'Carpentry', color: const Color(0xFFFFBB29), onPressed: (context) {}),
    _ServiceItem(
      icon: Icons.more_horiz,
      label: 'More',
      color: const Color(0xFFFFA7A7),
      onPressed: (context) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AllServicesScreen()),
        );
      },
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: <Widget>[
        const SizedBox(height: 10),
        TextFormField(
          decoration: InputDecoration(
            hintText: 'Search here..',
            hintStyle: const TextStyle(color: Colors.grey),
            prefixIcon: const Icon(Icons.search, color: Colors.grey),
            suffixIcon: IconButton(
              icon: const Icon(Icons.tune, color: Colors.orange),
              onPressed: () {},
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.grey.shade200,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Services',
              style: Theme.of(context).textTheme.displayMedium?.copyWith(fontSize: 20, color: Colors.black),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AllServicesScreen()),
                );
              },
              child: Text(
                'View all',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.orange),
              ),
            ),
          ],
        ),
        GridView.builder(
          itemCount: _services.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 80,
            mainAxisSpacing: 5,
            crossAxisSpacing: 20,
            childAspectRatio: 0.75,
          ),
          itemBuilder: (context, index) {
            final service = _services[index];
            return ServiceIcon(
              icon: service.icon,
              label: service.label,
              color: service.color,
              iconColor: Colors.black,
              onPressed: service.onPressed,
            );
          },
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Most Popular Services',
              style: Theme.of(context).textTheme.displayMedium?.copyWith(fontSize: 20, color: Colors.black),
            ),
            TextButton(
              onPressed: () {},
              child: Text(
                'View all',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.orange),
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        ServiceCard(
          title: 'Cleaning',
          provider: 'Alex Tan',
          price: 'RM 25 / hour',
          rating: 4.8,
          reviews: 80,
          imageUrl: 'assets/images/profile.jpg',
        ),
        const SizedBox(height: 16),
        ServiceCard(
          title: 'Electric',
          provider: 'James Tan',
          price: 'RM 15 / hour',
          rating: 4.8,
          reviews: 80,
          imageUrl: 'assets/images/profile.jpg',
        ),
        const SizedBox(height: 16),
        ServiceCard(
          title: 'Air Conditioning',
          provider: 'Allen Lim',
          price: 'RM 20 / hour',
          rating: 4.8,
          reviews: 80,
          imageUrl: 'assets/images/profile.jpg',
        ),
        const SizedBox(height: 24),
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