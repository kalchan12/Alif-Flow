import 'package:flutter/material.dart';

class ResponsiveLayout extends StatelessWidget {
  final Widget mobileBody;
  final Widget? tabletBody;
  final Widget? desktopBody;

  const ResponsiveLayout({
    super.key,
    required this.mobileBody,
    this.tabletBody,
    this.desktopBody,
  });

  // Breakpoints
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 1100;

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < mobileBreakpoint;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= mobileBreakpoint &&
      MediaQuery.of(context).size.width < tabletBreakpoint;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= tabletBreakpoint;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= tabletBreakpoint) {
          return desktopBody ?? tabletBody ?? mobileBody;
        } else if (constraints.maxWidth >= mobileBreakpoint) {
          return tabletBody ?? mobileBody;
        } else {
          return mobileBody;
        }
      },
    );
  }
}
