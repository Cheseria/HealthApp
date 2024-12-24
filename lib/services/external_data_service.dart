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
}
