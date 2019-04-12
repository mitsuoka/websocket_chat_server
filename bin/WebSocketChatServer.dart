/*
  Dart code sample : WebSocket chat server
    1. Run this WebSocketChatServer.dart as server.
    2. Access the server from Chrome browser:
         http://localhost:8080/chat
    3. To establish the WebSocket connection, enter your name and click 'join' button.
    4. To chat, enter chat message and click 'send' button.
    5. To close the connection, click 'leave' button
  Source : http://blog.sethladd.com/2012/04/dart-server-supports-web-sockets.html
  June  2012, modified by Cresc Corp.
  Sept. 2012, modified to incorpolate catch syntax change
  Oct.  2012, incorporated M1 changes
  Feb.  2013, incorporated re-designed dart:io (v2) library
  March 2013, incorporated API changes (WebSocket r19376 and String)
  June  2013, incorporated API (WebSocket.send -> WebSocket.add) and Pub changes
  April 2019, made Dart 2 compliant
  Ref: www.cresc.co.jp/tech/java/Google_Dart/DartLanguageGuide.pdf (in Japanese)
*/

import 'dart:io';
import 'dart:async';
import 'package:mime_type/mime_type.dart' as mime;

final HOST = "localhost";
final PORT = 8080;
final HTTP_REQUEST_PATH = "/chat";
final WEB_SOCKET_REQUEST_PATH = "/Chat";
final LOG_REQUESTS = true;

void main() {
  WebSocketHandler webSocketHandler = WebSocketHandler();
  HttpRequestHandler httpRequestHandler = HttpRequestHandler();
  print(
      '${DateTime.now().toString().substring(11)} - Serving Chat on ${HOST}:${PORT}.');

  HttpServer.bind(HOST, PORT).then((HttpServer server) {
    server.listen((request) {
      if (request.uri.path == WEB_SOCKET_REQUEST_PATH) {
        WebSocketTransformer.upgrade(request).then((ws) {
          webSocketHandler.wsHandler(ws);
        });
      }
      else if (request.uri.path.startsWith(HTTP_REQUEST_PATH)) {
        log("HTTP request arrived");
        httpRequestHandler.requestHandler(request);
      }
    });
  });
}

// handle WebSocket events
class WebSocketHandler {
  Map<String, WebSocket> users = {}; // Map of current users

  wsHandler(WebSocket ws) {
    log('New connection ${ws.hashCode} '
        '(active connections : ${users.length + 1})');
    ws.listen((message) {
      processMessage(ws, message);
    }, onDone: () {
      processClosed(ws);
    });
  }

  processMessage(WebSocket ws, String receivedMessage) {
    try {
      String sendMessage = '';
      String userName;
      userName = getUserName(ws);
      log('Received message on connection'
          ' ${ws.hashCode}: $receivedMessage');
      if (userName != null) {
        sendMessage = '${timeStamp()} $userName >> $receivedMessage';
      } else if (receivedMessage.startsWith("userName=")) {
        userName = receivedMessage.substring(9);
        if (users[userName] != null) {
          sendMessage = 'Note : $userName already exists in this chat room. '
              'Previous connection was deleted.\n';
          log('Duplicated name, closed previous '
              'connection ${users[userName].hashCode} (active connections : ${users.length})');
          users[userName]
              .add(preFormat('$userName has joind using another connection!'));
          users[userName].close(); //  close the previous connection
        }
        users[userName] = ws;
        sendMessage = '${sendMessage}${timeStamp()} * $userName joined.';
      }
      sendAll(sendMessage);
    } catch (err, st) {
      print('${new DateTime.now().toString()} - Exception - ${err.toString()}');
      print(st);
    }
  }

  processClosed(WebSocket ws) {
    try {
      String userName = getUserName(ws);
      if (userName != null) {
        String sendMessage = '${timeStamp()} * $userName left.';
        users.remove(userName);
        sendAll(sendMessage);
        log('Closed connection '
            '${ws.hashCode} with ${ws.closeCode} for ${ws.closeReason}'
            '(active connections : ${users.length})');
      }
    } catch (err, st) {
      print(
          '${new DateTime.now().toString().substring(11)} - Exception - ${err.toString()}');
      print(st);
    }
  }

  String getUserName(WebSocket ws) {
    String userName;
    users.forEach((key, value) {
      if (value == ws) userName = key;
    });
    return userName;
  }

  void sendAll(String sendMessage) {
    users.forEach((key, value) {
      value.add(preFormat(sendMessage));
    });
  }
}

String timeStamp() => new DateTime.now().toString().substring(11, 16);

String preFormat(String s) {
  StringBuffer b = StringBuffer();
  String c;
  bool nbsp = false;
  for (int i = 0; i < s.length; i++) {
    c = s[i];
    if (c != ' ') nbsp = false;
    if (c == '&') {
      b.write('&amp;');
    } else if (c == '"') {
      b.write('&quot;');
    } else if (c == "'") {
      b.write('&#39;');
    } else if (c == '<') {
      b.write('&lt;');
    } else if (c == '>') {
      b.write('&gt;');
    } else if (c == '\n') {
      b.write('<br>');
    } else if (c == ' ') {
      if (!nbsp) {
        b.write(' ');
        nbsp = true;
      } else {
        b.write('&nbsp;');
      }
    } else {
      b.write(c);
    }
  }
  return b.toString();
}

// adapt this function to your logger
void log(String s) {
  if (LOG_REQUESTS) print('${DateTime.now().toString().substring(11)} : $s');
}

// handle HTTP requests
class HttpRequestHandler {
  void requestHandler(HttpRequest request) {
    HttpResponse response = request.response;
    try {
      String fileName = request.uri.path;
      if (fileName == '/chat') {
        if (request.headers['user-agent'][0].contains('Dart')) {
          fileName = 'web/WebSocketChatClient.html';
        } else {
          fileName = 'web/WebSocketChat.html';
        }
        FileHandler().sendFile(request, response, fileName);
      } else if (fileName.startsWith('/chat/')) {
        fileName = request.uri.path.replaceFirst('/chat/', 'web/');
        FileHandler().sendFile(request, response, fileName);
      } else {
        NotFoundHandler().onRequest(response);
      }
    } catch (err, st) {
      print('${DateTime.now().toString().substring(11)} - '
          'Http request handler error : $err.toString()');
      print(st);
      response.close();
    }
  }
}

class FileHandler {
  void sendFile(HttpRequest request, HttpResponse response, String fileName) {
    try {
      if (LOG_REQUESTS) {
        log('Requested file name : $fileName');
      }
      File file = File(fileName);
      if (file.existsSync()) {
        String mimeType = mime.mime(fileName);
        if (mimeType == null) mimeType = 'text/plain; charset=UTF-8';
        response.headers.set('Content-Type', mimeType);
        RandomAccessFile openedFile = file.openSync();
        response.contentLength = openedFile.lengthSync();
        openedFile.closeSync();
        // Pipe the file content into the response.
        file.openRead().pipe(response);
      } else {
                  log('File not found: $fileName');
        NotFoundHandler().onRequest(response);
      }
    } catch (err, st) {
      print(
          '${new DateTime.now().toString()} - File handler error : $err.toString()');
      print(st);
      response.close();
    }
  }
}

class NotFoundHandler {
  static final String notFoundPageHtml = '''
<html><head>
<title>404 Not Found</title>
</head><body>
<h1>Not Found</h1>
<p>The requested URL or File was not found on this server.</p>
</body></html>''';

  void onRequest(HttpResponse response) {
    response.statusCode = HttpStatus.notFound;
    response.headers.set('Content-Type', 'text/html; charset=UTF-8');
    response.write(notFoundPageHtml);
    response.close();
  }
}
