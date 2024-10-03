import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_onscreen_logger/onscreen_logger.dart';
import 'package:word_generator/word_generator.dart';

void main() {
  runZonedGuarded(() {
    WidgetsFlutterBinding.ensureInitialized();
    OnscreenLogger.init();

    runApp(const MyApp());
  }, (error, stack) {
    OnscreenLogger.onError();
  });
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
          LoggerOverlayWidget(),
        ],
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Future<void> _generateRandomLogItems({int numberOfItems = 20}) async {
    for (int i = 0; i < numberOfItems; i++) {
      await Future.delayed(
        const Duration(
          milliseconds: 800,
        ),
      );
      OnscreenLogger.log(_getRandomItem());
    }
  }

  LogItem _getRandomItem() {
    final wordGenerator = WordGenerator();

    Random random = Random();
    return LogItem(
      type: LogItemType.values[random.nextInt(LogItemType.values.length)],
      title: wordGenerator.randomSentence(random.nextInt(5) + 5),
      description: wordGenerator.randomSentence(random.nextInt(50) + 50),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            _generateRandomLogItems(numberOfItems: 10);
          },
          child: const Text('Generate Example Log Messages'),
        ),
      ),
    );
  }
}
