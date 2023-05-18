import 'package:shelf_plus/shelf_plus.dart';

import 'authentication_helper.dart';

getMiddleware() {
  return createMiddleware(requestHandler: (Request request) async {
    print('Entering auth middleware for request ${request.url}');
    // Allow login
    if (request.url.toString().startsWith('login')) {
      return await AuthenticationHelper.checkSimpleAuthentication(request);
    } /* else if (request.url.toString() == 'register') {
      print('Into register from auth');
      //RegisterController.handle(request);
    } */
    else {
      // Use bearer authentication
      return await AuthenticationHelper.checkBearerAuthentication(request);
    }
  });
}
