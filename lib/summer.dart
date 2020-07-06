import 'dart:convert';
import 'dart:io';
import 'dart:mirrors';

import 'package:quiver_log/log.dart';
import 'package:logging/logging.dart';

class SimpleStringFormatter implements FormatterBase<String> {
  @override
  String call(LogRecord record) {
    return "${record.time} ${record}";
  }
}

const Controller = "Controller";

class GetMapping {
  final String route;

  const GetMapping([this.route]);
}

class PostMapping {
  final String route;

  const PostMapping([this.route]);
}

const RequestBody = "RequestBody";

// ===================== Main Class ======================

class Summer {
  static var controllers = [];

  static Map getDeclarations() {
    final mirrors = currentMirrorSystem();

    var finalMap = {};

    mirrors.isolate.rootLibrary.declarations.forEach((key, value) {
      finalMap[key] = value;
    });

    mirrors.isolate.rootLibrary.libraryDependencies.forEach((element) {
      element.targetLibrary.declarations.forEach((key, value) {
        finalMap[key] = value;
      });
    });

    return finalMap;
  }

  static bool isController(item) {
    if (item.metadata.length == 0) {
      return false;
    }

    for (var i in item.metadata) {
      if (i.reflectee == "Controller") {
        return true;
      }
    }

    return false;
  }

  static Object isSummerMapping(item) {
    if (item.metadata.length == 0) {
      return null;
    }

    for (var i in item.metadata) {
      if (i.reflectee is GetMapping) {
        return i.reflectee;
      }

      if (i.reflectee is PostMapping) {
        return i.reflectee;
      }
    }

    return null;
  }

  // static PostMapping isPostMapping(item) {
  //   if (item.metadata.length == 0) {
  //     return null;
  //   }

  //   for (var i in item.metadata) {
  //     if (i.reflectee is PostMapping) {
  //       return i.reflectee;
  //     }
  //   }

  //   return null;
  // }

  static void loadControllers() {
    getDeclarations().forEach((k, v) {
      if (!isController(v)) {
        return;
      }

      controllers.add(v.newInstance(Symbol(''), []).reflectee);
    });
  }

  static _handleGetRequest(HttpRequest request) {}

  static _findRequestBodyFields(ref) {
    print(ref);
  }

  static void runWebServer({String host = "localhost", int port = 4040}) async {
    var logger = Logger("SummerLogger");

    var appender = PrintAppender(SimpleStringFormatter());

    appender.attachLogger(logger);

    var server = await HttpServer.bind(
      host,
      port,
    );

    print("Listening on $host:$port");

    var routePaths = {};
    var controllerPaths = {};

    for (var controller in controllers) {
      var ref = reflect(controller).type;

      ref.declarations.forEach((k, v) {
        final sm = isSummerMapping(v);

        if (sm == null) {
          return;
        }

        if (sm is GetMapping) {
          routePaths["GET " + sm.route] = v;
          controllerPaths["GET " + sm.route] = controller;
        }

        if (sm is PostMapping) {
          routePaths["POST " + sm.route] = v;
          controllerPaths["POST " + sm.route] = controller;
        }
      });
    }

    print(routePaths);
    print(controllerPaths);

    await for (HttpRequest request in server) {
      logger.info("${request.method} ${request.uri.path}");

      if (!routePaths.containsKey(request.method + " " + request.uri.path)) {
        request.response.write("Route not found.");

        await request.response.close();

        continue;
      }

      // request.response.write(routePaths[request.uri.path].call([]));

      print(request.method + " " + request.uri.path);

      var ref =
          reflect(controllerPaths[request.method + " " + request.uri.path]);

      String content = null;

      if (request.method == "POST") {
        content = await utf8.decoder.bind(request).join();

        var fields = _findRequestBodyFields(ref);
      }

      var data;

      if (content == null) {
        data = ref.invoke(
          routePaths[request.method + " " + request.uri.path].simpleName,
          [],
        ).reflectee;
      } else {
        data = ref.invoke(
          routePaths[request.method + " " + request.uri.path].simpleName,
          [content],
        ).reflectee;
      }

      // Convert classes to JSON here. (Do not convert for string, and other basic types.)

      var output;

      try {
        if (data is Map) {
          output = json.encode(data);
        } else {
          output = data.toJson();
        }

        request.response.headers
            .add(HttpHeaders.contentTypeHeader, "application/json");
      } catch (e) {
        output = data;
      }

      request.response.write(output);

      await request.response.close();
    }
  }

  static void run({String host = "localhost", int port = 4040}) {
    loadControllers();

    runWebServer(host = host, port = port);
  }
}
