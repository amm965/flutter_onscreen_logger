import 'package:flutter/material.dart';

import '../data/log_item_type.dart';

extension LogItemTypeExtension on LogItemType {
  Color get itemColorByType {
    switch (this) {
      case LogItemType.info:
        return Colors.white;
      case LogItemType.warning:
        return Colors.amber;
      case LogItemType.error:
        return Colors.red;
      case LogItemType.success:
        return Colors.green;
    }
  }
}
