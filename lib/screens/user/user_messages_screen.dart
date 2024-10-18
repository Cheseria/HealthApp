import 'package:flutter/material.dart';
import 'package:healthapp/screens/chat_screen.dart';
import 'package:healthapp/services/chat_services.dart';

class UserMessagesScreen extends StatefulWidget {
  @override
  State<UserMessagesScreen> createState() => _UserMessagesScreenState();
}

class _UserMessagesScreenState extends State<UserMessagesScreen> {
  final ChatServices _chatServices = ChatServices();

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
            stream: _chatServices.getUsersStream(),
            builder: (context, snapshot) {
              // Handle errors
              if (snapshot.hasError) {
                return Center(
                    child: Text("Error loading users: ${snapshot.error}"));
              }

              // Handle loading state
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              // Check for data
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text("No users found"));
              }

              // Dynamically build the ListView based on Firestore data
              return ListView.builder(
                physics: NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  final userData = snapshot.data![index];

                  return ListTile(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatScreen(
                            receiverName: userData["full_name"],
                            receiverID: userData["uid"],
                          ),
                        ),
                      );
                    },
                    leading: Icon(Icons.contacts_outlined),
                    title: Text(
                      userData["full_name"] ?? "Unknown",
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
