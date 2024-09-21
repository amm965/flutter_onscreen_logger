import 'package:dio/dio.dart';

import '../data/log_item_model.dart';
import '../data/log_item_type.dart';

extension DioExceptionLoggerExtension on DioException {
  LogItem getDebugItem() {
    late String title;
    late String body;
    if (response != null) {
      title = 'Dio Exception (Status code ${response!.statusCode})';
      body = '''
* Response Data: \n ${response!.data}
\n* Response Headers: \n ${response!.headers}
\n* Request Options: \n ${response!.requestOptions.data.toString()}
\n* Real URI: \n ${response!.realUri}''';
    } else {
      title = 'Dio Exception';

      body = '''
*** Invalid Response ***
* Request Options: \n ${requestOptions.data.toString()}
\n* Message: \n $message
\n* Stack Trace: \n $stackTrace
      ''';
    }

    return LogItem(
      type: LogItemType.error,
      title: title,
      description: body,
    );
  }
}
