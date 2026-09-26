import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_onscreen_logger/flutter_onscreen_logger.dart';
import 'package:word_generator/word_generator.dart';

import 'network_demos.dart';

const _loggerOverlayEnabled = bool.fromEnvironment(
  'LOGGER_OVERLAY_ENABLED',
  defaultValue: kDebugMode,
);

void main() {
  runZonedGuarded(
    () {
      WidgetsFlutterBinding.ensureInitialized();
      OnScreenLog.init(
        enabled: const bool.fromEnvironment(
          'LOGGING_ENABLED',
          defaultValue: true,
        ),
        enabledTypes: const {
          LogItemType.info,
          LogItemType.success,
          LogItemType.warning,
          LogItemType.error,
        },
        autoScroll: const bool.fromEnvironment(
          'LOGGER_AUTO_SCROLL',
          defaultValue: true,
        ),
      );
      OnScreenLog.onError();

      runApp(const MyApp());
    },
    (error, stack) {
      OnScreenLog.e(title: error.toString(), message: stack.toString());
    },
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
        children: [
          MaterialApp(
            title: 'Flutter Demo',
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
              useMaterial3: true,
            ),
            home: const MyHomePage(title: 'Flutter Demo Home Page'),
          ),
          if (_loggerOverlayEnabled) LoggerOverlayWidget(),
        ],
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title, this.networkClients});

  final DemoNetworkClients? networkClients;

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late final DemoNetworkClients _networkClients =
      widget.networkClients ?? DemoNetworkClients();
  bool _requestInProgress = false;

  Future<void> _runNetworkDemo(Future<String> Function() demo) async {
    setState(() => _requestInProgress = true);
    try {
      final message = await demo();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Request failed. Check your connection and the logger.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _requestInProgress = false);
    }
  }

  @override
  void dispose() {
    _networkClients.close();
    super.dispose();
  }

  ///A method that will generate few random log items with different types
  Future<void> _generateRandomLogItems({int numberOfItems = 20}) async {
    final wordGenerator = WordGenerator();
    for (int i = 0; i < numberOfItems; i++) {
      Random random = Random();
      await Future.delayed(const Duration(milliseconds: 800));
      if (!mounted) return;
      switch (i % 4) {
        case 0:
          {
            ///adds info log message
            OnScreenLog.i(
              title: wordGenerator.randomSentence(random.nextInt(5) + 5),
              message: wordGenerator.randomSentence(random.nextInt(50) + 50),
            );
          }
        case 1:
          {
            ///adds error log message
            OnScreenLog.e(
              title: wordGenerator.randomSentence(random.nextInt(5) + 5),
              message: wordGenerator.randomSentence(random.nextInt(50) + 50),
            );
          }
        case 2:
          {
            ///adds warning log message
            OnScreenLog.w(
              title: wordGenerator.randomSentence(random.nextInt(5) + 5),
              message: wordGenerator.randomSentence(random.nextInt(50) + 50),
            );
          }
        case 3:
          {
            ///adds success log message
            OnScreenLog.s(
              title: wordGenerator.randomSentence(random.nextInt(5) + 5),
              message: wordGenerator.randomSentence(random.nextInt(50) + 50),
            );
          }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton(
                onPressed: () => _generateRandomLogItems(numberOfItems: 10),
                child: const Text('Generate Test Log Messages'),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _requestInProgress
                    ? null
                    : () => _runNetworkDemo(_networkClients.runDioDemo),
                icon: const Icon(Icons.cloud_outlined),
                label: const Text('Test Dio requests'),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: _requestInProgress
                    ? null
                    : () => _runNetworkDemo(_networkClients.runHttpDemo),
                icon: const Icon(Icons.http),
                label: const Text('Test HTTP requests'),
              ),
              const SizedBox(height: 16),
              const Text(
                'Each network demo calls JSONPlaceholder for a post and a missing post (404). Open the logger to see automatic request, response, and error logs.',
                textAlign: TextAlign.center,
              ),
              if (_requestInProgress)
                const Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: CircularProgressIndicator(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
