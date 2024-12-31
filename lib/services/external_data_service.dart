import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class ExternalDataService {
  /// Fetch weather data using Open-Meteo API
  static Future<Map<String, double>> fetchWeatherData(
      double latitude, double longitude) async {
    try {
      // Construct the API URL
      final Uri url = Uri.parse(
        'https://api.open-meteo.com/v1/forecast?latitude=$latitude&longitude=$longitude&current_weather=true',
      );

      // Make the HTTP GET request
      final response = await http.get(url);

      if (response.statusCode == 200) {
        // Parse the JSON response
        final data = json.decode(response.body);

        // Extract fields safely
        final currentWeather = data['current_weather'];
        if (currentWeather == null) {
          throw Exception("Weather data is missing from the API response");
        }

        // Safely retrieve temperature and humidity
        double? temperature = currentWeather['temperature']?.toDouble();
        double? humidity = currentWeather['relative_humidity']?.toDouble();

        // Ensure both are non-null, fallback to default values if necessary
        return {
          'temperature': temperature ?? 25.0, // Default to 25°C if missing
          'humidity': humidity ?? 50.0, // Default to 50% if missing
        };
      } else {
        throw Exception(
            'Failed to fetch weather data: ${response.reasonPhrase}');
      }
    } catch (e) {
      print("Error fetching weather data: $e");
      // Return default values in case of an error
      return {
        'temperature': 25.0, // Default temperature
        'humidity': 50.0, // Default humidity
      };
    }
  }

  /// Mock function to fetch user activity data (can be replaced with Firebase or other APIs)
  static Future<Map<String, int>> fetchUserActivityData() async {
    try {
      // Replace with actual Firebase or API integration for steps and heart rate
      return {
        'stepsIn15Mins': 400, // Mock data
        'heartRate': 80, // Mock data
      };
    } catch (e) {
      print("Error fetching user activity data: $e");
      return {
        'stepsIn15Mins': 0,
        'heartRate': 70,
      };
    }
  }

  /// Fetch and calculate user age based on the DOB stored in Firestore
  static Future<int> fetchUserAge() async {
    try {
      // Get the current user ID
      String userId = FirebaseAuth.instance.currentUser?.uid ?? "";

      if (userId.isEmpty) {
        throw Exception("User is not logged in.");
      }

      // Fetch user document from Firestore
      DocumentSnapshot<Map<String, dynamic>> userDoc = await FirebaseFirestore
          .instance
          .collection('users')
          .doc(userId)
          .get();

      // Retrieve the 'dob' field
      if (userDoc.exists && userDoc.data() != null) {
        Timestamp? dobTimestamp = userDoc.data()?['dob'];
        if (dobTimestamp == null) {
          throw Exception("DOB field is missing in the user document.");
        }

        // Convert Timestamp to DateTime
        DateTime birthDate = dobTimestamp.toDate();

        // Calculate age
        int age = _calculateAge(birthDate);
        print("User age: $age");
        return age;
      } else {
        throw Exception("User document does not exist or is invalid.");
      }
    } catch (e) {
      print("Error fetching user age: $e");
      return 0; // Default age if fetching fails
    }
  }

  /// Helper function to calculate age from birthDate
  static int _calculateAge(DateTime birthDate) {
    DateTime today = DateTime.now();
    int age = today.year - birthDate.year;
    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  /// Calculate and fetch health tips based on fetched data
  static Future<Map<String, String>> fetchHealthTips(
      double latitude, double longitude) async {
    try {
      // Fetch weather data
      Map<String, double> weatherData =
          await fetchWeatherData(latitude, longitude);

      // Fetch user activity data
      Map<String, int> activityData = await fetchUserActivityData();

      // Fetch user age (if needed for tips, not used in this example)
      int userAge = await fetchUserAge();

      // Assign tips based on fetched data
      return getTips(
        temperature: weatherData['temperature']!,
        humidity: weatherData['humidity']!,
        heartRate: activityData['heartRate']!.toDouble(),
        sleepMinutes:
            420.0, // Placeholder for sleep data (replace with actual value)
        hydrationLevel:
            65.0, // Placeholder for hydration level (replace with actual value)
        stepCounter: activityData['stepsIn15Mins']!,
      );
    } catch (e) {
      print("Error fetching health tips: $e");
      return {};
    }
  }

  /// Traditional logic to generate tips based on input
  static Map<String, String> getTips({
    required double temperature,
    required double humidity,
    required double heartRate,
    required double sleepMinutes,
    required double hydrationLevel,
    required int stepCounter,
  }) {
    Map<String, String> tips = {};

    // Temperature Tip
    if (temperature < 15) {
      tips['Temperature_Tip'] = "Keep warm, the temperature is low today.";
    } else if (temperature >= 15 && temperature <= 30) {
      tips['Temperature_Tip'] =
          "The temperature is pleasant for outdoor activities.";
    } else {
      tips['Temperature_Tip'] = "It's hot outside. Stay cool and hydrated.";
    }

    // Humidity Tip
    if (humidity < 30) {
      tips['Humidity_Tip'] = "The air is dry. Consider using a humidifier.";
    } else if (humidity >= 30 && humidity <= 60) {
      tips['Humidity_Tip'] =
          "Humidity is at a comfortable level. Enjoy your day!";
    } else {
      tips['Humidity_Tip'] = "High humidity levels. Stay cool and take breaks.";
    }

    // Heart Rate Tip
    if (heartRate == 0) {
      tips['Heart_Rate_Tip'] =
          "How's your heart rate? Share your latest measurement with me.";
    } else if (heartRate < 60) {
      tips['Heart_Rate_Tip'] =
          "Your heart rate is low. Consider consulting a doctor.";
    } else if (heartRate >= 60 && heartRate <= 100) {
      tips['Heart_Rate_Tip'] =
          "Your heart rate is normal. Keep up the healthy lifestyle.";
    } else {
      tips['Heart_Rate_Tip'] =
          "Your heart rate is high. Avoid heavy activities and relax.";
    }

    // Sleep Tip
    if (sleepMinutes == 0) {
      tips['Sleep_Tip'] =
          "How's your sleep last night? Let me know how long you slept.";
    } else if (sleepMinutes < 360) {
      tips['Sleep_Tip'] = "Ensure you get enough sleep for better health.";
    } else {
      tips['Sleep_Tip'] =
          "Your sleep duration is adequate. Keep maintaining it.";
    }

    // Hydration Tip
    if (hydrationLevel < 25) {
      tips['Hydration_Tip'] = "Severely dehydrated. Drink water immediately!";
    } else if (hydrationLevel >= 25 && hydrationLevel < 50) {
      tips['Hydration_Tip'] = "Mild dehydration. Increase water intake soon.";
    } else if (hydrationLevel >= 50 && hydrationLevel < 75) {
      tips['Hydration_Tip'] = "Hydration level moderate. Keep drinking water.";
    } else {
      tips['Hydration_Tip'] = "Well-hydrated. Maintain your water intake!";
    }

    // Steps Tip
    if (stepCounter < 5000) {
      tips['Steps_Tip'] = "Try to increase your activity level.";
    } else if (stepCounter < 15000) {
      tips['Steps_Tip'] = "Good job staying active!";
    } else {
      tips['Steps_Tip'] = "Great job on the steps today, keep it up!";
    }

    return tips;
  }
}
