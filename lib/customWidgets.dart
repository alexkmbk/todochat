import 'dart:io';
import 'dart:math';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:drop_down_search_field/drop_down_search_field.dart';
import 'package:todochat/ui_components/confirm_detele_dlg.dart';
import 'utils.dart';
import 'package:simple_gesture_detector/simple_gesture_detector.dart';

class TextFieldEx extends StatelessWidget {
  final TextEditingController? controller;
  final String? hintText;
  final String? labelText;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onFieldSubmitted;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onCleared;
  final bool showClearButton;
  final TextInputType keyboardType;
  final bool obscureText;
  final Color? fillColor;
  final Widget? prefixIcon;
  final List<String>? autofillHints;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final InputBorder? border;
  final TextAlign textAlign;
  final double? width;
  final List<String>? choiceList;

  const TextFieldEx(
      {this.controller,
      this.hintText,
      this.labelText,
      this.autofillHints,
      this.border,
      this.choiceList,
      this.fillColor,
      this.focusNode,
      this.keyboardType = TextInputType.text,
      this.obscureText = false,
      this.onChanged,
      this.onCleared,
      this.onFieldSubmitted,
      this.prefixIcon,
      this.showClearButton = true,
      this.textAlign = TextAlign.left,
      this.textInputAction,
      this.validator,
      this.width,
      Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final padding = Padding(
      padding: const EdgeInsets.all(8.0),
      child: DropDownSearchFormField(
        textFieldConfiguration: TextFieldConfiguration(
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
            enabledBorder: const OutlineInputBorder(
              borderSide: const BorderSide(color: Colors.grey),
            ),
            focusedBorder: const OutlineInputBorder(
              borderSide: const BorderSide(color: Colors.lightBlue, width: 2),
            ),
            border: border ??
                const OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.grey),
                ),
            prefixIcon: prefixIcon,
            suffixIcon: showClearButton ||
                    (choiceList != null && choiceList!.isNotEmpty)
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                        // if (choiceList != null && choiceList.isNotEmpty)
                        //   PopupMenuButton<String>(
                        //       padding: EdgeInsets.zero,
                        //       constraints: BoxConstraints(),
                        //       onSelected: (String value) {},
                        //       icon: Icon(Icons.arrow_drop_down),
                        //       itemBuilder: (BuildContext bc) {
                        //         var addresses =
                        //             settings.getStringList("addresses");
                        //         if (addresses != null && addresses.isNotEmpty) {
                        //           return addresses
                        //               .map((String item) => PopupMenuItem<String>(
                        //                     value: item,
                        //                     child: Text(item),
                        //                   ))
                        //               .toList();
                        //         } else
                        //           return new List.empty();
                        //       }),
                        IconButton(
                          focusNode: FocusNode(skipTraversal: true),
                          onPressed: () {
                            controller?.clear();
                            if (onCleared != null) onCleared!();
                          },
                          icon: const Icon(Icons.clear),
                        )
                      ])
                : null,
          ),
          controller: controller,
          onChanged: onChanged,
          onSubmitted: onFieldSubmitted,
          keyboardType: keyboardType,
          obscureText: obscureText,
          autofocus: true,
          textInputAction: textInputAction ?? TextInputAction.next,
        ),
        hideOnEmpty: true,
        suggestionsCallback: (pattern) {
          if (choiceList == null || pattern.isEmpty)
            return List.empty();
          else {
            return choiceList!
                .where((element) =>
                    element.contains(pattern) && element != pattern)
                .toList();
          }
        },
        itemBuilder: (context, itemData) {
          return ListTile(
            title: Text(itemData.toString()),
          );
        },
        onSuggestionSelected: (suggestion) {
          if (controller != null) controller!.text = suggestion.toString();
          if (onChanged != null) onChanged!(suggestion.toString());
          if (onFieldSubmitted != null)
            onFieldSubmitted!(suggestion.toString());
        },
        validator: validator,
      ),
    );

    if (width == null) {
      return padding;
    }
    return SizedBox(
      width: width,
      child: padding,
    );
  }
}

class BoolRef {
  bool value = false;
}

class NetworkImageWithMenu extends StatefulWidget {
  final String src;
  final Map<String, String>? headers;
  final GestureTapCallback? onTap;
  final Function? onCopy;
  final Function? onReply;
  final Function? onDelete;
  final Function? onCopyOriginal;
  final double? width;
  final double? height;
  final Uint8List? previewImageData;
  final List<PopupMenuEntry>? addMenuItems;

  const NetworkImageWithMenu(this.src,
      {this.headers,
      this.onCopy,
      this.onTap,
      this.onReply,
      this.onDelete,
      this.onCopyOriginal,
      this.width,
      this.height,
      this.previewImageData,
      this.addMenuItems,
      Key? key})
      : super(key: key);

  @override
  State<NetworkImageWithMenu> createState() => _NetworkImageWithMenuState();
}

class _NetworkImageWithMenuState extends State<NetworkImageWithMenu> {
  TapDownDetails? _tapDownDetails;

  void onSecondaryTapDown(TapDownDetails details, BuildContext context) async {
    final x = details.globalPosition.dx;
    final y = details.globalPosition.dy;
    final res = await showMenu(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(
        Radius.circular(10.0),
      )),
      popUpAnimationStyle: AnimationStyle.noAnimation,
      color: Colors.white,
      surfaceTintColor: Colors.white,
      context: context,
      position: RelativeRect.fromLTRB(x, y, x, y),
      items: [
        if (widget.onCopy != null)
          PopupMenuItem<String>(
              child: const Text('Copy'),
              onTap: () async {
                if (widget.onCopy != null) {
                  widget.onCopy!();
                }
              }),
        if (widget.onCopyOriginal != null)
          const PopupMenuItem<String>(
            value: "CopyOriginal",
            child: Text('Copy original quality picture'),
          ),
        if (widget.onReply != null)
          PopupMenuItem<String>(
              child: const Text('Reply'),
              onTap: () async {
                if (widget.onReply != null) {
                  widget.onReply!();
                }
              }),
        if (widget.onDelete != null)
          const PopupMenuItem<String>(
            value: 'Delete',
            child: Text('Delete'),
          ),
      ],
    );
    if (res == "Delete") {
      var res = await ConfirmDeleteDlg.show(context);
      if (res ?? false) {
        if (widget.onDelete != null) {
          widget.onDelete!();
        }
      }
    } else if (res == "CopyOriginal") {
      if (widget.onCopyOriginal != null) {
        widget.onCopyOriginal!();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    try {
      return GestureDetector(
          onTap: widget.onTap,
          onTapDown: (details) {
            _tapDownDetails = details;
          },
          onSecondaryTapDown: (details) => onSecondaryTapDown(details, context),
          onLongPress: () => _tapDownDetails != null
              ? onSecondaryTapDown(_tapDownDetails!, context)
              : null,
          child: ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: Image.network(
                widget.src,
                height: widget.height,
                headers: widget.headers,
                errorBuilder: (BuildContext context, Object exception,
                    StackTrace? stackTrace) {
                  return Image.asset(
                    'assets/images/image_error.png',
                    height: widget.height ?? 200,
                    width: widget.width,
                  );
                },
                loadingBuilder: (BuildContext context, Widget child,
                    ImageChunkEvent? loadingProgress) {
                  if (loadingProgress == null) return child;
                  return SizedBox(
                      width: widget.width,
                      height: widget.height,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8.0),
                        child: widget.previewImageData != null
                            ? Image.memory(
                                widget.previewImageData!,
                                width: widget.width,
                                height: widget.height,
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
        height: widget.height ?? 200,
        width: widget.width,
      );
    }
  }
}

Widget networkImage(String src,
    {Map<String, String>? headers,
    GestureTapCallback? onTap,
    GestureTapCallback? onSecondaryTap,
    GestureTapDownCallback? onSecondaryTapDown,
    double? width,
    double? height,
    Uint8List? previewImageData}) {
  TapDownDetails? tapDownDetails;
  try {
    return GestureDetector(
        onTap: onTap,
        onTapDown: (details) {
          tapDownDetails = details;
        },
        onSecondaryTap: onSecondaryTap,
        onSecondaryTapDown: onSecondaryTapDown,
        onLongPress: () => onSecondaryTapDown != null && tapDownDetails != null
            ? onSecondaryTapDown(tapDownDetails!)
            : null,
        child: ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: CachedNetworkImage(
              fadeOutDuration: const Duration(milliseconds: 0),
              fadeInDuration: const Duration(milliseconds: 0),
              imageUrl: src,
              height: height,
              httpHeaders: headers,
              errorWidget: (context, url, error) {
                return Image.asset(
                  'assets/images/image_error.png',
                  height: height ?? 200,
                  width: width,
                );
              },
              placeholder: (context, url) {
                return SizedBox(
                    width: width,
                    height: height,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8.0),
                      // child: previewImageData != null
                      //     ? Image.memory(
                      //         previewImageData,
                      //         width: width,
                      //         height: height,
                      //         fit: BoxFit.fill,
                      //       )
                      //     : null,
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
    GestureLongPressCallback? onLongPress,
    GestureTapCallback? onSecondaryTap,
    double? width,
    double? height}) {
  try {
    return GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        onSecondaryTap: onSecondaryTap,
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
      // PhotoView(
      //   initialScale: PhotoViewComputedScale.covered,
      //   imageProvider: imageProvider,
      //   loadingBuilder: (context, event) => Center(
      //     child: SizedBox(
      //       width: 20.0,
      //       height: 20.0,
      //       child: CircularProgressIndicator(
      //         value: calsProgress(event),
      //       ),
      //     ),
      //   ),
      // ),
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
  const Timestamp(this.timestamp, {Key? key}) : super(key: key);

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

class TextInCircle extends StatelessWidget {
  final TextSpan textWidget;
  final double? width;
  final Color? color;
  final Color? borderColor;
  final double borderWidth;
  const TextInCircle(
      {Key? key,
      required this.textWidget,
      this.width,
      this.color,
      this.borderColor,
      this.borderWidth = 5})
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
        border: Border.all(
            color: borderColor ?? Colors.blueAccent, width: borderWidth),
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
    return Align(
        alignment: Alignment.topCenter,
        child: Container(
            padding: const EdgeInsets.only(left: 5, right: 5, bottom: 3),
            decoration: BoxDecoration(
                color: Colors.lightBlue,
                shape: number < 10 ? BoxShape.circle : BoxShape.rectangle,
                borderRadius: number < 10
                    ? null
                    : const BorderRadius.only(
                        topLeft: Radius.circular(10),
                        bottomLeft: Radius.circular(10),
                        topRight: Radius.circular(10),
                        bottomRight: Radius.circular(10),
                      )),
            child: Text(
              number.toString(),
              style: const TextStyle(color: Colors.white),
            )));
  }
}

class Label extends StatelessWidget {
  final String text;
  final Color? backgroundColor;
  final VoidCallback? onPressed;
  final bool clickableCursor;
  static const TextStyle textStyle = const TextStyle(fontSize: 14, height: 1);
  static const shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(5)));
  static const padding = EdgeInsets.symmetric(horizontal: 10, vertical: 3);

  const Label(
      {Key? key,
      required this.text,
      this.backgroundColor,
      this.onPressed,
      this.clickableCursor = false})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (onPressed != null || clickableCursor) {
      return AbsorbPointer(
          child: ActionChip(
        padding: padding,
        visualDensity: const VisualDensity(horizontal: 0.0, vertical: -4),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: shape,
        backgroundColor: backgroundColor,
        onPressed: onPressed ?? () {},
        label: Text(
          text,
        ),
      ));
    } else {
      return UnconstrainedBox(
        child: Container(
          //width: calcTextSize(text, context, style: textStyle).width + 28,
          //color: backgroundColor,
          padding: padding,
          decoration: ShapeDecoration(
            color: backgroundColor,
            shape: shape,
          ),
          alignment: Alignment.center,
          child: Text(
            style: textStyle,
            text,
          ),
        ),
      );
      // return Chip(
      //   //labelPadding: EdgeInsets.all(0.0),
      //   padding: EdgeInsets.all(0.0),
      //   visualDensity: const VisualDensity(horizontal: -4.0, vertical: -4.0),
      //   materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      //   shape: const RoundedRectangleBorder(
      //       borderRadius: BorderRadius.all(Radius.circular(5))),
      //   backgroundColor: backgroundColor,
      //   label: Text(
      //     style: TextStyle(fontSize: 14, height: 1),
      //     text,
      //   ),
      // );
    }
  }
}

class AdjustableScrollController extends ScrollController {
  AdjustableScrollController([int extraScrollSpeed = 40]) {
    super.addListener(() {
      ScrollDirection scrollDirection = super.position.userScrollDirection;
      if (scrollDirection != ScrollDirection.idle) {
        double scrollEnd = super.offset +
            (scrollDirection == ScrollDirection.reverse
                ? extraScrollSpeed
                : -extraScrollSpeed);
        scrollEnd = min(super.position.maxScrollExtent,
            max(super.position.minScrollExtent, scrollEnd));
        jumpTo(scrollEnd);
      }
    });
  }
}
