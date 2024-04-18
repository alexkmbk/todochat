import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:todochat/customWidgets.dart';

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
  TextSelection textWidgetSelection =
      const TextSelection(baseOffset: 0, extentOffset: 0);
  late GestureDetectorWithMenu textGestureDetectorWithMenu;

  @override
  Widget build(BuildContext context) {
    final textSpan = TextSpan(
      text: widget.text,
      // recognizer: TapGestureRecognizer()
      //   ..onSecondaryTapDown = (value) {
      //     print('Tap Here onTap');
      //   },
    );
    //BoolRef isQuoteSelected = BoolRef();
    final textWidget = SelectableText.rich(
      textSpan,
      onSelectionChanged: (selection, cause) {
        textWidgetSelection = selection;
        textGestureDetectorWithMenu.isQuoteSelected = true;
      },
      contextMenuBuilder: null,
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
    return textGestureDetectorWithMenu;
  }
}
