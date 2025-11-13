import 'package:flutter/material.dart';

class CustNavigationBar extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  State<CustNavigationBar> createState() => CustNavigationBarState();
}

class CustNavigationBarState extends State<CustNavigationBar> {
  final Map<int, GlobalKey> itemKeys = {4: GlobalKey()};

  Future<void> showMoreMenu(BuildContext context) async {
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final offset = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    final value = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        offset.dx,
        offset.dy - 120,
        offset.dx + size.width,
        offset.dy,
      ),
      items: const [
        PopupMenuItem(value: 'billPayment', child: Text('Bill and Payment')),
        PopupMenuItem(value: 'profile', child: Text('Profile')),
        // PopupMenuItem(value: 'settings', child: Text('Settings')),
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
