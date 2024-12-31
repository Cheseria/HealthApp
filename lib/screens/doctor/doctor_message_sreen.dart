import 'package:flutter/material.dart';
import 'package:healthapp/screens/chat_screen.dart';
import 'package:healthapp/services/chat_services.dart';

class DoctorMessagesScreen extends StatefulWidget {
  @override
  State<DoctorMessagesScreen> createState() => _DoctorMessagesScreenState();
}

class _DoctorMessagesScreenState extends State<DoctorMessagesScreen> {
  final ChatServices _chatServices = ChatServices();
  String searchQuery = ""; // Store the search query

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 40),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              "Messages",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(height: 30),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 15),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 300,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 15),
                      child: TextFormField(
                        onChanged: (value) {
                          setState(() {
                            searchQuery = value; // Update the search query
                          });
                        },
                        decoration: InputDecoration(
                          hintText: "Search",
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                  Icon(
                    Icons.search,
                    color: Colors.black,
                  )
                ],
              ),
            ),
          ),
          SizedBox(height: 20),

          // Firestore integration with StreamBuilder
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: _chatServices.getDoctorChatroomsStream(),
            builder: (context, snapshot) {
              // Handle errors
              if (snapshot.hasError) {
                return Center(
                    child: Text("Error loading chatrooms: ${snapshot.error}"));
              }

              // Handle loading state
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              // Check for data
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text("No chatrooms found"));
              }

              // Filter chatrooms based on the search query
              final filteredChatrooms = snapshot.data!.where((chatroom) {
                final participantName =
                    chatroom["participant_name"]?.toLowerCase() ?? "";
                return participantName.contains(searchQuery.toLowerCase());
              }).toList();

              if (filteredChatrooms.isEmpty) {
                return const Center(child: Text("No matching chatrooms found"));
              }

              // Dynamically build the ListView based on Firestore data
              return ListView.builder(
                physics: NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: filteredChatrooms.length,
                itemBuilder: (context, index) {
                  final chatroomData = filteredChatrooms[index];

                  return ListTile(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatScreen(
                            receiverName: chatroomData["participant_name"],
                            receiverID: chatroomData["participant_id"],
                          ),
                        ),
                      );
                    },
                    leading: Icon(Icons.chat_bubble_outline),
                    title: Text(
                      chatroomData["participant_name"] ?? "Unknown",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
