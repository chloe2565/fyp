import 'package:flutter/material.dart';

class EmpNavigationBar extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;

  const EmpNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  State<EmpNavigationBar> createState() => EmpNavigationBarState();
}

class EmpNavigationBarState extends State<EmpNavigationBar> {
  final Map<int, GlobalKey> itemKeys = {3: GlobalKey()};

  Future<void> showMoreMenu(BuildContext context) async {
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final offset = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    final value = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        offset.dx,
        offset.dy - 217,
        offset.dx + size.width,
        offset.dy,
      ),
      items: const [
        PopupMenuItem(value: 'empAllService', child: Text('Service')),
        PopupMenuItem(value: 'billPayment', child: Text('Bill and Payment')),
        PopupMenuItem(value: 'profile', child: Text('Profile')),
        PopupMenuItem(value: 'settings', child: Text('Settings')),
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
      case 'empAllService':
        Navigator.pushNamed(context, '/empAllService');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: widget.currentIndex,
      onTap: (index) {
        if (index == 3) {
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
        const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Dashboard'),
        const BottomNavigationBarItem(
          icon: Icon(Icons.description),
          label: 'Requests',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.groups),
          label: 'Employees',
        ),
        BottomNavigationBarItem(
          icon: Builder(
            builder: (context) {
              return SizedBox(
                key: itemKeys[3],
                height: 25,
                child: const Icon(Icons.more_horiz_outlined),
              );
            },
          ),
          label: 'More',
        ),
      ],
    );
  }
}
