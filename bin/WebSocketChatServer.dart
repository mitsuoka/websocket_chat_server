/*
  Dart code sample : WebSocket chat server
    1. Run this WebSocketChatServer.dart as server.
    2. Access the server from Dartium or Chrome browser:
         http://localhost:8080/chat
       This chat server distinguishes Dartium and returns Dart based client page.
       For the request from Chrome, this server returns JS based client page.
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
  Ref: www.cresc.co.jp/tech/java/Google_Dart/DartLanguageGuide.pdf (in Japanese)
*/

import 'dart:io';
import 'dart:async';
import '../packages/mime_type/mime_type.dart' as mime;

final HOST = "127.0.0.1";
final PORT = 8080;
final LOG_REQUESTS = true;

void main() {
  WebSocketHandler webSocketHandler = new WebSocketHandler();
  HttpRequestHandler httpRequestHandler = new HttpRequestHandler();

  HttpServer.bind(HOST, PORT)
  .then((HttpServer server) {
    StreamController sc = new StreamController();
    sc.stream.transform(new WebSocketTransformer())
      .listen((WebSocket ws){
        webSocketHandler.wsHandler(ws);
      });

    server.listen((HttpRequest request) {
      if (request.uri.path == '/Chat') {
        sc.add(request);
      } else if (request.uri.path.startsWith('/chat')) {
        httpRequestHandler.requestHandler(request);
      } else {
        new NotFoundHandler().onRequest(request.response);
      }
    });
  });

  print('${new DateTime.now().toString()} - Serving Chat on ${HOST}:${PORT}.');
}


// handle WebSocket events
class WebSocketHandler {

  Map<String, WebSocket> users = {}; // Map of current users

  wsHandler(WebSocket ws) {
    if (LOG_REQUESTS) {
      log('${new DateTime.now().toString()} - New connection ${ws.hashCode} '
        '(active connections : ${users.length + 1})');
    }
    ws.listen((message) {
      processMessage(ws, message);
      } ,
      onDone:(){
        processClosed(ws);
      }
    );
  }

  processMessage(WebSocket ws, String receivedMessage) {
    try {
      String sendMessage = '';
      String userName;
      userName = getUserName(ws);
      if (LOG_REQUESTS) {
        log('${new DateTime.now().toString()} - Received message on connection'
          ' ${ws.hashCode}: $receivedMessage');
      }
      if (userName != null) {
        sendMessage = '${timeStamp()} $userName >> $receivedMessage';
      } else if (receivedMessage.startsWith("userName=")) {
        userName = receivedMessage.substring(9);
        if (users[userName] != null) {
          sendMessage = 'Note : $userName already exists in this chat room. '
            'Previous connection was deleted.\n';
          if (LOG_REQUESTS) {
            log('${new DateTime.now().toString()} - Duplicated name, closed previous '
            'connection ${users[userName].hashCode} (active connections : ${users.length})');
          }
          users[userName].add(preFormat('$userName has joind using another connection!'));
          users[userName].close();  //  close the previous connection
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

  processClosed(WebSocket ws){
    try {
      String userName = getUserName(ws);
      if (userName != null) {
        String sendMessage = '${timeStamp()} * $userName left.';
        users.remove(userName);
        sendAll(sendMessage);
        if (LOG_REQUESTS) {
          log('${new DateTime.now().toString()} - Closed connection '
            '${ws.hashCode} with ${ws.closeCode} for ${ws.closeReason}'
            '(active connections : ${users.length})');
        }
      }
    } catch (err, st) {
      print('${new DateTime.now().toString()} Exception - ${err.toString()}');
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


String timeStamp() => new DateTime.now().toString().substring(11,16);


String preFormat(String s) {
  StringBuffer b = new StringBuffer();
  String c;
  bool nbsp = false;
  for (int i = 0; i < s.length; i++){
    c = s[i];
    if (c != ' ') nbsp = false;
    if (c == '&') { b.write('&amp;');
    } else if (c == '"') { b.write('&quot;');
    } else if (c == "'") { b.write('&#39;');
    } else if (c == '<') { b.write('&lt;');
    } else if (c == '>') { b.write('&gt;');
    } else if (c == '\n') { b.write('<br>');
    } else if (c == ' ') {
      if (!nbsp) {
        b.write(' ');
        nbsp = true;
      }
      else { b.write('&nbsp;');
      }
    }
    else { b.write(c);
    }
  }
  return b.toString();
}


// adapt this function to your logger
void log(String s) {
  print(s);
}


// handle HTTP requests
class HttpRequestHandler {
  void requestHandler(HttpRequest request) {
    HttpResponse response = request.response;
    try {
      String fileName = request.uri.path;
      if (fileName == '/chat') {
        if (request.headers['user-agent'][0].contains('Dart')) {
          fileName = '../web/WebSocketChatClient.html';
        }
        else { fileName = '../web/WebSocketChat.html';
        }
        new FileHandler().sendFile(request, response, fileName);
      }
      else if (fileName.startsWith('/chat/')){
        fileName = request.uri.path.replaceFirst('/chat/', '../web/');
        new FileHandler().sendFile(request, response, fileName);
      }
      else { new NotFoundHandler().onRequest(response);
      }
    }
    catch (err, st) {
      print('${new DateTime.now().toString()} - '
        'Http request handler error : $err.toString()');
      print(st);
    }
  }
}


class FileHandler {
  void sendFile(HttpRequest request, HttpResponse response, String fileName) {
    try {
      if (LOG_REQUESTS) {
        log('${new DateTime.now().toString()} - Requested file name : $fileName');
      }
      File file = new File(fileName);
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
        if (LOG_REQUESTS) {
          log('${new DateTime.now().toString()} - File not found: $fileName');
        }
        new NotFoundHandler().onRequest(response);
      }
    } catch (err, st) {
      print('${new DateTime.now().toString()} - File handler error : $err.toString()');
      print(st);
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

  void onRequest(HttpResponse response){
    response.statusCode = HttpStatus.NOT_FOUND;
    response.headers.set('Content-Type', 'text/html; charset=UTF-8');
    response.write(notFoundPageHtml);
    response.close();
  }
}