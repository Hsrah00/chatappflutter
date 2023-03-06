import 'dart:convert';
import 'dart:developer';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:chatapp/models/chat_user.dart';
import 'package:chatapp/models/message.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/container.dart';
import 'package:flutter/src/widgets/framework.dart';

import '../api/apis.dart';
import '../main.dart';
import '../widgets/message_card.dart';

class ChatScreen extends StatefulWidget {
  final ChatUser user;
  const ChatScreen({
    super.key,
    required this.user,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  // for storing all messages
  List<Message> _list = [];

// for handling text field messages and sending them
  final _textController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          flexibleSpace: _appBar(),
          backgroundColor: Colors.white,
        ),
        backgroundColor: Color.fromARGB(255, 146, 254, 254),
        body: Column(
          children: [
            Expanded(
              child: StreamBuilder(
                  stream: APIs.getAllmessages(widget
                      .user), //users collection from firestore database in firebase
                  builder: (context, snapshot) {
                    switch (snapshot.connectionState) {
                      //if data is not loaded yet then waiting or none
                      case ConnectionState.waiting:
                      case ConnectionState.none:
                        return const SizedBox();

                      //if data is loaded then active or done then show data
                      case ConnectionState.active:
                      case ConnectionState.done:
                        final data = snapshot.data?.docs;

                        _list = data
                                ?.map((e) => Message.fromJson(e.data()))
                                .toList() ??
                            [];

                        if (_list.isNotEmpty) {
                          return ListView.builder(
                              itemCount: _list.length,
                              padding: EdgeInsets.only(top: mq.height * .01),
                              physics: BouncingScrollPhysics(),
                              itemBuilder: ((context, index) {
                                return MessageCard(
                                  message: _list[index],
                                );
                              }));
                        } else {
                          return const Center(
                              child: Text('Say hii😯😯!',
                                  style: TextStyle(fontSize: 20)));
                        }
                    }
                  }),
            ),
            _chatInput()
          ],
        ),
      ),
    );
  }

  Widget _appBar() {
    return InkWell(
      onTap: () {},
      child: Row(
        children: [
          IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Icon(
                Icons.arrow_back_ios,
                color: Colors.black87,
              )),
          ClipRRect(
            borderRadius: BorderRadius.circular(mq.height * .03),
            child: CachedNetworkImage(
              width: mq.height * .05,
              height: mq.height * .05,
              imageUrl: widget.user.image,
              errorWidget: (context, url, error) => const CircleAvatar(
                child: Icon(CupertinoIcons.person),
              ),
            ),
          ),
          SizedBox(width: 10),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // for printing the name of the user
              Text(
                widget.user.name,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 2),
              // for printing the last seen of the user
              Text(
                "Yeh raaz bhi uske saath chala gaya",
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 12,
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _chatInput() {
    return Padding(
      padding: EdgeInsets.symmetric(
          vertical: mq.height * .01, horizontal: mq.width * .025),
      child: Row(
        children: [
          // Input field and buttons
          Expanded(
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  //emoji button
                  IconButton(
                    onPressed: () {},
                    icon: Icon(
                      Icons.emoji_emotions,
                      color: Colors.greenAccent.shade700,
                      size: 28,
                    ),
                  ),

                  // text send box
                  Expanded(
                      child: TextField(
                    controller: _textController,
                    keyboardType: TextInputType.multiline,
                    maxLines: null,
                    decoration: InputDecoration(
                      hintText: "Type a message",
                      hintStyle: TextStyle(
                        color: Colors.greenAccent.shade700,
                      ),
                      border: InputBorder.none,
                    ),
                  )),

                  // Pick image from gallery
                  IconButton(
                    onPressed: () {},
                    icon: Icon(
                      Icons.image_sharp,
                      color: Colors.greenAccent.shade700,
                      size: 28,
                    ),
                  ),

                  // pick image from camera
                  IconButton(
                    onPressed: () {},
                    icon: Icon(
                      Icons.camera_alt_rounded,
                      color: Colors.greenAccent.shade700,
                      size: 28,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Send message button
          MaterialButton(
              onPressed: () {
                if (_textController.text.isNotEmpty) {
                  APIs.sendMessage(widget.user, _textController.text);
                  _textController.text = '';
                }
              },
              minWidth: 0,
              padding:
                  EdgeInsets.only(top: 10, bottom: 10, left: 20, right: 20),
              shape: CircleBorder(),
              color: Color.fromARGB(255, 5, 189, 240),
              child: Icon(Icons.send,
                  color: Color.fromARGB(255, 227, 228, 228), size: 30)),
        ],
      ),
    );
  }
}
// // error in docs due to null safety in flutter to solve this error we have to add ? after docs