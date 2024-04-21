import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:todochat/customWidgets.dart';
import 'package:todochat/ui_components/confirm_detele_dlg.dart';

class CachedNetworkImageWithMenu extends StatefulWidget {
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

  const CachedNetworkImageWithMenu(this.src,
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
  State<CachedNetworkImageWithMenu> createState() =>
      _CachedNetworkImageWithMenuState();
}

class _CachedNetworkImageWithMenuState
    extends State<CachedNetworkImageWithMenu> {
  TapDownDetails? _tapDownDetails;

  void onSecondaryTapDown(TapDownDetails details, BuildContext context) async {
    final x = details.globalPosition.dx;
    final y = details.globalPosition.dy;
    final res = await showMenu(
      popUpAnimationStyle: AnimationStyle.noAnimation,
      color: Colors.white,
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
              child: CachedNetworkImage(
                fadeOutDuration: const Duration(milliseconds: 0),
                fadeInDuration: const Duration(milliseconds: 0),
                imageUrl: widget.src,
                height: widget.height,
                httpHeaders: widget.headers,
                errorWidget: (context, url, error) {
                  return Image.asset(
                    'assets/images/image_error.png',
                    height: widget.height ?? 200,
                    width: widget.width,
                  );
                },
                placeholder: (context, url) {
                  return SizedBox(
                      width: widget.width,
                      height: widget.height,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8.0),
                        // child: widget.previewImageData != null
                        //     ? Image.memory(
                        //         widget.previewImageData!,
                        //         width: widget.width,
                        //         height: widget.height,
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
        height: widget.height ?? 200,
        width: widget.width,
      );
    }
  }
}
