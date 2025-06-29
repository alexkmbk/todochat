import 'package:flutter/material.dart';
import 'package:todochat/ui_components/confirm_detele_dlg.dart';

class SelectionAreaTileMenu extends StatelessWidget {
  final SelectableRegionState selectableRegionState;
  GestureTapCallback? onTap;
  //final GestureTapDownCallback? onSecondaryTapDown;
  Function? onCopy;
  Function? onEdit;
  Function? onReply;
  Function? onDelete;
  Function(String)? onQuoteSelection;
  List<ContextMenuButtonItem>? addMenuItems;
  List<ContextMenuButtonItem> items = [];
  String selectedText;

  SelectionAreaTileMenu(
      {this.selectedText = "",
      this.onCopy,
      this.onEdit,
      this.onTap,
      this.onReply,
      this.onDelete,
      this.onQuoteSelection,
      this.addMenuItems,
      Key? key,
      required this.selectableRegionState});

  Future<void> show(BuildContext context, Offset position) async {
    List<PopupMenuEntry> items = [];
    items = [
      if (onCopy != null)
        PopupMenuItem(
            child: Text('Copy'),
            onTap: () async {
              if (onCopy != null) {
                onCopy!();
              }
            }),
      if (onEdit != null)
        PopupMenuItem<String>(
            child: const Text('Edit'),
            onTap: () async {
              if (onEdit != null) {
                onEdit!();
              }
            }),
      if (onReply != null)
        PopupMenuItem<String>(
            child: const Text('Reply'),
            onTap: () async {
              if (onReply != null) {
                onReply!();
              }
            }),
      if (onDelete != null)
        const PopupMenuItem<String>(
          value: 'Delete',
          child: Text('Delete'),
        ),
      if (onQuoteSelection != null)
        PopupMenuItem<String>(
            child: const Text('Quote selection'),
            onTap: () async {
              if (onQuoteSelection != null) {
                onQuoteSelection!(selectedText);
              }
            }),
    ];

    if (items.isEmpty) return;

    final res = await showMenu(
      color: Colors.white,
      popUpAnimationStyle: AnimationStyle.noAnimation,
      context: context,
      position: RelativeRect.fromLTRB(
          position.dx, position.dy, position.dx, position.dy),
      items: items,
    );
    if (res == "Delete") {
      var res = await ConfirmDeleteDlg.show(context);
      if (res ?? false) {
        if (onDelete != null) {
          onDelete!();
        }
      }
    }
    return;
  }

  @override
  Widget build(BuildContext context) {
    items = [
      if (onCopy != null &&
          (addMenuItems == null ||
              addMenuItems!.indexWhere(
                      (element) => element.type == ContextMenuButtonType.copy) <
                  0))
        ContextMenuButtonItem(
            type: ContextMenuButtonType.copy,
            label: 'Copy',
            onPressed: () {
              ContextMenuController.removeAny();
              if (onCopy != null) {
                onCopy!();
              }
            }),
      if (onEdit != null)
        ContextMenuButtonItem(
            label: 'Edit',
            onPressed: () async {
              ContextMenuController.removeAny();
              if (onEdit != null) {
                onEdit!();
              }
            }),
      if (onReply != null)
        ContextMenuButtonItem(
            label: 'Reply',
            onPressed: () async {
              ContextMenuController.removeAny();
              if (onReply != null) {
                onReply!();
              }
            }),
      if (onDelete != null)
        ContextMenuButtonItem(
          label: 'Delete',
          onPressed: () async {
            ContextMenuController.removeAny();
            var res = await ConfirmDeleteDlg.show(context);
            if (res ?? false) {
              if (onDelete != null) {
                onDelete!();
              }
            }

            if (onDelete != null) {
              onDelete!();
            }
          },
        ),
      if (onQuoteSelection != null)
        ContextMenuButtonItem(
            label: 'Quote selection',
            onPressed: () async {
              ContextMenuController.removeAny();
              if (onQuoteSelection != null) {
                onQuoteSelection!(selectedText);
              }
            }),
    ];
    if (addMenuItems != null) {
      items = [...items, ...addMenuItems!];
    }

    return AdaptiveTextSelectionToolbar.buttonItems(
      anchors: selectableRegionState.contextMenuAnchors,
      buttonItems: items,
    );
  }
}
