import 'dart:developer';

import 'package:chatapp/api/apis.dart';
import 'package:chatapp/helper/dialouges.dart';
import 'package:chatapp/models/chat_user.dart';
import 'package:chatapp/screens/profile_screen.dart';
import 'package:chatapp/widgets/chat_user_card.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../main.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // for storing all users
  List<ChatUser> _list = [];
  // for storing searched users
  final List<ChatUser> _searchlist = [];
  // for searching users by name
  bool _isSearching = false;
  @override
  void initState() {
    super.initState();
    APIs.getSelfInfo();

    // to update last active status via firebase and system channel
    // system channel is an inbuilt channel in flutter to get app state
    // Resume means user open app
    // Paused means user exit app
    SystemChannels.lifecycle.setMessageHandler((message) {
      log('message: $message');
      if (APIs.auth.currentUser != null) {
        if (message.toString().contains('paused')) APIs.updateLastActive(false);
        if (message.toString().contains('resume')) APIs.updateLastActive(true);
      }
      return Future.value(message);
    });

    // resume means user open app
    // paused means user exit app
    // Here we used system channel to get app state and update last active status like whatsapp and telegram
    SystemChannels.lifecycle.setMessageHandler((message) {
      log('message: $message');
      // here when user exit app then update last active status to false
      if (message.toString().contains('paused')) APIs.updateLastActive(false);
      // here when user open app then update last active status to true
      if (message.toString().contains('resume')) APIs.updateLastActive(true);
      return Future.value(message);
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // to hide keyboard when user tap on screen
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: PopScope(
        // to prevent user from exiting app by pressing back button
        canPop:
            _isSearching, // If _isSearching is true, we handle the pop ourselves
        onPopInvoked: (bool didPop) {
          // This callback handles the pop action
          if (!didPop && _isSearching) {
            // If didPop is false and we're searching, we cancel the search
            setState(() {
              _isSearching = false;
            });
          }
        },
        child: Scaffold(
            appBar: AppBar(
              //Home icon
              leading: const Icon(CupertinoIcons.home),
              centerTitle: true,
              elevation: 1,
              iconTheme: const IconThemeData(color: Colors.black87),
              title: _isSearching
                  ? TextField(
                      decoration: const InputDecoration(
                        hintText: 'Name, Email, ...',
                        hintStyle: TextStyle(color: Colors.black87),
                        border: InputBorder.none,
                      ),
                      autofocus: true,
                      style:
                          const TextStyle(color: Colors.black87, fontSize: 19),
                      onChanged: (val) {
                        //Search logic
                        _searchlist.clear();
                        for (var i in _list) {
                          if (i.name
                                  .toLowerCase()
                                  .contains(val.toLowerCase()) ||
                              i.email
                                  .toLowerCase()
                                  .contains(val.toLowerCase()) ||
                              i.about
                                  .toLowerCase()
                                  .contains(val.toLowerCase())) {
                            _searchlist.add(i);
                          }
                          setState(() {
                            _searchlist;
                          });
                        }
                      },
                    )
                  : const Text('Chat App',
                      style: TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.normal,
                          letterSpacing: 0.8,
                          fontSize: 19)),
              actions: [
                //Icons
                IconButton(
                  onPressed: () {
                    setState(() {
                      _isSearching = !_isSearching;
                    });
                  },
                  icon: Icon(_isSearching
                      ? CupertinoIcons.clear_circled_solid
                      : Icons.search), //Search icon
                ),

                //More features button
                IconButton(
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                ProfileScreen(user: APIs.me)));
                  },
                  icon: const Icon(Icons.more_vert),
                ),
              ],
              backgroundColor: Colors.white,
            ),

            // floating button for chat
            floatingActionButton: Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: FloatingActionButton(
                onPressed: () {
                  // Navigator.push(context,
                  // MaterialPageRoute(builder: (context) => DrawerFb1()));
                  _AddEmailUserDialog();
                },
                child: const Icon(Icons.message),

                //Message icon (chat bubble)
              ),
            ),
            body: StreamBuilder(
              stream: APIs.getMyFrensId(),
              builder: (context, snapshot) {
                switch (snapshot.connectionState) {
                  //if data is not loaded yet then waiting or none
                  case ConnectionState.waiting:
                  case ConnectionState.none:
                    return const Center(child: CircularProgressIndicator());

                  //if data is loaded then active or done then show data
                  case ConnectionState.active:
                  case ConnectionState.done:
                    return StreamBuilder(
                      stream: APIs.getAllUsers(snapshot.data?.docs
                              .map((e) => e.id)
                              .toList() ??
                          []), //users collection from firestore database in firebase
                      builder: (context, snapshot) {
                        switch (snapshot.connectionState) {
                          //if data is not loaded yet then waiting or none
                          case ConnectionState.waiting:
                          case ConnectionState.none:
                          // return const Center(
                          //     child: CircularProgressIndicator());

                          //if data is loaded then active or done then show data
                          case ConnectionState.active:
                          case ConnectionState.done:
                            final data = snapshot.data?.docs;
                            // error in docs due to null safety in flutter to solve this error we have to add ? after docs
                            _list = data
                                    ?.map((e) => ChatUser.fromJson(e.data()))
                                    .toList() ??
                                [];
                            if (_list.isNotEmpty) {
                              return ListView.builder(
                                  itemCount: _isSearching
                                      ? _searchlist.length
                                      : _list.length,
                                  padding:
                                      EdgeInsets.only(top: mq.height * .01),
                                  physics: const BouncingScrollPhysics(),
                                  itemBuilder: ((context, index) {
                                    return ChatUserCard(
                                      user: _isSearching
                                          ? _searchlist[index]
                                          : _list[index],
                                    );
                                    // return Text('Name: ${list[index]}');
                                  }));
                            } else {
                              return const Center(
                                  child: Text('No user found',
                                      style: TextStyle(fontSize: 20)));
                            }
                        }
                      },
                    );
                }
              },
            )),
      ),
    );
  }

//Add chatuser
  // ignore: non_constant_identifier_names
  void _AddEmailUserDialog() {
    String email = "";
    showDialog(
        context: context,
        builder: (_) => AlertDialog(
              contentPadding: const EdgeInsets.only(
                  top: 20, bottom: 10, left: 24, right: 24),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: const Row(children: [
                Icon(
                  Icons.person_add,
                  color: Colors.black87,
                ),
                SizedBox(
                  width: 10,
                ),
                Text(
                  'Add User',
                  style: TextStyle(color: Colors.black87),
                )
              ]),

              //content
              content: TextFormField(
                maxLines: null,
                onChanged: ((value) => email = value),
                decoration: InputDecoration(
                  hintText: "enter email",
                  prefixIcon: const Icon(Icons.email),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15)),
                ),
              ),

              actions: [
                //cancel button
                MaterialButton(
                    onPressed: () {
                      //hide dialog
                      Navigator.pop(context);
                    },
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Colors.black87),
                    )),

                //add button
                MaterialButton(
                  onPressed: () async {
                    //hide dialog
                    Navigator.pop(context);
                    //add user
                    if (email.isNotEmpty) {
                      await APIs.AddChatUser(email).then((value) {
                        if (!value) {
                          Dialogs.showSnackBar(context, 'User not found');
                        }
                      });
                    }
                  },
                  child: const Text(
                    'Add',
                    style: TextStyle(color: Colors.black87),
                  ),
                )
              ],

              //
            ));
  }
}
