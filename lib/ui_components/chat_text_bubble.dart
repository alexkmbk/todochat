import 'package:flutter/material.dart';
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
  final Map<String, String>? HTTPHeaders;
  final Widget? leading;

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
      this.HTTPHeaders,
      this.onEdit,
      this.leading});

  @override
  State<ChatTextBubble> createState() => _ChatTextBubbleState();
}

class _ChatTextBubbleState extends State<ChatTextBubble> {
  bool editMode = false;
  final FocusNode focusNode = FocusNode();
  String selectedText = "";

  // TextSelection textWidgetSelection =
  //     const TextSelection(baseOffset: 0, extentOffset: 0);
  // late GestureDetectorWithMenu textGestureDetectorWithMenu;

  _ChatTextBubbleState() {
    focusNode.addListener(() {
      if (!focusNode.hasFocus) ContextMenuController.removeAny();
    });
  }
  @override
  Widget build(BuildContext context) {
    final textWidget = Text(
      widget.text,
    );

    return SelectionArea(
      focusNode: focusNode,
      onSelectionChanged: (value) {
        if (value != null)
          selectedText = value.plainText;
        else
          selectedText = "";
      },
      contextMenuBuilder: (context, selectableRegionState) {
        return TileMenu(
          selectedText: selectedText,
          addMenuItems: selectableRegionState.contextMenuButtonItems,
          selectableRegionState: selectableRegionState,
          onQuoteSelection:
              selectedText.isNotEmpty ? widget.onQuoteSelection : null,
          onDelete: widget.onDelete,
          onEdit: widget.onEdit,
          onCopy: widget.onCopy,
          onReply: widget.onReply,
        );
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
            if (widget.leading != null) widget.leading!,
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
                    headers: widget.HTTPHeaders,
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
  }
}
