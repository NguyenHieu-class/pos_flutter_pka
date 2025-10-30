import 'package:flutter/material.dart';

/// Global navigator key so services (e.g. AuthService) can trigger
/// navigation actions without a BuildContext.
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();
