import 'dart:async';

import 'package:flutter/material.dart';
import 'package:harmony_sdk/harmony.dart';

class MessageList extends StatefulWidget {
  MessageList(this.channel);

  final Channel channel;

  @override
  _MessageListState createState() => _MessageListState();
}

class _MessageListState extends State<MessageList> {
  final messageController = TextEditingController();

  Channel _channel;
  List<MMessage> _messages;
  StreamSubscription<GGuildEvent> _sub;
  StreamSubscription<GGuildEvent> _cancelingSub;

  @override void dispose() {
    _sub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_messages == null || _channel?.id != widget.channel.id) {
      _channel = widget.channel;
      resetEventSubscription();
      return FutureBuilder(
          future: _channel.getMessages(null),
          builder: (context, snapshot) {
            if (snapshot.hasData && !snapshot.hasError) {
              _messages = snapshot.data;
            }
            if (snapshot.hasError) {
              print(snapshot.error);
            }
            return CircularProgressIndicator();
      });
    }
    return Column(
      children: [
        Expanded(
            child: ListView.builder(
                shrinkWrap: true,
                reverse: true,
                itemCount: _messages == null ? 0 : _messages.length,
                itemBuilder: (BuildContext context, int index) {
                  MMessage m = _messages[index];
                  return ListTile(
                    title: Text(m.content),
                    onTap: () {},
                  );
                })
        ),
        Row(
          children: [
            Expanded(child: Padding(
                padding: EdgeInsets.all(16.0),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Message',
                  ),
                  controller: messageController,
                ))),
            IconButton(
              icon: Icon(Icons.send, color: Colors.white, size: 30.0),
              onPressed: () async {
                try {
                  await _channel.sendMessage(messageController.text);
                  messageController.clear();
                } catch (e) {
                  Scaffold.of(context).showSnackBar(SnackBar(content:  Text("Send: $e")),);
                }
              },
            )
          ],
        )
      ],
    );
  }

  void resetEventSubscription() {
    if(_sub != null) {
      _cancelingSub = _sub;
      _cancelingSub.cancel().then((value) => _cancelingSub = null);
    }
    _sub = _channel.streamGuildEvents().listen((event) {
      if (event is MMessageSent) {
        if (event.message.channelId == _channel.id) {
          setState(() {
            _messages = new List.from(_messages)
              ..insert(0, event.message);
          });
        }
      }
    });
  }

}
