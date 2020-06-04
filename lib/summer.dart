import 'dart:io';
import 'dart:mirrors';

const Controller = "Controller";

class GetMapping {
  final String route;

  const GetMapping([this.route]);
}

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

  static GetMapping isGetMapping(item) {
    if (item.metadata.length == 0) {
      return null;
    }

    for (var i in item.metadata) {
      print(i);

      if (i.reflectee is GetMapping) {
        return i.reflectee;
      }
    }

    return null;
  }

  static void loadControllers() {
    getDeclarations().forEach((k, v) {
      if (!isController(v)) {
        return;
      }

      controllers.add(v.newInstance(Symbol(''), []).reflectee);
    });
  }

  static void runWebServer() async {
    var server = await HttpServer.bind(
      InternetAddress.loopbackIPv4,
      4040,
    );

    print("Listening on localhost:4040");

    var routePaths = {};
    var controllerPaths = {};

    for (var controller in controllers) {
      var ref = reflect(controller).type;

      ref.declarations.forEach((k, v) {
        final gm = isGetMapping(v);

        if (gm == null) {
          return;
        }

        routePaths[gm.route] = v;
        controllerPaths[gm.route] = controller;
      });
    }

    await for (HttpRequest request in server) {
      print(request.method);
      print(request.uri.path);

      if (!routePaths.containsKey(request.uri.path)) {
        request.response.write("Route not found.");

        await request.response.close();

        continue;
      }

      // request.response.write(routePaths[request.uri.path].call([]));

      var ref = reflect(controllerPaths[request.uri.path]);

      var data =
          ref.invoke(routePaths[request.uri.path].simpleName, []).reflectee;

      request.response.write(data);

      await request.response.close();
    }
  }

  static void run() {
    loadControllers();

    runWebServer();
  }
}
