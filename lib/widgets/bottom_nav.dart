import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class BottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTap;

  const BottomNavBar({
    Key? key,
    required this.selectedIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final items = [
      {'icon': 'assets/icons/home-icon.svg', 'label': 'Home'},
      {'icon': 'assets/icons/habit-icon.svg', 'label': 'Habit'},
      {'icon': 'assets/icons/mood-icon.svg', 'label': 'Mood'},
      {'icon': 'assets/icons/journal-icon.svg', 'label': 'Journal'},
    ];

    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed, // always shows text
  currentIndex: selectedIndex,
  onTap: onTap,
  selectedItemColor: Theme.of(context).colorScheme.primary,
  unselectedItemColor: Colors.grey,
  showUnselectedLabels: true, // also shows labels for unselected tabs
  items: items.map((item) {
    int index = items.indexOf(item);
    return BottomNavigationBarItem(
      icon: SvgPicture.asset(
        item['icon']!,
        colorFilter: ColorFilter.mode(
          index == selectedIndex
              ? Theme.of(context).colorScheme.primary
              : Colors.grey,
          BlendMode.srcIn,
        ),
        height: 24,
      ),
      label: item['label'],
    );
  }).toList(),
    );
  }
}
