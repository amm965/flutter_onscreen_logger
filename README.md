# Lexzur On-Screen Logger

A Flutter package that allows you to display logs on the screen of your app for easier debugging.

## Features

- Log exceptions and errors in a user-friendly way.
- Easily integrate with Dio for HTTP request logging.
- Simple API for logging custom messages.
- Customizable display options for logs.

## Getting Started

1. Add the package to your `pubspec.yaml` file:

    ```yaml
    dependencies:
      lexzur_onscreen_logger:
        path: ../onscreen_logger
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

   - wrap your `MaterialApp()` widget with a `Stack()`
   - add `LogOverlayWidget()` widget below it
   - Note: you can add a condition here to show/hide the on-screen logger based on your use cases

   ```dart
   Stack(
      children: [
        MaterialApp(
          //...other material app properties...
          home: MyHomePage(title: 'MyApp'),
        ),
        if (BuildConfig.showOnScreenLogger) LogOverlayWidget(),
      ],
    ),
   ```

## Usage

You can use the on-screen logger to log your own custom message through out your project

   ```dart
   OnscreenLogger.log(
         LogItem(
           type: logItemType,
           title: 'API Response Received',
           description: '''* API Response:\n$data'''),
       );
   ```
   
