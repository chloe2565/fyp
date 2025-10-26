import 'package:flutter/material.dart';

class AppNavigationBar extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;

  const AppNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  State<AppNavigationBar> createState() => AppNavigationBarState();
}

class AppNavigationBarState extends State<AppNavigationBar> {
  final Map<int, GlobalKey> itemKeys = {4: GlobalKey()};

  Future<void> showMoreMenu(BuildContext context) async {
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return; // safety check

    final offset = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    final value = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        offset.dx,
        offset.dy - 167,
        offset.dx + size.width,
        offset.dy,
      ),
      items: const [
        PopupMenuItem(value: 'profile', child: Text('Profile')),
        PopupMenuItem(value: 'settings', child: Text('Settings')),
        PopupMenuItem(value: 'billPayment', child: Text('Bill and Payment')),
      ],
    );

    if (value == null) return;

    switch (value) {
      case 'profile':
        Navigator.pushNamed(context, '/profile');
        break;
      case 'settings':
        Navigator.pushNamed(context, '/settings');
        break;
      case 'billPayment':
        Navigator.pushNamed(context, '/billPayment');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: widget.currentIndex,
      onTap: (index) {
        if (index == 4) {
          final key = itemKeys[index];
          final itemContext = key?.currentContext;
          if (itemContext != null) {
            showMoreMenu(itemContext);
          }
        } else {
          widget.onTap(index);
        }
      },
      selectedItemColor: Theme.of(context).colorScheme.primary,
      unselectedItemColor: Colors.grey,
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
      iconSize: 24,
      selectedFontSize: 12,
      unselectedFontSize: 12,
      items: [
        const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        const BottomNavigationBarItem(
          icon: Icon(Icons.description_outlined),
          label: 'Request',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.bookmark_border),
          label: 'Favorite',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.thumb_up_alt_outlined),
          label: 'Rating',
        ),
        BottomNavigationBarItem(
          icon: Builder(
            builder: (context) {
              // assign key here so we can later access its position
              return SizedBox(
                key: itemKeys[4],
                height: 25,
                child: const Icon(Icons.more_horiz),
              );
            },
          ),
          label: 'More',
        ),
      ],
    );
  }
}
