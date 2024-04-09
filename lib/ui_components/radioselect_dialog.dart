import 'package:flutter/material.dart';

class RadioSelectDialog<T> extends StatelessWidget {
  final Map<T, String> choiceMap;
  final T? currentValue;
  const RadioSelectDialog(
      {super.key, required this.choiceMap, this.currentValue});

  static Future<T?> choice<T>(
      {required BuildContext context,
      required Map<T, String> choiceMap,
      T? currentValue}) async {
    return await showDialog<T>(
        context: context,
        builder: (BuildContext context) {
          return RadioSelectDialog<T>(
            choiceMap: choiceMap,
            currentValue: currentValue,
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> radioWidgets = [];

    for (var element in choiceMap.entries) {
      radioWidgets.add(
        RadioListTile(
          toggleable: true,
          title: Text(element.value),
          value: element.key,
          groupValue: currentValue,
          onChanged: (T? value) {
            Navigator.of(context).pop<T>(value);
          },
        ),
      );
    }
    return AlertDialog(
      shadowColor: Colors.transparent,
      //title: Text('Choose your favourite programming language!'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: radioWidgets,
      ),
    );
  }
}
