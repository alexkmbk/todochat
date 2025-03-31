import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:todochat/todochat.dart';

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
    if (isDesktopMode)
      return Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (event) {
          if (event.kind == PointerDeviceKind.mouse &&
              event.buttons == kSecondaryMouseButton) {
            widget.onContextMenu?.call(event.position);
          }
        },
        child: widget.child,
      );
    else
      return GestureDetector(
          behavior: HitTestBehavior.opaque,
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
// class _ContextMenuDetectorState extends State<ContextMenuDetector> {
//   TapDownDetails? _tapDownDetails;
//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//         behavior: HitTestBehavior.opaque,
//         onTap: widget.onTap,
//         onTapDown: (details) {
//           _tapDownDetails = details;
//         },
//         onSecondaryTapDown: (details) =>
//             widget.onContextMenu?.call(details.globalPosition),
//         onLongPress: () {
//           if (_tapDownDetails != null &&
//               _tapDownDetails!.kind != PointerDeviceKind.mouse) {
//             widget.onContextMenu?.call(_tapDownDetails!.globalPosition);
//           }
//         },
//         child: widget.child);
//   }
// }

// class _ContextMenuDetectorState extends State<ContextMenuDetector> {
//   TapDownDetails? _tapDownDetails;
//   @override
//   Widget build(BuildContext context) {
//     return RawGestureDetector(
//       behavior: HitTestBehavior.opaque,
//       gestures: {
//         TapGestureRecognizer:
//             GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
//           () => TapGestureRecognizer(),
//           (instance) {
//             instance.onTap = widget.onTap;
//             instance.onTapDown = (details) {
//               _tapDownDetails = details;
//             };
//             instance.onSecondaryTapDown =
//                 (details) => widget.onContextMenu?.call(details.globalPosition);
//           },
//         ),
//         LongPressGestureRecognizer:
//             GestureRecognizerFactoryWithHandlers<LongPressGestureRecognizer>(
//           () => LongPressGestureRecognizer(),
//           (instance) {
//             instance.onLongPress = () {
//               if (_tapDownDetails != null &&
//                   _tapDownDetails!.kind != PointerDeviceKind.mouse) {
//                 widget.onContextMenu?.call(_tapDownDetails!.globalPosition);
//               }
//             };
//           },
//         ),
//       },
//       child: widget.child,
//     );
//   }
// }
