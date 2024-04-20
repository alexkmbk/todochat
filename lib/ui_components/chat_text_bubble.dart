import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:todochat/customWidgets.dart';
import 'package:todochat/ui_components/tile_menu.dart';

class ChatTextBubble extends StatefulWidget {
  final String text;
  final GestureTapCallback? onTap;
  //final GestureTapDownCallback? onSecondaryTapDown;
  final Function? onCopy;
  final Function? onEdit;
  final Function? onReply;
  final Function? onDelete;
  final Function(String selectedText)? onQuoteSelection;
  final Function? onTapOnQuotedMessage;
  final Color? backgroundColor;
  final String? quotedText;
  final String? quotedImageURL;
  final Map<String, String>? headers;

  const ChatTextBubble(
      {super.key,
      required this.text,
      this.onTap,
      this.onCopy,
      this.onReply,
      this.onDelete,
      this.onQuoteSelection,
      this.backgroundColor,
      this.quotedText,
      this.onTapOnQuotedMessage,
      this.quotedImageURL,
      this.headers,
      this.onEdit});

  @override
  State<ChatTextBubble> createState() => _ChatTextBubbleState();
}

class _ChatTextBubbleState extends State<ChatTextBubble> {
  bool editMode = false;
  final FocusNode focusNode = FocusNode();
  String selectedText = "";

  TextSelection textWidgetSelection =
      const TextSelection(baseOffset: 0, extentOffset: 0);
  late GestureDetectorWithMenu textGestureDetectorWithMenu;

  @override
  Widget build(BuildContext context) {
    // var textSpan =
    //     TextSpan(text: "", recognizer: TapGestureRecognizer()..onTap = () {});

    // var tapRecognizer = TapGestureRecognizer();
    // tapRecognizer.onTap = () {};

    final textWidget = Text(
      widget.text,
    );

    // final textSpan = TextSpan(
    //   text: widget.text,
    //   recognizer: TapGestureRecognizer()
    //     ..onSecondaryTapDown = (value) {
    //       TileMenu(
    //         position: value.globalPosition,
    //         onCopy: () {
    //           if (widget.onCopy != null) {
    //             widget.onCopy!();
    //           }
    //         },
    //         onQuoteSelection: textWidgetSelection.start !=
    //                 textWidgetSelection.end
    //             ? () {
    //                 if (widget.onQuoteSelection != null) {
    //                   var selectedText = "";
    //                   selectedText = widget.text.substring(
    //                       textWidgetSelection.start, textWidgetSelection.end);
    //                   widget.onQuoteSelection!(selectedText);
    //                 }
    //               }
    //             : null,
    //       ).show(context);
    //     },
    // );
    // //BoolRef isQuoteSelected = BoolRef();
    // final textWidget = SelectableText.rich(
    //   textSpan,
    //   onSelectionChanged: (selection, cause) {
    //     textWidgetSelection = selection;
    //     textGestureDetectorWithMenu.isQuoteSelected = true;
    //   },
    //   contextMenuBuilder: null,
    // );

    return SelectionArea(
      onSelectionChanged: (value) {
        if (value != null)
          selectedText = value.plainText;
        else
          selectedText = "";
      },
      contextMenuBuilder: (context, selectableRegionState) {
        return TileMenu(
          addMenuItems: selectableRegionState.contextMenuButtonItems,
          selectableRegionState: selectableRegionState,
          onQuoteSelection:
              selectedText.isNotEmpty ? widget.onQuoteSelection : null,
          onDelete: widget.onDelete,
          onEdit: widget.onEdit,
          onReply: widget.onReply,
        );
        // final List<ContextMenuButtonItem> buttonItems =
        //     editableTextState.contextMenuButtonItems;
        // if (selectedText.isNotEmpty) {
        //   buttonItems.insert(
        //       0,
        //       ContextMenuButtonItem(
        //         label: 'Quote selection',
        //         onPressed: () {
        //           ContextMenuController.removeAny();
        //           widget.onQuoteSelection!(selectedText);
        //         },
        //       ));
        // }
        // return AdaptiveTextSelectionToolbar.buttonItems(
        //   anchors: editableTextState.contextMenuAnchors,
        //   buttonItems: buttonItems,
        // );
      },
      child: DecoratedBox(
        // chat bubble decoration
        decoration: BoxDecoration(
          border: Border.all(color: const Color.fromARGB(255, 228, 232, 233)),
          color: widget.backgroundColor ??
              const Color.fromARGB(255, 187, 239, 251),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          //child: IntrinsicWidth(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (widget.quotedText != null && widget.quotedText!.isNotEmpty)
              MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                      onTap: () {
                        if (widget.onTapOnQuotedMessage != null)
                          widget.onTapOnQuotedMessage!();
                      },
                      child: Text(
                        widget.quotedText ?? "",
                        style: const TextStyle(color: Colors.grey),
                      ))),
            if (widget.quotedImageURL != null &&
                widget.quotedImageURL!.isNotEmpty)
              MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: networkImage(
                    widget.quotedImageURL ?? "",
                    height: 60,
                    headers: widget.headers,
                    onTap: () {
                      if (widget.onTapOnQuotedMessage != null)
                        widget.onTapOnQuotedMessage!();
                    },
                  )),
            if (widget.quotedText != null && widget.quotedText!.isNotEmpty)
              const Divider(),
            textWidget,
          ]),
        ),
        //  ),
      ),
    );
    textGestureDetectorWithMenu = GestureDetectorWithMenu(
      isQuoteSelected: textWidgetSelection.start != 0,
      onCopy: () {
        if (widget.onCopy != null) {
          widget.onCopy!();
        }
      },
      onReply: () {
        if (widget.onReply != null) widget.onReply!();
      },
      onDelete: () {
        if (widget.onDelete != null) widget.onDelete!();
      },
      onQuoteSelection: () {
        if (widget.onQuoteSelection != null) {
          var selectedText = "";
          if (textWidgetSelection.start != textWidgetSelection.end) {
            selectedText = widget.text
                .substring(textWidgetSelection.start, textWidgetSelection.end);
          }
          widget.onQuoteSelection!(selectedText);
        }
      },
      onEdit: () {
        if (widget.onEdit != null) {
          widget.onEdit!();
        }
      },
      child: SelectionArea(
        child: DecoratedBox(
          // chat bubble decoration
          decoration: BoxDecoration(
            border: Border.all(color: const Color.fromARGB(255, 228, 232, 233)),
            color: widget.backgroundColor ??
                const Color.fromARGB(255, 187, 239, 251),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            //child: IntrinsicWidth(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (widget.quotedText != null && widget.quotedText!.isNotEmpty)
                MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                        onTap: () {
                          if (widget.onTapOnQuotedMessage != null)
                            widget.onTapOnQuotedMessage!();
                        },
                        child: Text(
                          widget.quotedText ?? "",
                          style: const TextStyle(color: Colors.grey),
                        ))),
              if (widget.quotedImageURL != null &&
                  widget.quotedImageURL!.isNotEmpty)
                MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: networkImage(
                      widget.quotedImageURL ?? "",
                      height: 60,
                      headers: widget.headers,
                      onTap: () {
                        if (widget.onTapOnQuotedMessage != null)
                          widget.onTapOnQuotedMessage!();
                      },
                    )),
              if (widget.quotedText != null && widget.quotedText!.isNotEmpty)
                const Divider(),
              textWidget,
            ]),
          ),
          //  ),
        ),
      ),
    );
    return textGestureDetectorWithMenu;
  }
}

// class ChatTextBubble extends StatefulWidget {
//   final String text;
//   final GestureTapCallback? onTap;
//   //final GestureTapDownCallback? onSecondaryTapDown;
//   final Function? onCopy;
//   final Function? onEdit;
//   final Function? onReply;
//   final Function? onDelete;
//   final Function(String selectedText)? onQuoteSelection;
//   final Function? onTapOnQuotedMessage;
//   final Color? backgroundColor;
//   final String? quotedText;
//   final String? quotedImageURL;
//   final Map<String, String>? headers;

//   const ChatTextBubble(
//       {super.key,
//       required this.text,
//       this.onTap,
//       this.onCopy,
//       this.onReply,
//       this.onDelete,
//       this.onQuoteSelection,
//       this.backgroundColor,
//       this.quotedText,
//       this.onTapOnQuotedMessage,
//       this.quotedImageURL,
//       this.headers,
//       this.onEdit});

//   @override
//   State<ChatTextBubble> createState() => _ChatTextBubbleState();
// }

// class _ChatTextBubbleState extends State<ChatTextBubble> {
//   bool editMode = false;
//   TextSelection textWidgetSelection =
//       const TextSelection(baseOffset: 0, extentOffset: 0);
//   late GestureDetectorWithMenu textGestureDetectorWithMenu;

//   @override
//   Widget build(BuildContext context) {
//     final textSpan = TextSpan(
//       text: widget.text,
//       // recognizer: TapGestureRecognizer()
//       //   ..onSecondaryTapDown = (value) {
//       //     print('Tap Here onTap');
//       //   },
//     );
//     //BoolRef isQuoteSelected = BoolRef();
//     final textWidget = SelectableText.rich(
//       textSpan,
//       onSelectionChanged: (selection, cause) {
//         textWidgetSelection = selection;
//         textGestureDetectorWithMenu.isQuoteSelected = true;
//       },
//       contextMenuBuilder: null,
//     );

//     textGestureDetectorWithMenu = GestureDetectorWithMenu(
//       isQuoteSelected: textWidgetSelection.start != 0,
//       onCopy: () {
//         if (widget.onCopy != null) {
//           widget.onCopy!();
//         }
//       },
//       onReply: () {
//         if (widget.onReply != null) widget.onReply!();
//       },
//       onDelete: () {
//         if (widget.onDelete != null) widget.onDelete!();
//       },
//       onQuoteSelection: () {
//         if (widget.onQuoteSelection != null) {
//           var selectedText = "";
//           if (textWidgetSelection.start != textWidgetSelection.end) {
//             selectedText = widget.text
//                 .substring(textWidgetSelection.start, textWidgetSelection.end);
//           }
//           widget.onQuoteSelection!(selectedText);
//         }
//       },
//       onEdit: () {
//         if (widget.onEdit != null) {
//           widget.onEdit!();
//         }
//       },
//       child: DecoratedBox(
//         // chat bubble decoration
//         decoration: BoxDecoration(
//           border: Border.all(color: const Color.fromARGB(255, 228, 232, 233)),
//           color: widget.backgroundColor ??
//               const Color.fromARGB(255, 187, 239, 251),
//           borderRadius: BorderRadius.circular(8),
//         ),
//         child: Padding(
//           padding: const EdgeInsets.all(12),
//           //child: IntrinsicWidth(
//           child:
//               Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//             if (widget.quotedText != null && widget.quotedText!.isNotEmpty)
//               MouseRegion(
//                   cursor: SystemMouseCursors.click,
//                   child: GestureDetector(
//                       onTap: () {
//                         if (widget.onTapOnQuotedMessage != null)
//                           widget.onTapOnQuotedMessage!();
//                       },
//                       child: Text(
//                         widget.quotedText ?? "",
//                         style: const TextStyle(color: Colors.grey),
//                       ))),
//             if (widget.quotedImageURL != null &&
//                 widget.quotedImageURL!.isNotEmpty)
//               MouseRegion(
//                   cursor: SystemMouseCursors.click,
//                   child: networkImage(
//                     widget.quotedImageURL ?? "",
//                     height: 60,
//                     headers: widget.headers,
//                     onTap: () {
//                       if (widget.onTapOnQuotedMessage != null)
//                         widget.onTapOnQuotedMessage!();
//                     },
//                   )),
//             if (widget.quotedText != null && widget.quotedText!.isNotEmpty)
//               const Divider(),
//             textWidget,
//           ]),
//         ),
//         //  ),
//       ),
//     );
//     return textGestureDetectorWithMenu;
//   }
// }
