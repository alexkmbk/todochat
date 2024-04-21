import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class ContextMenuDetector extends StatefulWidget {
  final Widget child;
  final GestureTapCallback? onTap;
  final Function(Offset position)? onContextMenu;

  ContextMenuDetector(
      {required this.child, Key? key, this.onContextMenu, this.onTap})
      : super(key: key);

  @override
  State<ContextMenuDetector> createState() => _ContextMenuDetectorState();
}

class _ContextMenuDetectorState extends State<ContextMenuDetector> {
  TapDownDetails? _tapDownDetails;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: widget.onTap,
        onTapDown: (details) {
          _tapDownDetails = details;
        },
        onSecondaryTapDown: (details) =>
            widget.onContextMenu?.call(details.globalPosition),
        onLongPress: () {
          if (_tapDownDetails != null &&
              _tapDownDetails!.kind != PointerDeviceKind.mouse) {
            widget.onContextMenu?.call(_tapDownDetails!.globalPosition);
          }
        },
        child: widget.child);
  }
}
