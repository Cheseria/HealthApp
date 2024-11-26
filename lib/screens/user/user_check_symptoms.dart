import 'package:flutter/material.dart';
import 'package:healthapp/services/symptom_message.dart';

class UserCheckSymptoms extends StatefulWidget {
  @override
  UserCheckSymptomsState createState() => UserCheckSymptomsState();
}

class UserCheckSymptomsState extends State<UserCheckSymptoms> {
  List<SymptomMessage> messages = [
    SymptomMessage(
      text: "Welcome! What symptoms are you experiencing?",
      options: [
        "Fatigue",
        "Fever",
        "Headache",
        "Cough",
        "Other",
      ],
    ),
  ];

  void onOptionSelected(String option) {
    setState(() {
      // Add user's choice to the chat
      messages.add(SymptomMessage(text: option, isUser: true));

      // Add the next question or response
      if (option == "Other") {
        messages.add(SymptomMessage(
          text: "Please describe your symptoms.",
        ));
      } else {
        messages.add(SymptomMessage(
          text: "Got it! Are you experiencing any of these?",
          options: ["Dizziness", "Nausea", "Chest Pain", "None"],
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
