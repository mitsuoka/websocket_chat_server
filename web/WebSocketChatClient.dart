/*
  Dart code sample : WebSocket chat client for Dartium
    1. Save these files and dart.js into a folder named WebSocketChat.
    2. From Dart editor, File > Open Folder and select this WebSocketChat folder.
    3. Run WebSocketChatServer.dart as server.
    4. Call the the server from Dartium: http://localhost:8080/chat
    5. To establish WebSocket connection, enter your name and click 'join' button.
    6. To chat, enter chat message and click 'send' button.
    7. To close the connection, click 'leave' button
  June 2012, by Cresc Corp.
  February 2013, revised to incorporate re-designed dart:html library.
  Ref: www.cresc.co.jp/tech/java/Google_Dart/DartLanguageGuide.pdf (in Japanese)
*/

import 'dart:html';

var wsUri = 'ws://localhost:8080/Chat';
var mode = 'DISCONNECTED';
WebSocket webSocket;
var userName;
var sendMessage;
var consoleLog;

void main() {
  show('Dart WebSocket Chat Sample');
  userName = document.query('#userName');
  sendMessage = document.query('#sendMessage');
  consoleLog = document.query('#consoleLog');
  document.query('#clearLogButton').onClick.listen((e) {clearLog();});
  document.query('#joinButton').onClick.listen((e) {doConnect();});
  document.query('#leaveButton').onClick.listen((e) {doDisconnect();});
  document.query('#sendButton').onClick.listen((e) {doSend();});
}

doConnect() {
  if (mode == 'CONNECTED') {
    return;
  }
  if (userName.value == '') {
    logToConsole('<span style="color: red;"><strong>Enter your name!</strong></span>');
    return;
  }
  webSocket = new WebSocket(wsUri);
  webSocket.onOpen.listen(onOpen);
  webSocket.onClose.listen(onClose);
  webSocket.onMessage.listen(onMessage);
  webSocket.onError.listen(onError);
}

doDisconnect() {
  if (mode == 'CONNECTED') {
  }
  webSocket.close();
}

doSend() {
  if (sendMessage.value != '' && mode == 'CONNECTED') {
    webSocket.send(sendMessage.value);
    sendMessage.value = '';
  }
}

clearLog() {
  while (consoleLog.nodes.length > 0) {
    consoleLog.nodes.removeLast();
  }
}

onOpen(open) {
  logToConsole('CONNECTED');
  mode = 'CONNECTED';
  webSocket.send('userName=${userName.value}');
}

onClose(close) {
  logToConsole('DISCONNECTED');
  mode = 'DISCONNECTED';
}

onMessage(message) {
  logToConsole('<span style="color: blue;">${message.data}</span>');
}

onError(error) {
  logToConsole('<span style="color: red;">ERROR:</span> ${error}');
  webSocket.close();
}

logToConsole(message) {
  Element pre = new Element.tag('p');
  pre.style.wordWrap = 'break-word';
  pre.innerHtml = message;
  consoleLog.nodes.add(pre);
  while (consoleLog.nodes.length > 50) {
    consoleLog.$dom_removeChild(consoleLog.nodes[0]);
  }
  pre.scrollIntoView();
}

show(String message) {
  document.query('#status').text = message;
}