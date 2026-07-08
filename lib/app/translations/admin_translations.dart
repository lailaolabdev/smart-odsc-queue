// Staff / admin-facing translations: login, home, profile.
// Kept separate from kiosk-flow keys because the audience and tone differ
// (staff are operators, not the public-facing queue user).

const Map<String, String> adminLo = {
  // Home (operator landing — admin-only path)
  'admin.home.title': 'ໜ້າຫຼັກ',
  'admin.home.welcome': 'ຍິນດີຕ້ອນຮັບສູ່ລະບົບຈັດການຄິວ',

  // Login
  'admin.login.welcome': 'ຍິນດີຕ້ອນຮັບ',
  'admin.login.subtitle': 'ເຂົ້າສູ່ລະບົບເພື່ອຈັດການຄິວ',
  'admin.login.username': 'ຊື່ຜູ້ໃຊ້',
  'admin.login.password': 'ລະຫັດຜ່ານ',
  'admin.login.submit': 'ເຂົ້າສູ່ລະບົບ',
  'admin.login.brand.title': 'ລະບົບ ການຈັດການຄິວ',
  'admin.login.brand.subtitle': 'ກະຊວງ ພາຍໃນ',

  // Profile
  'admin.profile.title': 'ໂປຣໄຟລ໌',
  'admin.profile.logout': 'ອອກຈາກລະບົບ',
};

const Map<String, String> adminEn = {
  'admin.home.title': 'Home',
  'admin.home.welcome': 'Welcome to the Queue Management system',

  'admin.login.welcome': 'Welcome',
  'admin.login.subtitle': 'Sign in to manage the queue',
  'admin.login.username': 'Username',
  'admin.login.password': 'Password',
  'admin.login.submit': 'Sign in',
  'admin.login.brand.title': 'Queue Management System',
  'admin.login.brand.subtitle': 'Ministry of Interior',

  'admin.profile.title': 'Profile',
  'admin.profile.logout': 'Sign out',
};
