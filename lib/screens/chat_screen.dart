import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:healthapp/services/chat_services.dart';
import 'package:healthapp/widgets/chat_bubble.dart';
import 'package:healthapp/widgets/my_textfield.dart';
import 'package:intl/intl.dart';

class ChatScreen extends StatefulWidget {
  final String receiverName;
  final String receiverID;

  ChatScreen({super.key, required this.receiverName, required this.receiverID});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? getCurrentUser() {
    return _auth.currentUser;
  }

  //text controller
  final TextEditingController _messageController = TextEditingController();

  //chat services
  final ChatServices _chatServices = ChatServices();

  //for textfield focus
  FocusNode myFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();

    // Add listener to focus node
    myFocusNode.addListener(() {
      if (myFocusNode.hasFocus) {
        // Cause a delay so that the keyboard has time to show up, then scroll
        Future.delayed(
          const Duration(milliseconds: 500),
          () => scrollDown(),
        );
      }
    });

    // Delay scroll after the first frame is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 500), () => scrollDown());
    });
  }

  @override
  void dispose() {
    myFocusNode.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  //scroll controller
  final ScrollController _scrollController = ScrollController();
  void scrollDown() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(seconds: 1),
        curve: Curves.fastOutSlowIn,
      );
    }
  }

  //send message
  void sendMessage() async {
    //if there is nothing inside the textfield
    if (_messageController.text.isNotEmpty) {
      //send the message
      await _chatServices.sendMessage(
          widget.receiverID, _messageController.text);

      //clear the controller
      _messageController.clear();
    }

    scrollDown();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.receiverName,
          style: TextStyle(fontSize: 25),
        ),
        backgroundColor: Color(0xFF5ECD81),
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: _buildMessageList(),
          ),
          _buildUserInput(),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    String senderId = getCurrentUser()!.uid;
    return StreamBuilder(
      stream: _chatServices.getMessages(widget.receiverID, senderId),
      builder: (context, snapshot) {
        //errors
        if (snapshot.hasError) {
          debugPrint('Stream error: ${snapshot.error}');
          return Text('Error: ${snapshot.error}');
        }

        //loading
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Text("Loading..");
        }

        // Retrieve message documents
        List<DocumentSnapshot> messages = snapshot.data!.docs;

        // Initialize variables to track the previous message's date
        DateTime? previousMessageDate;

        // Build the message list with date headers
        return ListView.builder(
          controller: _scrollController,
          itemCount: messages.length,
          itemBuilder: (context, index) {
            // Get the message data and timestamp
            DocumentSnapshot doc = messages[index];
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
            Timestamp timestamp = data['timestamp'] as Timestamp;
            DateTime messageDate = timestamp.toDate();

            // Format the date
            String formattedDate = DateFormat('yMMMMd').format(messageDate);

            // Check if the date has changed since the previous message
            bool isNewDay = previousMessageDate == null ||
                !isSameDay(messageDate, previousMessageDate!);

            // Update the previous message date
            previousMessageDate = messageDate;

            // If it's a new day, show the date header above the message
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (isNewDay) _buildDateHeader(formattedDate), // Date header
                _buildMessageItem(doc), // Message bubble
              ],
            );
          },
        );
      },
    );
  }

  // Helper function to check if two DateTime objects are on the same day
  bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

// Build the date header widget
  Widget _buildDateHeader(String formattedDate) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Center(
        child: Text(
          formattedDate,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.grey[700],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageItem(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    //is current user
    bool isCurrentUser = data['senderID'] == getCurrentUser()!.uid;

    //allign message to the right if sender is the current user, otherwise left
    var alignment =
        isCurrentUser ? Alignment.centerRight : Alignment.centerLeft;

    // Extract and format the timestamp
    Timestamp timestamp = data['timestamp'] as Timestamp;
    DateTime dateTime = timestamp.toDate();
    String formattedTime = DateFormat('h:mm a').format(dateTime);

    return Container(
      alignment: alignment,
      child: Column(
        crossAxisAlignment:
            isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          ChatBubble(message: data["message"], isCurrentUser: isCurrentUser),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Text(
              formattedTime,
              style: TextStyle(
                  fontSize: 12, color: Colors.grey), // Style the timestamp
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserInput() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 50),
      child: Row(
        children: [
          Expanded(
            child: MyTextfield(
              hintText: "type a message",
              obscureText: false,
              controller: _messageController,
              focusNode: myFocusNode,
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Color(0xFF238878),
              shape: BoxShape.circle,
            ),
            margin: const EdgeInsets.only(right: 25),
            child: IconButton(
                onPressed: sendMessage,
                icon: Icon(
                  Icons.arrow_right_outlined,
                  color: Colors.white,
                )),
          )
        ],
      ),
    );
  }
}
