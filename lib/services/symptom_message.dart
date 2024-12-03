import 'package:flutter/material.dart';

class SymptomMessage {
  final String? text;
  final RichText? richText;
  final bool isUser;
  final List<String>? options;

  SymptomMessage(
      {this.text, this.richText, required this.isUser, this.options});
}
