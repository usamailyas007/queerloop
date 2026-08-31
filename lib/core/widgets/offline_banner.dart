import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../network/network_info.dart';
import '../theme/app_colors.dart';

/// Non-intrusive offline status banner shown when the device loses network connectivity.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Expanded(child: child),
        Selector<NetworkInfo, bool>(
          selector: (_, NetworkInfo n) => n.isOffline,
          builder: (BuildContext context, bool isOffline, _) {
            return AnimatedCrossFade(
              duration: const Duration(milliseconds: 300),
              crossFadeState: isOffline
                  ? CrossFadeState.showFirst
                  : CrossFadeState.showSecond,
              firstChild: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                color: AppColors.danger.withValues(alpha: 0.95),
                child: const SafeArea(
                  top: false,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Icon(
                        Icons.wifi_off_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'No internet connection · Offline mode',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              secondChild: const SizedBox.shrink(),
            );
          },
        ),
      ],
    );
  }
}
