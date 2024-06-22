import 'package:flutter/material.dart';
import 'package:todochat/ui_components/confirm_detele_dlg.dart';

class TileMenu {
  static Future<void> show({
    required BuildContext context,
    required Offset position,
    selectedText = "",
    onCopy,
    onEdit,
    onReply,
    onDelete,
    onQuoteSelection,
    List<PopupMenuEntry>? addMenuItems,
  }) async {
    List<PopupMenuEntry> items = [];
    items = [
      if (onCopy != null)
        PopupMenuItem(
            child: const Text('Copy'),
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
            onTap: () {
              if (onReply != null) {
                onReply!();
              }
            }),
      if (onDelete != null)
        PopupMenuItem<String>(
          child: const Text('Delete'),
          onTap: () async {
            final res = await ConfirmDeleteDlg.show(context);
            if (res ?? false) {
              if (onDelete != null) {
                onDelete!();
              }
            }
          },
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

    if (addMenuItems != null) {
      items = [...items, ...addMenuItems];
    }
    if (items.isEmpty) return;

    showMenu(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(
        Radius.circular(10.0),
      )),
      color: Colors.white,
      surfaceTintColor: Colors.white,
      popUpAnimationStyle: AnimationStyle.noAnimation,
      context: context,
      position: RelativeRect.fromLTRB(
          position.dx, position.dy, position.dx, position.dy),
      items: items,
    );
    // if (res == "Delete") {
    //   var res = await ConfirmDeleteDlg.show(context);
    //   if (res ?? false) {
    //     if (onDelete != null) {
    //       onDelete!();
    //     }
    //   }
    // }
  }
}
