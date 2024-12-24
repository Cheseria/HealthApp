import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:healthapp/services/message.dart';

class ChatServices {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<List<Map<String, dynamic>>> getUsersStream() {
    return FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'doctor') // Query only doctors
        .snapshots() // Listen for real-time updates
        .map((querySnapshot) => querySnapshot.docs
            .map((doc) => doc.data() as Map<String, dynamic>)
            .toList());
  }

  Future<void> sendMessage(String receiverID, String receiverRole,
      String message, String receiverName) async {
    final String currentUserID = _auth.currentUser!.uid;
    final String currentUserEmail = _auth.currentUser!.email!;
    final Timestamp timestamp = Timestamp.now();

    try {
      // Fetch current user's role and username dynamically from Firestore
      DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserID)
          .get();

      if (!userSnapshot.exists) {
        throw Exception("User data not found!");
      }

      // Cast the data to Map<String, dynamic>
      Map<String, dynamic> userData =
          userSnapshot.data() as Map<String, dynamic>;

      // Extract current user's role and username
      final String currentUserRole =
          userData['role'] ?? 'user'; // Default to 'user' if not found
      final String currentUserName = userData['full_name'] ??
          'Unknown'; // Default to 'Unknown' if not found

      // Create a new message
      Message newMessage = Message(
        senderID: currentUserID,
        senderEmail: currentUserEmail,
        receiverID: receiverID,
        message: message,
        timestamp: timestamp,
      );

      // Construct chat room ID
      List<String> ids = [currentUserID, receiverID];
      ids.sort();
      String chatRoomID = ids.join('_');

      // Reference to chat room
      final chatRoomRef = _firestore.collection("chat_rooms").doc(chatRoomID);

      // Ensure the chatroom exists or update it with new data
      await chatRoomRef.set({
        "participants": ids,
        "participant_roles": {
          currentUserID: currentUserRole,
          receiverID: receiverRole,
        },
        "participant_names": {
          currentUserID: currentUserName,
          receiverID: receiverName,
        },
        "lastMessage": message,
        "timestamp": timestamp,
      }, SetOptions(merge: true));

      // Add the new message to the messages sub-collection
      await chatRoomRef.collection("messages").add(newMessage.toMap());
    } catch (error) {
      throw Exception("Failed to send message: $error");
    }
  }

  //get messages
  Stream<QuerySnapshot> getMessages(String userID, otherUserID) {
    //construct a chatroom ID for the two users
    List<String> ids = [userID, otherUserID];
    ids.sort();
    String chatRoomID = ids.join('_');

    return _firestore
        .collection("chat_rooms")
        .doc(chatRoomID)
        .collection("messages")
        .orderBy("timestamp", descending: false)
        .snapshots();
  }

  Stream<List<Map<String, dynamic>>> getDoctorChatroomsStream() {
    final String currentDoctorID = _auth.currentUser!.uid;

    return _firestore
        .collection('chat_rooms')
        .where('participants', arrayContains: currentDoctorID)
        .where('participant_roles.$currentDoctorID', isEqualTo: 'doctor')
        .snapshots()
        .map((querySnapshot) => querySnapshot.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final participants = data['participants'] as List<dynamic>;
              final participantID = participants.firstWhere(
                  (id) => id != currentDoctorID,
                  orElse: () => null);
              final participantName =
                  data['participant_names']?[participantID] ?? "Unknown";
              return {
                'participant_id': participantID,
                'participant_name': participantName,
                ...data
              };
            }).toList());
  }

  Stream<List<Map<String, dynamic>>> getUserChatroomsStream() {
    final String currentUserID = _auth.currentUser!.uid;

    return _firestore
        .collection('chat_rooms')
        .where('participants', arrayContains: currentUserID)
        .where('participant_roles.$currentUserID', isEqualTo: 'user')
        .snapshots()
        .map((querySnapshot) => querySnapshot.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final participants = data['participants'] as List<dynamic>;
              final participantID = participants
                  .firstWhere((id) => id != currentUserID, orElse: () => null);
              final participantName =
                  data['participant_names']?[participantID] ?? "Unknown";
              return {
                'participant_id': participantID,
                'participant_name': participantName,
                ...data
              };
            }).toList());
  }
}
