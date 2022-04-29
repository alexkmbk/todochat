import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photo_view/photo_view.dart';

Widget GetTextField(
    {TextEditingController? controller,
    String? hintText,
    String? labelText,
    FormFieldValidator<String>? validator,
    ValueChanged<String>? onFieldSubmitted,
    ValueChanged<String>? onChanged,
    final VoidCallback? onCleared,
    bool showClearButton = false,
    TextInputType? keyboardType,
    bool obscureText = false,
    Color? fillColor,
    Widget? prefixIcon,
    Iterable<String>? autofillHints}) {
  return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextFormField(
        autofillHints: autofillHints,
        decoration: InputDecoration(
          isDense: true,
          filled: fillColor == null ? false : true,
          fillColor: fillColor,
          labelText: labelText,
          hintText: hintText,
          border: const OutlineInputBorder(),
          prefixIcon: prefixIcon,
          suffixIcon: IconButton(
            onPressed: () {
              controller?.clear();
              if (onCleared != null) onCleared();
            },
            icon: const Icon(Icons.clear),
          ),
        ),
        validator: validator,
        controller: controller,
        onChanged: onChanged,
        onFieldSubmitted: onFieldSubmitted,
        keyboardType: keyboardType,
        obscureText: obscureText,
        autofocus: true,
      ));
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
    double width = 40,
    double height = 40,
    Uint8List? previewImageData}) {
  try {
    return GestureDetector(
        onTap: onTap,
        child: ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: Image.network(
              src,
              headers: headers,
              errorBuilder: (BuildContext context, Object exception,
                  StackTrace? stackTrace) {
                return Placeholder(
                  fallbackHeight: height,
                  fallbackWidth: width,
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
          child: Container(
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
  static const Size size = Size(60.0, 25.0);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(3.0),
        decoration: BoxDecoration(
          color: Colors.greenAccent,
          border: Border.all(color: Colors.yellow),
        ),
        child:
            Text('${timestamp.hour}:${timestamp.minute}:${timestamp.second}'),
      );
}
