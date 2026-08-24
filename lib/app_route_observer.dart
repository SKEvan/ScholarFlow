import 'package:flutter/material.dart';

/// Route observer used by [DashboardScreen] to refresh its project list when
/// a route pushed on top of it (e.g. the invitations inbox) pops back. The
/// observer is registered in `main.dart` via `MaterialApp.navigatorObservers`.
final RouteObserver<PageRoute<dynamic>> dashboardRouteObserver =
    RouteObserver<PageRoute<dynamic>>();
