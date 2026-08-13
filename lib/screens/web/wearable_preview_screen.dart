import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../wearable/wearable_news_list_screen.dart';
import '../wearable/wearable_news_detail_screen.dart';

/// Marks the subtree that lives inside the smartwatch frame of
/// [WearablePreviewScreen]. The wearable screens are shared with the real
/// Wear OS build, so they consult this to decide whether to navigate with
/// the app-wide [GoRouter] (real device) or with the frame's own nested
/// [Navigator] (preview) — otherwise a tap inside the watch would replace
/// the whole web page.
class WearablePreviewScope extends InheritedWidget {
  const WearablePreviewScope({super.key, required super.child});

  static bool isActive(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<WearablePreviewScope>() != null;

  @override
  bool updateShouldNotify(WearablePreviewScope oldWidget) => false;
}

/// Public page (`/wearable`) that renders the real wearable UI inside a
/// smartwatch mockup, so the watch experience is reachable — and
/// demonstrable — from a desktop browser without a physical device.
class WearablePreviewScreen extends StatelessWidget {
  const WearablePreviewScreen({super.key});

  /// Logical size of the watch screen. Must stay at or below
  /// [AppConstants.wearableBreakpoint] so that `context.isWearable` is true
  /// inside the frame and the wearable layouts are the ones that render.
  static const double _screenSize = 300;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vista de smartwatch'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Volver al sitio',
          onPressed: () => context.canPop() ? context.pop() : context.go('/news'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
        child: Column(
          children: [
            const _PreviewHeader(),
            const SizedBox(height: 28),
            const _WatchFrame(screenSize: _screenSize),
            const SizedBox(height: 28),
            const Text(
              'Esta es la misma interfaz que se compila para Wear OS: '
              'la aplicación detecta el dispositivo y sustituye las pantallas '
              'web por su equivalente para reloj.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewHeader extends StatelessWidget {
  const _PreviewHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Icon(Icons.watch, color: AppTheme.primary, size: 34),
        const SizedBox(height: 10),
        const Text(
          'TechNews en tu smartwatch',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        const Text(
          'Desliza dentro del reloj para navegar. Toca una noticia para abrirla.',
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

/// Round smartwatch bezel with a nested [Navigator] inside, so pushes and
/// pops stay within the watch screen instead of navigating the host page.
class _WatchFrame extends StatelessWidget {
  final double screenSize;

  const _WatchFrame({required this.screenSize});

  @override
  Widget build(BuildContext context) {
    // The watch screen advertises its own MediaQuery so that the wearable
    // breakpoint (and therefore `context.isWearable`) is evaluated against
    // the frame, not the browser window.
    final watchMediaQuery = MediaQuery.of(context).copyWith(
      size: Size(screenSize, screenSize),
      padding: EdgeInsets.zero,
      viewPadding: EdgeInsets.zero,
      viewInsets: EdgeInsets.zero,
      textScaler: const TextScaler.linear(1),
    );

    return Center(
      child: Container(
        width: screenSize + 24,
        height: screenSize + 24,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF15171A),
          border: Border.all(color: AppTheme.divider, width: 2),
          boxShadow: const [
            BoxShadow(color: Colors.black54, blurRadius: 24, offset: Offset(0, 10)),
          ],
        ),
        alignment: Alignment.center,
        child: ClipOval(
          child: SizedBox(
            width: screenSize,
            height: screenSize,
            child: MediaQuery(
              data: watchMediaQuery,
              child: WearablePreviewScope(
                child: Navigator(
                  onGenerateRoute: (settings) => MaterialPageRoute<void>(
                    settings: settings,
                    builder: (_) => const WearableNewsListScreen(),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Opens an article from a wearable list, using the nested navigator when
/// running inside [WearablePreviewScreen] and the app router otherwise.
Future<void> openWearableNewsDetail(BuildContext context, int newsId) {
  if (WearablePreviewScope.isActive(context)) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => WearableNewsDetailScreen(newsId: newsId)),
    );
  }
  return context.push('/news/$newsId');
}

/// Counterpart of [openWearableNewsDetail] for the back button.
void closeWearableNewsDetail(BuildContext context) {
  if (WearablePreviewScope.isActive(context)) {
    Navigator.of(context).pop();
    return;
  }
  context.pop();
}
