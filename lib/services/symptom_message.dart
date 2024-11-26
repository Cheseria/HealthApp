class SymptomMessage {
  final String text;
  final bool isUser;
  final List<String>? options; // Options to present to the user (if any)

  SymptomMessage({
    required this.text,
    this.isUser = false,
    this.options,
  });
}
