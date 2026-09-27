import 'package:flutter/material.dart';

/// Global navigator key used for context-free navigation
/// (e.g. from push notification handlers, background isolates).
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// Thin wrapper around the global [navigatorKey] that lets any service
/// push routes without holding a [BuildContext].
abstract final class NavigationService {
  static NavigatorState? get _nav => navigatorKey.currentState;

  /// Push a named route.
  static Future<T?> pushNamed<T>(String routeName, {Object? arguments}) =>
      _nav!.pushNamed<T>(routeName, arguments: arguments);

  /// Push a widget route built from a [WidgetBuilder].
  static Future<T?> push<T>(WidgetBuilder builder) =>
      _nav!.push<T>(MaterialPageRoute<T>(builder: builder));
}
