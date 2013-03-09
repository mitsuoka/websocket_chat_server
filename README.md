WebSocket Chat Server
==

Dart sample WebSocket server application. 
Client codes for Chrome and Dartium are provided from this server.

## Components

Server program:

+ `WebSocketChatServer.dart`

Client program for Chrome browser:
 
+ `WebSocketChat.html` //  Written in JavaScript

Client program for Dartium browser:

+ `WebSocketChatClient.dart`  //  Written in Dart

+ `WebSocketChatClient.html` 

+ `dart.js` // Bootstrap code

## Installing

1. Download and unpack this application into a folder.

2. Open the folder from Dart Editor.

 File - > Open Existing Folder...

3. Install pubs.

 Tools -> Pub Install

4. Run the server.

 Select bin/WebSocketChatServer.dart

 Right click -> Run

5. Access the server from two or more Chrome and or Dartium instances:

 http://localhost:8080/chat

 This server distinguishes Dartium and returns Dart based client page.
      
 For request from Chrome, this server returns JS based client page.

## Try it

1. To establish an WebSocket connection, enter your name and click `join` button.
2. To chat, enter chat message and click `send` button.
3. To close the connection, click `leave` button.

## License
This library is licensed under [MIT License][MIT].


[MIT]: http://www.opensource.org/licenses/mit-license.php