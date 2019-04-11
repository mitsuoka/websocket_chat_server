WebSocket Chat Server
==

Dart 2 version of the  sample WebSocket server. 

Client code for Chrome is delivered from this server.

## Components

Server program:

+ `WebSocketChatServer.dart`

Client program for Chrome browser:
 
+ `WebSocketChat.html` //  Written in JavaScript

+ `WebSocketChatClient.dart`  //  Written in Dart

+ `WebSocketChatClient.html`  // Paired with Dart code

## Installing

1. Download and unpack this application into a folder.

2. Open the folder from your IDE.

3. Apply 'Get dependencies' and 'Build...' commands.

4. Run the server bin/WebSocketChatServer.dart

5. Access the server from two or more Chrome instances using:
`http://localhost:8080/chat`


## Try it

1. To establish an WebSocket connection, enter your name and click `join` button.
2. To chat, enter chat message and click `send` button.
3. To close the connection, click `leave` button.

## License
This library is licensed under [MIT License](http://www.opensource.org/licenses/mit-license.php).
