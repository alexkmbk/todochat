import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';

Widget getTextField({
  TextEditingController? controller,
  String? hintText,
  String? labelText,
  FormFieldValidator<String>? validator,
  ValueChanged<String>? onFieldSubmitted,
  ValueChanged<String>? onChanged,
  final VoidCallback? onCleared,
  bool showClearButton = true,
  TextInputType? keyboardType,
  bool obscureText = false,
  Color? fillColor,
  Widget? prefixIcon,
  Iterable<String>? autofillHints,
  FocusNode? focusNode,
  TextInputAction? textInputAction,
  InputBorder? border,
  TextAlign textAlign = TextAlign.left,
  double? width,
}) {
  final padding = Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextFormField(
        focusNode: focusNode,
        autofillHints: autofillHints,
        textAlign: textAlign,
        decoration: InputDecoration(
          isDense: true,
          filled: fillColor == null ? false : true,
          fillColor: fillColor,
          labelText: labelText,
          hintText: hintText,
          hintStyle: const TextStyle(color: Colors.grey),
          border: border ?? const OutlineInputBorder(),
          prefixIcon: prefixIcon,
          suffixIcon: showClearButton
              ? IconButton(
                  focusNode: FocusNode(skipTraversal: true),
                  onPressed: () {
                    controller?.clear();
                    if (onCleared != null) onCleared();
                  },
                  icon: const Icon(Icons.clear),
                )
              : null,
        ),
        validator: validator,
        controller: controller,
        onChanged: onChanged,
        onFieldSubmitted: onFieldSubmitted,
        keyboardType: keyboardType,
        obscureText: obscureText,
        autofocus: true,
        textInputAction: textInputAction ?? TextInputAction.next,
      ));

  if (width == null) {
    return padding;
  }
  return SizedBox(
    width: width,
    child: padding,
  );
}

/*class CustomAppBar extends PreferredSizeWidget{
  @override
  Element createElement() {
    // TODO: implement createElement
    throw UnimplementedError();
  }

  @override
  List<DiagnosticsNode> debugDescribeChildren() {
    // TODO: implement debugDescribeChildren
    throw UnimplementedError();
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    // TODO: implement debugFillProperties
  }

  @override
  // TODO: implement key
  Key? get key => throw UnimplementedError();

  @override
  // TODO: implement preferredSize
  Size get preferredSize => throw UnimplementedError();

  @override
  DiagnosticsNode toDiagnosticsNode({String? name, DiagnosticsTreeStyle? style}) {
    // TODO: implement toDiagnosticsNode
    throw UnimplementedError();
  }

  @override
  String toStringDeep({String prefixLineOne = '', String? prefixOtherLines, DiagnosticLevel minLevel = DiagnosticLevel.debug}) {
    // TODO: implement toStringDeep
    throw UnimplementedError();
  }

  @override
  String toStringShallow({String joiner = ', ', DiagnosticLevel minLevel = DiagnosticLevel.debug}) {
    // TODO: implement toStringShallow
    throw UnimplementedError();
  }

  @override
  String toStringShort() {
    // TODO: implement toStringShort
    throw UnimplementedError();
  }
  
}*/

Widget networkImage(String src,
    {Map<String, String>? headers,
    GestureTapCallback? onTap,
    double? width,
    double? height,
    Uint8List? previewImageData}) {
  try {
    return GestureDetector(
        onTap: onTap,
        child: ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: Image.network(
              src,
              height: height,
              headers: headers,
              errorBuilder: (BuildContext context, Object exception,
                  StackTrace? stackTrace) {
                return Image.asset(
                  'assets/images/image_error.png',
                  height: height ?? 200,
                  width: width,
                );
              },
              loadingBuilder: (BuildContext context, Widget child,
                  ImageChunkEvent? loadingProgress) {
                if (loadingProgress == null) return child;
                return SizedBox(
                    width: width,
                    height: height,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8.0),
                      child: previewImageData != null
                          ? Image.memory(
                              previewImageData,
                              width: width,
                              height: height,
                              fit: BoxFit.fill,
                            )
                          : null,
                    )); /*CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
                  ),*/
              },
            )));
  } catch (e) {
    return Image.asset(
      'assets/images/image_error.png',
      height: height ?? 200,
      width: width,
    );
  }
}

Widget memoryImage(Uint8List data,
    {Map<String, String>? headers,
    GestureTapCallback? onTap,
    double? width,
    double? height}) {
  try {
    return GestureDetector(
        onTap: onTap,
        child: ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: Image.memory(
              data,
              width: width,
              height: height,
            )));
  } catch (e) {
    return const Placeholder();
  }
}

class ImageDialog extends StatelessWidget {
  final FocusNode focusNode = FocusNode();
  final ImageProvider imageProvider;
  //final Uint8List imageData;
  final int fileSize;
  ImageDialog({Key? key, required this.imageProvider, this.fileSize = 0})
      : super(key: key);

  double calsProgress(ImageChunkEvent? event) {
    if (event == null) {
      return 0;
    } else {
      if (fileSize == 0) {
        if (event.expectedTotalBytes == null || event.expectedTotalBytes == 0) {
          return 0;
        } else {
          return event.cumulativeBytesLoaded /
              (event.expectedTotalBytes as int);
        }
      }
    }
    return event.cumulativeBytesLoaded / fileSize;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
        child: Stack(children: [
      PhotoView(
        imageProvider: imageProvider,
        loadingBuilder: (context, event) => Center(
          child: SizedBox(
            width: 20.0,
            height: 20.0,
            child: CircularProgressIndicator(
              value: calsProgress(event),
            ),
          ),
        ),
      ),
      Positioned(
          right: -2,
          top: -9,
          child: IconButton(
              icon: Icon(
                Icons.cancel,
                color: Colors.white.withOpacity(0.5),
                size: 18,
              ),
              onPressed: () => Navigator.pop(context)))
    ]));
  }
}

class Timestamp extends StatelessWidget {
  const Timestamp(this.timestamp);

  final DateTime timestamp;

  /// This size could be calculated similarly to the way the text size in
  /// [Bubble] is calculated instead of using magic values.
  static const Size size = Size(50.0, 20.0);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3.0),
      child: Text(
        '${timestamp.hour}:${timestamp.minute}',
        style: const TextStyle(color: Colors.grey),
      ),
    );
  }
}

class NavigationService {
  static GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
}

BuildContext? getGlobalContext() {
  return NavigationService.navigatorKey.currentContext;
}

class RestartWidget extends StatefulWidget {
  RestartWidget({Key? key, required this.builder, this.beforeRestart})
      : super(key: key);

  Function? beforeRestart;

  //final Widget child;
  final Function builder;

  static void restartApp([BuildContext? context]) {
    context ??= NavigationService.navigatorKey.currentContext;
    context!.findAncestorStateOfType<_RestartWidgetState>()?.restartApp();
  }

  @override
  _RestartWidgetState createState() => _RestartWidgetState();
}

class _RestartWidgetState extends State<RestartWidget> {
  Key key = UniqueKey();

  void restartApp() {
    if (widget.beforeRestart != null) {
      widget.beforeRestart!();
    }

    setState(() {
      key = UniqueKey();
    });
  }

  void rebuildAllChildren(BuildContext context) {
    void rebuild(Element el) {
      el.markNeedsBuild();
      el.visitChildren(rebuild);
    }

    (context as Element).visitChildren(rebuild);
  }

  @override
  Widget build(BuildContext context) {
    //rebuildAllChildren(context);
    return KeyedSubtree(
      key: key,
      child: widget.builder(),
    );
  }
}

class TextInCircle extends StatelessWidget {
  final TextSpan textWidget;
  final double? width;
  final Color? color;
  const TextInCircle(
      {Key? key, required this.textWidget, this.width, this.color})
      : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: width,
      decoration: BoxDecoration(
        //border: Border.all(width: 2),
        shape: BoxShape.circle,
        color: color,
      ),
      child: Center(
          child: Text.rich(
        textWidget,
        textAlign: TextAlign.center,
      )),
    );
  }
}

class NumberInStadium extends StatelessWidget {
  final int number;
  const NumberInStadium({Key? key, required this.number}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
        child: Center(
            child: Text(
          number.toString(),
          style: const TextStyle(color: Colors.white, fontSize: 12),
        )),
        padding: const EdgeInsets.only(left: 5, right: 5),
        decoration: BoxDecoration(
            color: Colors.blue,
            shape: number < 10 ? BoxShape.circle : BoxShape.rectangle,
            borderRadius: number < 10
                ? null
                : const BorderRadius.only(
                    topLeft: Radius.circular(10),
                    bottomLeft: Radius.circular(10),
                    topRight: Radius.circular(10),
                    bottomRight: Radius.circular(10),
                  )));
  }
}

class Label extends StatelessWidget {
  final String text;
  final Color? backgroundColor;

  const Label({Key? key, required this.text, this.backgroundColor})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Chip(
        visualDensity: const VisualDensity(horizontal: 0.0, vertical: -4),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(5))),
        backgroundColor: backgroundColor,
        label: Text(
          text,
        ));
  }
}
