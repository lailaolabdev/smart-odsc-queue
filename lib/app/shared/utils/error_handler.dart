import 'dart:async';
import 'dart:io';

class ErrorHandler {
  ErrorHandler._();

  static String getMessage(Object e) {
    if (e is SocketException) {
      return 'ບໍ່ມີການເຊື່ອມຕໍ່ອິນເຕີເນັດ';
    }

    if (e is TimeoutException) {
      return 'ການຮ້ອງຂໍໝົດເວລາ ກະລຸນາລອງໃໝ່';
    }

    if (e is HttpException) {
      return 'ເກີດຂໍ້ຜິດພາດຈາກເຊີເວີ: ${e.message}';
    }

    if (e is FormatException) {
      return 'ຮູບແບບຂໍ້ມູນບໍ່ຖືກຕ້ອງ';
    }

    if (e is TypeError) {
      return 'ຂໍ້ມູນບໍ່ຖືກຕ້ອງ';
    }

    if (e is RangeError) {
      return 'ຂໍ້ມູນຢູ່ນອກຂອບເຂດ';
    }

    if (e is ArgumentError) {
      return 'ຄ່າທີ່ສົ່ງມາບໍ່ຖືກຕ້ອງ';
    }

    if (e is StateError) {
      return 'ສະຖານະຂໍ້ມູນຜິດພາດ';
    }

    if (e is UnsupportedError) {
      return 'ການດຳເນີນງານນີ້ບໍ່ຮອງຮັບ';
    }

    if (e is Exception) {
      final msg = e.toString();
      final cleaned = msg.startsWith('Exception: ')
          ? msg.substring('Exception: '.length)
          : msg;
      if (cleaned.isNotEmpty) return cleaned;
    }

    final statusMessage = _fromStatusCode(e.toString());
    if (statusMessage != null) return statusMessage;

    return 'ເກີດຂໍ້ຜິດພາດທີ່ບໍ່ຄາດຄິດ ກະລຸນາລອງໃໝ່';
  }

  static String getHttpMessage(int statusCode) {
    return _fromStatusCode(statusCode.toString()) ??
        'ເກີດຂໍ້ຜິດພາດ (HTTP $statusCode)';
  }

  static String? _fromStatusCode(String raw) {
    final trimmed = raw.trim();
    switch (trimmed) {
      case '400':
        return 'ຄຳຮ້ອງຂໍຂໍ້ມູນບໍ່ຖືກຕ້ອງ (400)';
      case '401':
        return 'ກະລຸນາເຂົ້າສູ່ລະບົບໃໝ່ (401)';
      case '403':
        return 'ທ່ານບໍ່ມີສິດໃນການດຳເນີນງານນີ້ (403)';
      case '404':
        return 'ບໍ່ພົບຂໍ້ມູນທີ່ຕ້ອງການ (404)';
      case '409':
        return 'ຂໍ້ມູນຊ້ຳກັນ ກະລຸນາກວດສອບ (409)';
      case '422':
        return 'ຂໍ້ມູນທີ່ສົ່ງໄປບໍ່ຖືກຕ້ອງ (422)';
      case '429':
        return 'ທ່ານຮ້ອງຂໍຫຼາຍເກີນໄປ ກະລຸນາລໍຖ້າ (429)';
      case '500':
        return 'ເຊີເວີເກີดຂໍ້ຜິດພາດ ກະລຸນາລອງໃໝ່ (500)';
      case '502':
      case '503':
      case '504':
        return 'ເຊີເວີບໍ່ສາມາດໃຫ້ບໍລິການໄດ້ຊົ່ວຄາວ ກະລຸນาລອງໃໝ່';
      default:
        return null;
    }
  }
}
