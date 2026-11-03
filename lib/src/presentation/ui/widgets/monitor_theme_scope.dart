import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../theme/monitor_theme.dart';

/// Wraps DevMonitor UI subtrees to completely isolate them from the host app's
/// custom fonts, text scalers (e.g. accessibility large fonts), and theme overrides.
class MonitorThemeScope extends StatelessWidget {
  final Widget child;

  /// `true` (mặc định): phóng chữ theo [MonitorTextStyle.scale] (màn dashboard).
  /// `false`: giữ 1.0x (menu nổi/overlay ngoài màn dashboard).
  final bool scaleText;

  const MonitorThemeScope({
    super.key,
    required this.child,
    this.scaleText = true,
  });

  /// Text scaler đang áp dụng cho các widget con; ngoài scope thì 1.0x.
  static TextScaler textScalerOf(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<_MonitorTextScaler>()
          ?.scaler ??
      TextScaler.noScaling;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: MonitorColors.isDarkNotifier,
      builder: (context, isDark, _) {
        final mediaQueryData =
            MediaQuery.maybeOf(context) ?? const MediaQueryData();

        // 1. Force text scaling bằng MonitorTextStyle.scale and disable bold text forcing
        final scaler =
            scaleText ? MonitorTextStyle.textScaler : TextScaler.noScaling;
        final cleanMediaQuery = mediaQueryData.copyWith(
          textScaler: scaler,
          boldText: false,
        );

        // 2. Build isolated clean theme
        final baseTheme = isDark ? ThemeData.dark() : ThemeData.light();
        final isolatedTheme = baseTheme.copyWith(
          scaffoldBackgroundColor: MonitorColors.pageBackground,
          iconTheme: const IconThemeData(applyTextScaling: false),
          primaryIconTheme: const IconThemeData(applyTextScaling: false),
          colorScheme: baseTheme.colorScheme.copyWith(
            surface: MonitorColors.surface,
            onSurface: MonitorColors.primaryText,
          ),
          textTheme: Typography.material2021(platform: defaultTargetPlatform)
              .englishLike
              .apply(
                fontFamily: null,
                bodyColor: MonitorColors.primaryText,
                displayColor: MonitorColors.primaryText,
              ),
        );

        // 3. Reset DefaultTextStyle with inherit: false to sever inheritance
        // from host app's DefaultTextStyle.merge (e.g. custom fontFamily, bold weight).
        final cleanDefaultTextStyle = TextStyle(
          inherit: false,
          color: MonitorColors.primaryText,
          fontSize: 13,
          fontWeight: FontWeight.normal,
          fontFamilyFallback: MonitorTextStyle.standardFontFallback,
          decoration: TextDecoration.none,
        );

        return MediaQuery(
          data: cleanMediaQuery,
          child: Theme(
            data: isolatedTheme,
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: _MonitorTextScaler(
                scaler: scaler,
                child: DefaultTextStyle(
                  style: cleanDefaultTextStyle,
                  child: child,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MonitorTextScaler extends InheritedWidget {
  final TextScaler scaler;

  const _MonitorTextScaler({required this.scaler, required super.child});

  @override
  bool updateShouldNotify(_MonitorTextScaler old) => old.scaler != scaler;
}
