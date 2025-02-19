import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' as dev;



class FilterMenu extends StatelessWidget {
  final Function(String) onTypeChanged;
  const FilterMenu({super.key, required this.onTypeChanged});
  Future<void> _showMenu(BuildContext context) async {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              title: const Text('Protanopia'),
              onTap: () {
                onTypeChanged('Protanopia');
                dev.debugPrint('Protanopia');
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Deuteranopia'),
              onTap: () {
                onTypeChanged('Deuteranopia');  
                dev.debugPrint('Deuteranopia');
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Tritanopia'),
              onTap: () {
                onTypeChanged('Tritanopia');
                dev.debugPrint('Tritanopia');
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Achromatopsia'),
              onTap: () {
                onTypeChanged('Achromatopsia');
                dev.debugPrint('Achromatopsia');
                Navigator.pop(context);
              },
            )
          ],
        );
      },
    );
  }
  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () => _showMenu(context),
      child: const Icon(Icons.list),
    );
  }
}

