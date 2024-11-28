import 'package:flutter/material.dart';
import 'package:healthapp/services/symptom_message.dart';
import 'package:healthapp/services/symptoms_list.dart';

class UserCheckSymptoms extends StatefulWidget {
  @override
  UserCheckSymptomsState createState() => UserCheckSymptomsState();
}

class UserCheckSymptomsState extends State<UserCheckSymptoms> {
  List<SymptomMessage> messages = [
    SymptomMessage(
      text: "Welcome! Please select a category of symptoms.",
      options: symptoms.map((category) => category.name).toList(),
    ),
  ];

  void onOptionSelected(String option) {
    setState(() {
      // Add user's choice to the chat
      messages.add(SymptomMessage(text: option, isUser: true));

      // Check if the selected option matches a category name
      final selectedCategory = symptoms.firstWhere(
          (category) => category.name == option,
          orElse: () => Symptom("", []));

      if (selectedCategory.subSymptoms != null &&
          selectedCategory.subSymptoms!.isNotEmpty) {
        // Add the list of symptoms for the selected category
        messages.add(SymptomMessage(
          text: "Here are the symptoms under $option. Select one:",
          options: selectedCategory.subSymptoms,
        ));
      } else {
        // If no matching category or no symptoms found
        messages.add(SymptomMessage(
          text: "Please describe your symptoms or select another category.",
        ));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Symptom Checker"),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                return Align(
                  alignment: message.isUser
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color:
                          message.isUser ? Colors.blue[100] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(message.text),
                        if (message.options != null)
                          ...message.options!.map((option) {
                            return TextButton(
                              onPressed: () => onOptionSelected(option),
                              child: Text(option),
                            );
                          }),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
