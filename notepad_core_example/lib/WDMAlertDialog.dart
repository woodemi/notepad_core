import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

double get ScreenWidth => window.physicalSize.width / window.devicePixelRatio;
double get ScreenHeight => window.physicalSize.height / window.devicePixelRatio;
double get LineThickness => 1;

final ThemeColor = Color(0xFF2172FD);
final CancelColor = Color(0xFFefefef);
final ConfirmColor = Color(0xFF2172FD);
final DividerColor = Color(0xffd9d9d9);

typedef StringCallback = void Function(String);

enum Operation { NOTICE, EDIT }

class WDMAlertDialog extends Dialog {
  final String title;
  final String message;

  final double msgFontSize;

  final Operation type;

  final bool isLandscape;

  final String cancelText;
  final String confirmText;

  final bool isNeedCancel;

  final TextAlign textAlign;

  final VoidCallback cancel;
  final StringCallback confirm;

  final alertDialogHeight = 265.0;

  final TextEditingController textEditingController;

  final List<TextInputFormatter> inputFormatters;

  WDMAlertDialog({
    Key key,
    this.title = '',
    this.message = '',
    this.msgFontSize = 13,
    this.isLandscape = false,
    this.isNeedCancel = true,
    this.cancelText = '',
    this.confirmText = '',
    this.type = Operation.NOTICE,
    this.textEditingController,
    this.textAlign = TextAlign.center,
    this.cancel,
    this.confirm,
    this.inputFormatters,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final padding =
        (MediaQuery.of(context).size.height - alertDialogHeight) / 2;
    return Padding(
      padding: EdgeInsets.only(
          left: ScreenWidth * (isLandscape ? 0.3 : 0.1),
          right: ScreenWidth * (isLandscape ? 0.3 : 0.1),
          top: padding - 35,
          bottom: padding + 35),
      child: Material(
        type: MaterialType.transparency,
        child: Stack(
          children: <Widget>[
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _renderContent(context),
            ),
            Container(
              margin: EdgeInsets.only(top: 5, left: 30, right: 30),
            )
          ],
        ),
      ),
    );
  }

  Widget _renderContent(BuildContext context) {
    if (textEditingController != null) {
      var textSelection = TextSelection(baseOffset: 0, extentOffset: textEditingController.text.length);
      textEditingController.selection = textSelection;
    }

    return Container(
      height: alertDialogHeight - 75,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(18)),
      ),
      padding: EdgeInsets.only(bottom: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          WDMText(text: title, isBold: true, color: Colors.black, fontSize: 18),
          type == Operation.NOTICE
              ? WDMText(
                  text: message,
                  isBold: false,
                  color: Colors.black87,
                  textAlign: textAlign,
                  fontSize: msgFontSize,
                  maxLines: 3,
                  top: message.isEmpty ? 0 : 23,
                  left: 50,
                  right: 50,
                  bottom: 30,
                )
              : WDMTextField(
                  margin: EdgeInsets.only(top: 18, bottom: 25),
                  controller: textEditingController,
                  radius: 12,
                  inputFormatters: inputFormatters,
                ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              if (isNeedCancel)
                Spacer(
                  flex: 1,
                ),
              if (isNeedCancel)
                Expanded(
                  flex: 3,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      if (cancel != null) cancel();
                    },
                    child: Container(
                      height: 35,
                      decoration: BoxDecoration(
                        color: CancelColor,
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                      child: Center(
                        child: WDMText(
                          text: cancelText.length > 0
                              ? cancelText
                              : "Cancel",
                          isBold: true,
                          fontSize: 15,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ),
              Spacer(
                flex: 1,
              ),
              Expanded(
                flex: isNeedCancel ? 3 : 1,
                child: GestureDetector(
                  onTap: () {
                    if (confirm != null) {
                      if (textEditingController != null) {
                        if (textEditingController.text.length > 0) {
                          Navigator.pop(context);
                        }
                      } else {
                        Navigator.pop(context);
                      }
                      confirm(textEditingController?.text);
                    } else {
                      Navigator.pop(context);
                    }
                  },
                  child: Container(
                    height: 35,
                    decoration: BoxDecoration(
                      color: ConfirmColor,
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                    child: Center(
                      child: WDMText(
                        text: confirmText.length > 0
                            ? confirmText
                            : "OK",
                        isBold: true,
                        fontSize: 15,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              Spacer(
                flex: 1,
              )
            ],
          )
        ],
      ),
    );
  }
}

//  TextField
Widget WDMTextField(
    {String text,
      TextEditingController controller,
      double width = 230,
      double height = 45,
      EdgeInsetsGeometry margin,
      double radius = 19,
      List<TextInputFormatter> inputFormatters,
      onFieldSubmitted(String value)}) {
  return Container(
    width: width,
    height: height,
    alignment: Alignment.center,
    padding: EdgeInsets.only(top: 0, left: 10, right: 9, bottom: 10),
    margin: margin == null ? EdgeInsets.only(top: 30) : margin,
    decoration: BoxDecoration(
        border: Border.all(color: DividerColor, width: LineThickness),
        borderRadius: BorderRadius.circular(radius)),
    child: Material(
      color: Colors.transparent,
      child: TextFormField(
        enabled: true,
        textAlign: TextAlign.center,
        cursorColor: ThemeColor,
        textInputAction: TextInputAction.done,
        onFieldSubmitted: onFieldSubmitted,
        controller: controller,
        autofocus: true,
        inputFormatters: inputFormatters,
        decoration: InputDecoration(
            contentPadding: EdgeInsets.only(top: 0, bottom: 0),
            border: InputBorder.none
        ),
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: Colors.black,
        ),
      ),
    ),
  );
}

//  Text
Widget WDMText(
    {String text,
      double fontSize = 18,
      Color color = Colors.black87,
      Color backgroundColor = Colors.transparent,
      TextAlign textAlign = TextAlign.start,
      int maxLines,
      double width,
      double height,
      double left = 0,
      double top = 0,
      double right = 0,
      double bottom = 0,
      TextOverflow overflow,
      bool isBold = false}) {
  return Container(
    width: width,
    height: height,
    color: backgroundColor,
    margin: EdgeInsets.only(left: left, top: top, right: right, bottom: bottom),
    child: Text(text,
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: overflow ?? TextOverflow.ellipsis,
        style: TextStyle(
            color: color,
            fontSize: fontSize,
            decoration: TextDecoration.none,
            fontWeight: isBold ? FontWeight.w600 : FontWeight.w400)),
  );
}