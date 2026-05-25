import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'constants.dart';

extension ContextExtensions on BuildContext {
  double get screenWidth => MediaQuery.of(this).size.width;
  bool get isWearable => screenWidth <= AppConstants.wearableBreakpoint;
  bool get isMobile => screenWidth <= AppConstants.tabletBreakpoint;
  bool get isDesktop => screenWidth > AppConstants.tabletBreakpoint;
}

String formatDate(DateTime date) {
  return DateFormat('dd MMM yyyy', 'es').format(date.toLocal());
}

String formatDateShort(DateTime date) {
  return DateFormat('dd/MM/yy').format(date.toLocal());
}

String formatDateRelative(DateTime date) {
  final now = DateTime.now();
  final diff = now.difference(date.toLocal());
  if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
  if (diff.inHours < 24) return 'Hace ${diff.inHours}h';
  if (diff.inDays < 7) return 'Hace ${diff.inDays}d';
  return formatDate(date);
}
