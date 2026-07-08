import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../data/services/app_version_service.dart';
import '../../../routes/app_routes.dart';

/// Re-checks the cached app-version result every time a gated route is
/// entered. The redirect itself MUST be synchronous (Get's contract), so
/// we only ever read [AppVersionService.lastResult] here. To keep that
/// cache reasonably fresh after a long-running session, we kick off a
/// fire-and-forget refresh in the background — its result will be picked
/// up by the next redirect call.
class ForceUpdateMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    final r = AppVersionService.instance.lastResult;

    // Fire-and-forget; do NOT await. We're inside a synchronous redirect
    // hook. If the call is still in flight from a previous navigation,
    // package_info + http will dedupe on their own — calling .check()
    // twice in a row is cheap.
    AppVersionService.instance.check();

    if (r != null && r.status == AppVersionStatus.forceUpdateRequired) {
      return RouteSettings(name: AppRoutes.forceUpdate, arguments: r);
    }
    return null;
  }
}
