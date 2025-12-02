import 'package:intl/intl.dart';

class Format {
  static String currency(num number) {
    final formatter = NumberFormat('#,###');
    return "${formatter.format(number)} đ";
  }

  static String dateTime(DateTime dt) {
    return DateFormat("dd/MM/yyyy HH:mm").format(dt);
  }

  static String date(DateTime dt) {
    return DateFormat("dd/MM/yyyy").format(dt);
  }
}
