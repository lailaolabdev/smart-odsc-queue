// Welcome / landing screen + admin chrome translations.
//
// Keys are intentionally namespaced (`welcome.*`, `common.*`, `error.*`) so
// that this map can be merged with the other module maps in
// [AppTranslations.keys] without collision.
const Map<String, String> welcomeLo = {
  'welcome.title': 'Smart ODSC',
  'welcome.subtitle': 'ຍິນດີຕ້ອນຮັບສູ່ ບໍລິການປະຕູດຽວຂອງລັດຖະບານ ສປປ ລາວ',
  'welcome.queue_button': 'ກົດບັດຄິວ',
  'welcome.feedback_button': 'ຄຳຕິຊົມ',
  'welcome.directory_button': 'ລາຍການບໍລິການ',

  'common.tap_to_select': 'ກົດເພື່ອເລືອກ',
  'common.loading': 'ກະລຸນາລໍຖ້າ...',
  'common.ok': 'OK',
  'common.error': 'ຜິດພາດ',
  'common.success': 'ສຳເລັດ',
  'common.retry': 'ລອງໃໝ່',
  'common.back': 'ກັບຄືນ',
  'common.cancel': 'ຍົກເລີກ',
  'common.confirm': 'ຢືນຢັນ',
  'common.next': 'ຕໍ່ໄປ',
  'common.done': 'ສຳເລັດ',
  'common.failed_to_load': 'ໂຫຼດບໍ່ສຳເລັດ',

  // Network / runtime errors surfaced by ErrorHandler. Keep short so they
  // fit a kiosk dialog without truncation.
  'error.no_internet': 'ບໍ່ມີການເຊື່ອມຕໍ່ອິນເຕີເນັດ',
  'error.timeout': 'ການຮ້ອງຂໍໝົດເວລາ ກະລຸນາລອງໃໝ່',
  'error.server_prefix': 'ເກີດຂໍ້ຜິດພາດຈາກເຊີເວີ',
  'error.bad_format': 'ຮູບແບບຂໍ້ມູນບໍ່ຖືກຕ້ອງ',
  'error.bad_data': 'ຂໍ້ມູນບໍ່ຖືກຕ້ອງ',
  'error.out_of_range': 'ຂໍ້ມູນຢູ່ນອກຂອບເຂດ',
  'error.bad_argument': 'ຄ່າທີ່ສົ່ງມາບໍ່ຖືກຕ້ອງ',
  'error.bad_state': 'ສະຖານະຂໍ້ມູນຜິດພາດ',
  'error.unsupported': 'ການດຳເນີນງານນີ້ບໍ່ຮອງຮັບ',
  'error.unexpected': 'ເກີດຂໍ້ຜິດພາດທີ່ບໍ່ຄາດຄິດ ກະລຸນາລອງໃໝ່',
  'error.http_generic_prefix': 'ເກີດຂໍ້ຜິດພາດ',
  'error.http_400': 'ຄຳຮ້ອງຂໍຂໍ້ມູນບໍ່ຖືກຕ້ອງ',
  'error.http_401': 'ກະລຸນາເຂົ້າສູ່ລະບົບໃໝ່',
  'error.http_403': 'ທ່ານບໍ່ມີສິດໃນການດຳເນີນງານນີ້',
  'error.http_404': 'ບໍ່ພົບຂໍ້ມູນທີ່ຕ້ອງການ',
  'error.http_409': 'ຂໍ້ມູນຊ້ຳກັນ ກະລຸນາກວດສອບ',
  'error.http_422': 'ຂໍ້ມູນທີ່ສົ່ງໄປບໍ່ຖືກຕ້ອງ',
  'error.http_429': 'ທ່ານຮ້ອງຂໍຫຼາຍເກີນໄປ ກະລຸນາລໍຖ້າ',
  'error.http_500': 'ເຊີເວີເກີດຂໍ້ຜິດພາດ ກະລຸນາລອງໃໝ່',
  'error.http_5xx': 'ເຊີເວີບໍ່ສາມາດໃຫ້ບໍລິການໄດ້ຊົ່ວຄາວ ກະລຸນາລອງໃໝ່',

  // Lower-level network errors. These used to show raw English strings
  // like "DNS failed for api.odsc.gov.la" — which kiosk operators can't
  // read or act on. Keep them in Lao and avoid leaking hostnames /
  // error codes into the dialog body (those go to the log).
  'error.tls': 'ການເຊື່ອມຕໍ່ປອດໄພລົ້ມເຫລວ ກະລຸນາກວດສອບເວລາໃນເຄື່ອງ',
  'error.dns': 'ບໍ່ສາມາດເຂົ້າເຖິງເຊີເວີ ກະລຸນາກວດສອບອິນເຕີເນັດ',
  'error.server_refused': 'ເຊີເວີປະຕິເສດການເຊື່ອມຕໍ່',
  'error.server_unreachable': 'ບໍ່ສາມາດເຂົ້າເຖິງເຊີເວີ',
  'error.server_timeout': 'ເຊີເວີຕອບສະໜອງຊ້າເກີນໄປ',
  'error.network_generic': 'ການເຊື່ອມຕໍ່ມີບັນຫາ ກະລຸນາລອງໃໝ່',

  // Login screen
  'login.title': 'ເຂົ້າສູ່ລະບົບ',
  'login.username': 'ຊື່ຜູ້ໃຊ້',
  'login.password': 'ລະຫັດຜ່ານ',
  'login.button': 'ເຂົ້າສູ່ລະບົບ',
  'login.loading': 'ກຳລັງເຂົ້າສູ່ລະບົບ...',
  'login.error.empty_fields': 'ກະລຸນາປ້ອນຊື່ຜູ້ໃຊ້ ແລະ ລະຫັດຜ່ານ',
  'login.error.failed_title': 'ເຂົ້າສູ່ລະບົບບໍ່ສຳເລັດ',
  'login.error.invalid_credentials':
      'ຊື່ຜູ້ໃຊ້ ຫຼື ລະຫັດຜ່ານບໍ່ຖືກຕ້ອງ',

  // Printer pairing screen
  'printer.error.bluetooth': 'ບໍ່ສາມາດໂຫຼດເຄື່ອງພິມ Bluetooth ໄດ້',
  'printer.error.connect_failed': 'ເຊື່ອມເຄື່ອງພິມບໍ່ສຳເລັດ',
  'printer.error.not_connected': 'ກະລຸນາເຊື່ອມເຄື່ອງພິມກ່ອນ',
  'printer.error.test_failed': 'ພິມທົດສອບບໍ່ສຳເລັດ',
  'printer.connecting': 'ກຳລັງເຊື່ອມ',
  'printer.connected': 'ເຊື່ອມເຄື່ອງພິມສຳເລັດ',
  'printer.testing': 'ກຳລັງພິມທົດສອບ...',
};

const Map<String, String> welcomeEn = {
  'welcome.title': 'Smart ODSC',
  'welcome.subtitle':
      'Welcome to the One-Door Service Centre, Government of Lao PDR',
  'welcome.queue_button': 'Get Queue Ticket',
  'welcome.feedback_button': 'Give Feedback',
  'welcome.directory_button': 'Other Services',

  'common.tap_to_select': 'Tap to select',
  'common.loading': 'Please wait...',
  'common.ok': 'OK',
  'common.error': 'Error',
  'common.success': 'Success',
  'common.retry': 'Retry',
  'common.back': 'Back',
  'common.cancel': 'Cancel',
  'common.confirm': 'Confirm',
  'common.next': 'Next',
  'common.done': 'Done',
  'common.failed_to_load': 'Failed to load',

  'error.no_internet': 'No internet connection',
  'error.timeout': 'Request timed out. Please try again',
  'error.server_prefix': 'Server error',
  'error.bad_format': 'Invalid data format',
  'error.bad_data': 'Invalid data',
  'error.out_of_range': 'Data is out of range',
  'error.bad_argument': 'Invalid argument',
  'error.bad_state': 'Invalid state',
  'error.unsupported': 'This operation is not supported',
  'error.unexpected': 'An unexpected error occurred. Please try again',
  'error.http_generic_prefix': 'An error occurred',
  'error.http_400': 'Bad request',
  'error.http_401': 'Please sign in again',
  'error.http_403': 'You do not have permission',
  'error.http_404': 'Requested data not found',
  'error.http_409': 'Conflict in data, please verify',
  'error.http_422': 'Submitted data is invalid',
  'error.http_429': 'Too many requests, please wait',
  'error.http_500': 'Server error, please try again',
  'error.http_5xx': 'Service temporarily unavailable, please try again',

  'error.tls': 'Secure connection failed. Please check device clock',
  'error.dns': 'Cannot reach the server. Please check internet',
  'error.server_refused': 'Server refused the connection',
  'error.server_unreachable': 'Cannot reach the server',
  'error.server_timeout': 'Server is responding too slowly',
  'error.network_generic': 'Connection problem, please try again',

  'login.title': 'Sign in',
  'login.username': 'Username',
  'login.password': 'Password',
  'login.button': 'Sign in',
  'login.loading': 'Signing in...',
  'login.error.empty_fields': 'Please enter username and password',
  'login.error.failed_title': 'Sign-in failed',
  'login.error.invalid_credentials': 'Invalid username or password',

  'printer.error.bluetooth': 'Cannot load Bluetooth printers',
  'printer.error.connect_failed': 'Failed to connect printer',
  'printer.error.not_connected': 'Please connect a printer first',
  'printer.error.test_failed': 'Test print failed',
  'printer.connecting': 'Connecting',
  'printer.connected': 'Printer connected',
  'printer.testing': 'Printing test...',
};
