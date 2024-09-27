# Flutter On-Screen Logger

[![Pub Package](https://img.shields.io/badge/pub-v1.1.7-blue)](https://pub.dev/packages/flutter_onscreen_logger)
[![Pub Package](https://img.shields.io/badge/flutter-%3E%3D1.17.0-green)](https://flutter.dev/)
[![GitHub Repo stars](https://img.shields.io/github/stars/amm965/flutter_onscreen_logger?style=social)](https://github.com/amm965/flutter_onscreen_logger)


A Flutter package that allows you to display logs on the screen of your app for easier debugging.

![flutteer onscreen logger](https://github.com/user-attachments/assets/c6cb07fa-313f-4a73-bd71-3837fb201f85)

## Features

- Log exceptions and errors in a user-friendly way.
- Easily integrate with Dio for HTTP request logging.
- Simple API for logging custom messages.
- Customizable display options for logs.

## Getting Started

1. Add the package to your `pubspec.yaml` file:

    ```yaml
    dependencies:
      flutter_onscreen_logger: ^1.0.0
    ```

2. Configure your `main.dart` to integrate the library:

   - wrap your `runApp()` method in main with `runZonedGuarded()`
   - in the `body` function initialize the logger by calling `OnscreenLogger.init();`
   - in the `onError()` function call logger's `onError()` method

    ```dart
    main() {
      runZonedGuarded(() async {
        WidgetsFlutterBinding.ensureInitialized();

        OnscreenLogger.init();

        //...other code...
        
        runApp(MyApp());
      }, (error, stack) {
        OnscreenLogger.onError();
      });
    }
    ```

   - wrap your `MaterialApp()` widget with a `Stack()` and 
   - add `LogOverlayWidget()` widget below it
   - Note: you can add a condition here to show/hide the on-screen logger based on your use cases

   ```dart
   Directionality(
      textDirection: TextDirection.ltr, 
      child: Stack(
          children: [
            MaterialApp(
              //...other material app properties...
              home: MyHomePage(title: 'MyApp'),
            ),
            if (BuildConfig.showOnScreenLogger) LoggerOverlayWidget(),
          ],
        ),
    );
   ```

## Usage

You can use the on-screen logger to log your own custom message through out your project

   ```dart
   OnscreenLogger.log(
         LogItem(
           type: LogItemType.info,
           title: 'API Response Received',
           description: '''* API Response:\n$data'''),
       );
   ```
   
