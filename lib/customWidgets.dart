import 'package:flutter/material.dart';
import 'package:flutter/src/foundation/diagnostics.dart';

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
    bool obscureText = false}) {
  return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextFormField(
        decoration: InputDecoration(
          labelText: labelText,
          hintText: hintText,
          border: const OutlineInputBorder(),
          suffixIcon: IconButton(
            onPressed: () {
              controller?.clear();
              if (onCleared != null) onCleared();
            },
            icon: Icon(Icons.clear),
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
