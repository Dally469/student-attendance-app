import 'package:another_flushbar/flushbar.dart';
import 'package:attendance/utils/colors.dart';
import 'package:flutter/material.dart';

void showErrorAlert(String message, context) {
  Flushbar(
    title: "Error",
    message: message,
    icon: const Icon(
      Icons.info_outline,
      size: 28.0,
      color: Colors.white,
    ),
    duration: const Duration(seconds: 40),
    margin: const EdgeInsets.all(30),
    borderRadius: BorderRadius.circular(10),
    flushbarPosition: FlushbarPosition.TOP,
    flushbarStyle: FlushbarStyle.FLOATING,
    reverseAnimationCurve: Curves.elasticInOut,
    forwardAnimationCurve: Curves.elasticInOut,
    backgroundColor: orangeColor,
  ).show(context);
}

void showSuccessAlert(String message, context) {
  Flushbar(
    title: "Success",
    message: message,
    icon: const Icon(
      Icons.thumb_up,
      size: 28.0,
      color: Colors.white,
    ),
    duration: const Duration(seconds: 4),
    margin: const EdgeInsets.all(30),
    borderRadius: BorderRadius.circular(10),
    flushbarPosition: FlushbarPosition.TOP,
    flushbarStyle: FlushbarStyle.FLOATING,
    reverseAnimationCurve: Curves.elasticInOut,
    forwardAnimationCurve: Curves.elasticInOut,
    backgroundColor: greenColor,
  ).show(context);
}


