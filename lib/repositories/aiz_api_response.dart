import 'package:haxuvina/middlewares/group_middleware.dart';
import 'package:haxuvina/middlewares/maintenance.dart';
import 'package:haxuvina/middlewares/middleware.dart';
import 'package:http/http.dart' as http;

class AIZApiResponse {
  static http.Response check(http.Response response,
      {Middleware? middleware, GroupMiddleware? groupMiddleWare}) {
    _commonCheck(response);
    if (middleware != null) {
      middleware.next(response);
    }
    if (groupMiddleWare != null) {
      groupMiddleWare.next(response);
    }
    return response;
  }

  static _commonCheck(http.Response response) {
    MaintenanceMiddleware().next(response);
  }
}
