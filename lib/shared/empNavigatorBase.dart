import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

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
  final storage = const FlutterSecureStorage();

  Future<void> showMoreMenu(BuildContext context) async {
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final offset = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;
    final empType = await storage.read(key: 'empType') ?? 'handyman';

    final List<PopupMenuItem<String>> items = [
      const PopupMenuItem(value: 'empAllService', child: Text('Service')),
      const PopupMenuItem(value: 'empProfile', child: Text('Profile')),
      const PopupMenuItem(value: 'settings', child: Text('Settings')),
    ];

    if (empType == 'admin') {
      items.insert(
        1,
        const PopupMenuItem(
          value: 'empBillPayment',
          child: Text('Bill and Payment'),
        ),
      );
    }

    final menuHeight = 55 * items.length;
    final value = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        offset.dx,
        offset.dy - menuHeight,
        offset.dx + size.width,
        offset.dy,
      ),
      items: items,
    );

    if (value == null) return;

    switch (value) {
      case 'empAllService':
        Navigator.pushNamed(context, '/empAllService');
        break;
      case 'empBillPayment':
        Navigator.pushNamed(context, '/empBillPayment');
        break;
      case 'empProfile':
        Navigator.pushNamed(context, '/empProfile');
        break;
      case 'settings':
        Navigator.pushNamed(context, '/settings');
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
        const BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Dashboard',
        ),
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
