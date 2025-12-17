import 'package:flutter/material.dart';

class ResponsiveUtils {
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1200;
  static const double largeDesktopBreakpoint = 1600;

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < mobileBreakpoint;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= mobileBreakpoint &&
      MediaQuery.of(context).size.width < desktopBreakpoint;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= desktopBreakpoint;

  static bool isLargeDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= largeDesktopBreakpoint;

  static double getContentPadding(BuildContext context) {
    if (isMobile(context)) return 16.0;
    if (isTablet(context)) return 20.0;
    if (isLargeDesktop(context)) return 32.0;
    return 24.0;
  }

  static double getCardPadding(BuildContext context) {
    if (isMobile(context)) return 12.0;
    if (isTablet(context)) return 16.0;
    return 20.0;
  }

  static double getFontSize(
    BuildContext context, {
    required double mobile,
    required double tablet,
    required double desktop,
  }) {
    if (isMobile(context)) return mobile;
    if (isTablet(context)) return tablet;
    return desktop;
  }

  static int getGridColumns(
    BuildContext context, {
    int mobile = 1,
    int tablet = 2,
    int desktop = 3,
    int largeDesktop = 4,
  }) {
    if (isMobile(context)) return mobile;
    if (isTablet(context)) return tablet;
    if (isLargeDesktop(context)) return largeDesktop;
    return desktop;
  }

  static double getSidebarWidth(BuildContext context,
      {required bool isExpanded}) {
    if (isMobile(context))
      return MediaQuery.of(context).size.width * 0.75; // 75% width on mobile
    if (isExpanded) {
      if (isTablet(context)) return 240;
      return 280;
    }
    return 80;
  }

  static bool shouldShowSidebar(BuildContext context) {
    return !isMobile(context);
  }

  static bool shouldAutoCollapseSidebar(BuildContext context) {
    return isTablet(context);
  }

  static double getIconSize(BuildContext context,
      {double mobile = 20, double tablet = 22, double desktop = 24}) {
    if (isMobile(context)) return mobile;
    if (isTablet(context)) return tablet;
    return desktop;
  }

  static double getSpacing(BuildContext context,
      {double mobile = 12, double tablet = 16, double desktop = 20}) {
    if (isMobile(context)) return mobile;
    if (isTablet(context)) return tablet;
    return desktop;
  }

  static EdgeInsets getScreenPadding(BuildContext context) {
    final padding = getContentPadding(context);
    return EdgeInsets.all(padding);
  }

  static double getMaxWidth(BuildContext context) {
    if (isLargeDesktop(context)) return 1400;
    if (isDesktop(context)) return 1200;
    return double.infinity;
  }

  static SliverGridDelegate getGridDelegate(
    BuildContext context, {
    int? mobileColumns,
    int? tabletColumns,
    int? desktopColumns,
    double? childAspectRatio,
    double? crossAxisSpacing,
    double? mainAxisSpacing,
  }) {
    final columns = getGridColumns(
      context,
      mobile: mobileColumns ?? 1,
      tablet: tabletColumns ?? 2,
      desktop: desktopColumns ?? 3,
    );

    return SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: columns,
      childAspectRatio: childAspectRatio ?? 1.0,
      crossAxisSpacing: crossAxisSpacing ?? 16,
      mainAxisSpacing: mainAxisSpacing ?? 16,
    );
  }
}

class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, BoxConstraints constraints)
      mobile;
  final Widget Function(BuildContext context, BoxConstraints constraints)?
      tablet;
  final Widget Function(BuildContext context, BoxConstraints constraints)?
      desktop;

  const ResponsiveBuilder({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (ResponsiveUtils.isDesktop(context) && desktop != null) {
          return desktop!(context, constraints);
        }
        if (ResponsiveUtils.isTablet(context) && tablet != null) {
          return tablet!(context, constraints);
        }
        return mobile(context, constraints);
      },
    );
  }
}
