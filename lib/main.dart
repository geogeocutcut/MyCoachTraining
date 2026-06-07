// lib/main.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'services/data_store.dart';
import 'services/session_io_service.dart';
import 'services/workout_notification_service.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await WorkoutNotificationService.init();
  final store = DataStore();
  await store.load();
  runApp(
    ChangeNotifierProvider.value(
      value: store,
      child: const MyCoachTrainingApp(),
    ),
  );
}

class MyCoachTrainingApp extends StatefulWidget {
  const MyCoachTrainingApp({super.key});

  @override
  State<MyCoachTrainingApp> createState() => _MyCoachTrainingAppState();
}

class _MyCoachTrainingAppState extends State<MyCoachTrainingApp> {
  StreamSubscription? _linkSub;
  Uri? _pendingUri;

  @override
  void initState() {
    super.initState();

    // Use AppLinks in "string" mode to avoid Flutter route dispatch
    final appLinks = AppLinks();

    appLinks.getInitialLink().then((uri) {
      if (uri == null) return;
      _pendingUri = uri;
    });

    _linkSub = appLinks.uriLinkStream.listen((uri) {
      _processMctUri(uri);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_pendingUri != null) {
        _processMctUri(_pendingUri!);
        _pendingUri = null;
      }
    });
  }

  @override
  void dispose() {
    _linkSub?.cancel();
    super.dispose();
  }

  void _processMctUri(Uri uri) {
    final uriStr = uri.toString();
    debugPrint('MCT >>> processMctUri: $uriStr');
    // Accept .mct extension OR octet-stream mime (WhatsApp uses content URI without extension)
    _importFromUri(uri);
  }

  Future<void> _importFromUri(Uri uri) async {
    // navigatorKey.currentContext is above the Provider — use overlay context instead
    final ctx = navigatorKey.currentState?.overlay?.context;
    debugPrint('MCT >>> importFromUri: ${uri.scheme} / $uri');
    debugPrint('MCT >>> context available: ${ctx != null}');
    if (ctx == null) {
      debugPrint('MCT >>> context null, retrying after frame');
      WidgetsBinding.instance.addPostFrameCallback((_) => _importFromUri(uri));
      return;
    }

    try {
      String content;

      if (uri.scheme == 'content') {
        const channel = MethodChannel('com.example.MyCoachTraining/file');
        final bytes = await channel.invokeMethod<Uint8List>(
          'readUri', {'uri': uri.toString()},
        );
        debugPrint('MCT >>> bytes received: ${bytes?.length ?? 'null'}');
        if (bytes == null) {
          debugPrint('MCT >>> readUri: null bytes');
          return;
        }
        content = utf8.decode(bytes);
        debugPrint('MCT >>> content length: ${content.length}');
      } else if (uri.scheme == 'file') {
        content = await File(uri.toFilePath()).readAsString();
      } else {
        debugPrint('Unhandled scheme: ${uri.scheme}');
        return;
      }

      // Verify it looks like a .mct file before importing
      debugPrint('MCT >>> content preview: ${content.substring(0, content.length.clamp(0, 100))}');
      if (!content.trimLeft().startsWith('{')) {
        debugPrint('MCT >>> Not a valid .mct file');
        return;
      }

      debugPrint('MCT >>> calling importFromString...');
      DataStore store;
      try {
        // ignore: use_build_context_synchronously
        store = ctx.read<DataStore>();
        debugPrint('MCT >>> store ok, sessions: ${store.sessions.length}');
      } catch (e, stack) {
        debugPrint('MCT >>> read<DataStore> FAILED: $e\n$stack');
        return;
      }
      try {
        // ignore: use_build_context_synchronously
        await SessionIOService.importFromString(ctx, content, store);
        debugPrint('MCT >>> importFromString done');
      } catch (e, stack) {
        debugPrint('MCT >>> importFromString FAILED: $e\n$stack');
      }
    } catch (e, stack) {
      debugPrint('_importFromUri outer error: $e\n$stack');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MyCoachTraining',
      navigatorKey: navigatorKey,
      theme: buildAppTheme(),
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
      // Prevent app_links from pushing content URIs as Flutter routes
      onGenerateRoute: (settings) {
        // Only "/" is a valid internal route — everything else is ignored
        if (settings.name == '/') {
          return MaterialPageRoute(builder: (_) => const SplashScreen());
        }
        return null;
      },
      onUnknownRoute: (settings) {
        // Silently swallow unknown routes (e.g. content:// URIs from app_links)
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      },
    );
  }
}