import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tflite/tflite.dart';
import 'package:healthapp/services/symptom_message.dart';
import 'package:healthapp/services/symptoms_list.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

import 'package:url_launcher/url_launcher.dart'; // For launching URLs in a browser

class UserCheckSymptoms extends StatefulWidget {
  @override
  UserCheckSymptomsState createState() => UserCheckSymptomsState();
}

class UserCheckSymptomsState extends State<UserCheckSymptoms> {
  List<SymptomMessage> messages = [
    SymptomMessage(
      text: "Welcome! Please select a category of symptoms.",
      options: symptoms.map((category) => category.name).toList() + ["None"],
      isUser: false,
    ),
  ];

  String? selectedCategory; // Track the currently selected category
  List<String> selectedSymptoms = []; // Track selected symptoms

  @override
  void initState() {
    super.initState();
    loadModel();
  }

  Future<void> loadModel() async {
    String? res = await Tflite.loadModel(
      model: "assets/tflite/your_model.tflite",
    );
    print(res); // Optional: check if the model loads successfully
  }

  @override
  void dispose() {
    Tflite.close(); // Dispose model when not needed to free resources
    super.dispose();
  }

  void onOptionSelected(String option) {
    setState(() {
      if (selectedCategory == null) {
        handleCategorySelection(option);
      } else if (option == "Back") {
        handleBackOption();
      } else if (option == "Submit") {
        handleCompletion();
      } else {
        handleSymptomSelection(option);
      }
    });
  }

  void handleCategorySelection(String option) {
    if (option == "None") {
      if (selectedSymptoms.isEmpty) {
        messages.add(SymptomMessage(
          text: "No symptoms provided. Thank you!",
          isUser: true,
        ));
      } else {
        handleCompletion();
      }
    } else {
      selectedCategory = option;
      final category = symptoms.firstWhere((cat) => cat.name == option);

      messages.add(SymptomMessage(text: option, isUser: true));
      messages.add(SymptomMessage(
        text: "Here are the symptoms under $option. Select one:",
        options: [...category.subSymptoms!, "Back", "Submit"],
        isUser: false,
      ));
    }
  }

  void handleBackOption() {
    selectedCategory = null;
    messages.add(SymptomMessage(text: "Back to categories.", isUser: true));
    messages.add(SymptomMessage(
        text: "Please select a category of symptoms.",
        options:
            symptoms.map((category) => category.name).toList() + ["Submit"],
        isUser: false));
  }

  void handleCompletion() {
    messages.add(SymptomMessage(
      text: "Thank you for sharing your symptoms!",
      isUser: false,
    ));
    diagnoseSymptoms();
  }

  void handleSymptomSelection(String option) {
    if (!selectedSymptoms.contains(option)) {
      messages.add(SymptomMessage(text: option, isUser: true));
      selectedSymptoms.add(option);
    } else {
      messages.add(SymptomMessage(
        text:
            "You have already selected $option. Please choose another symptom.",
        isUser: false,
      ));
    }

    if (getRemainingSymptoms().isNotEmpty) {
      messages.add(SymptomMessage(
        text: "Any other symptoms?",
        options: [...getRemainingSymptoms(), "Back", "Submit"],
        isUser: false,
      ));
    } else {
      messages.add(SymptomMessage(
        text:
            "No more symptoms available in this category. You can go back or complete the selection.",
        options: ["Back", "Submit"],
        isUser: false,
      ));
    }
  }

  List<String> getRemainingSymptoms() {
    final category = symptoms.firstWhere((cat) => cat.name == selectedCategory);
    return category.subSymptoms!
        .where((symptom) => !selectedSymptoms.contains(symptom))
        .toList();
  }

  Future<void> diagnoseSymptoms() async {
    try {
      List<String> featureNames = await loadFeatureNames();
      List<String> diseaseLabels = await loadDiseaseLabels();
      Map<String, dynamic> icdMapping = await loadICD10Mapping();

      List<double> inputFeatures =
          convertSymptomsToFeatures(selectedSymptoms, featureNames);
      Float32List inputAsFloat32List = Float32List.fromList(inputFeatures);

      final interpreter =
          await Interpreter.fromAsset('assets/tflite/model.tflite');
      var input = [inputAsFloat32List];
      var output = List.filled(1 * diseaseLabels.length, 0.0)
          .reshape([1, diseaseLabels.length]);

      interpreter.run(input, output);

      List<double> probabilities = output[0];
      List<int> topIndices =
          List.generate(probabilities.length, (index) => index);
      topIndices.sort((a, b) => probabilities[b].compareTo(probabilities[a]));
      List<int> top3Indices = topIndices.sublist(0, 3);

      String result = "Top Predictions:\n";
      String diseaseName = "";
      for (int i = 0; i < top3Indices.length; i++) {
        int index = top3Indices[i];
        diseaseName = diseaseLabels[index];
        double confidence = probabilities[index] * 100;
        result +=
            "${i + 1}. ${diseaseName} - ${confidence.toStringAsFixed(2)}%\n";

        if (i == 0) {
          await getTreatmentInfo(diseaseName, icdMapping[diseaseName]);
        }
      }

      setState(() {
        messages.add(SymptomMessage(
          text: result,
          isUser: false,
        ));
      });
    } catch (e) {
      print("Error while running model: $e");
    }
  }

  Future<void> getTreatmentInfo(String diseaseName, String? icdCode) async {
    // Call showTreatmentInfo() with the disease name
    try {
      showTreatmentInfo(diseaseName);
    } catch (e) {
      setState(() {
        messages.add(SymptomMessage(
          text: "Error while fetching treatment information: $e",
          isUser: false,
        ));
      });
    }
  }

  void showTreatmentInfo(String diseaseName) {
    // Generate the MedlinePlus URL using the provided disease name
    String generateMedlinePlusUrl(String diseaseName) {
      String encodedDiseaseName = Uri.encodeQueryComponent(diseaseName);
      return Uri.https(
        'vsearch.nlm.nih.gov',
        '/vivisimo/cgi-bin/query-meta',
        {
          'v:project': 'medlineplus',
          'v:sources': 'medlineplus-bundle',
          'query': encodedDiseaseName.replaceAll(
              '+', '%20'), // Ensure spaces are encoded as '%20'
        },
      ).toString();
    }

    // Generate the URL
    String link = generateMedlinePlusUrl(diseaseName);

    // Update the UI with the clickable link to open the treatment information
    setState(() {
      messages.add(SymptomMessage(
        richText: RichText(
          text: TextSpan(
            text: "Learn more about $diseaseName",
            style: TextStyle(
                color: Colors.blue, decoration: TextDecoration.underline),
            recognizer: TapGestureRecognizer()
              ..onTap = () async {
                final Uri url = Uri.parse(link);
                print("Attempting to launch URL: $url");
                if (await canLaunchUrl(url)) {
                  await launchUrl(
                    url,
                    mode: LaunchMode.externalApplication,
                  );
                } else {
                  print("Could not launch $url");
                }
              },
          ),
        ),
        isUser: false,
      ));
    });
  }

  Future<List<String>> loadFeatureNames() async {
    final String csvString =
        await rootBundle.loadString('assets/tflite/feature_name.csv');
    List<String> featureNames =
        csvString.split('\n').map((e) => e.trim()).toList();
    // Remove any empty entries caused by trailing new lines
    featureNames.removeWhere((element) => element.isEmpty);
    return featureNames;
  }

  List<double> convertSymptomsToFeatures(
      List<String> selectedSymptoms, List<String> featureNames) {
    // Preprocess the user-provided symptom names to match training feature names
    List<String> processedSymptoms = selectedSymptoms.map((symptom) {
      return symptom
          .toLowerCase()
          .replaceAll(' ', '_')
          .replaceAll(RegExp(r'[^\w]'), '');
    }).toList();

    // Initialize a list of zeros with length equal to the number of features
    List<double> featureVector = List.filled(featureNames.length, 0.0);

    // Set the value to 1.0 for each symptom that the user has selected
    for (String symptom in processedSymptoms) {
      int index = featureNames.indexOf(symptom);
      if (index != -1) {
        featureVector[index] = 1.0;
      }
    }

    return featureVector;
  }

  Future<List<String>> loadDiseaseLabels() async {
    final String csvString =
        await rootBundle.loadString('assets/tflite/disease_labels.csv');
    List<String> diseaseLabels =
        csvString.split('\n').map((e) => e.trim()).toList();
    // Remove any empty entries caused by trailing new lines
    diseaseLabels.removeWhere((element) => element.isEmpty);
    return diseaseLabels;
  }

  Future<Map<String, dynamic>> loadICD10Mapping() async {
    String jsonString =
        await rootBundle.loadString('assets/tflite/icd10_mapping.json');
    return json.decode(jsonString);
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
                        if (message.richText != null)
                          message.richText!
                        else if (message.text != null)
                          Text(message.text!),
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
