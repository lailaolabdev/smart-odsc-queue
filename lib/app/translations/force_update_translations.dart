// Force-update gate translations. Shown when the kiosk's installed
// versionCode falls below the backend-published minVersionCode.
//
// NOTE: do NOT add `letterSpacing > 0` to any Lao copy that renders these
// keys. Lao combining marks fracture visually when the engine applies
// positive letter spacing across the cluster boundary.

const Map<String, String> forceUpdateLo = {
  'force_update.title': 'ມີຄຳ ປັບປຸງ ໃໝ່',
  'force_update.subtitle': 'ກະລຸນາອັບເດດແອັບເພື່ອໃຊ້ງານຕໍ່',
  'force_update.cta': 'ອັບເດດດຽວນີ້',
  'force_update.retry': 'ລອງໃໝ່',
  'force_update.install_blocked':
      'ບໍ່ສາມາດເປີດໂປຣແກຣມຕິດຕັ້ງໄດ້. ກະລຸນາຕິດຕໍ່ IT',
  'force_update.downloading': 'ກຳລັງດາວໂຫລດ',
  'force_update.installing': 'ກຳລັງຕິດຕັ້ງ...',
  'force_update.installing_hint':
      'Android ຈະຖາມຢືນຢັນການຕິດຕັ້ງ. ກົດ "ຕິດຕັ້ງ"',
  'force_update.done': 'ສຳເລັດ — ກຳລັງເປີດແອັບໃໝ່',
  'force_update.error':
      'ມີຂໍ້ຜິດພາດໃນການອັບເດດ. ກະລຸນາລອງໃໝ່ ຫຼື ຕິດຕໍ່ IT',
};

const Map<String, String> forceUpdateEn = {
  'force_update.title': 'Update Required',
  'force_update.subtitle': 'Please update the app to continue',
  'force_update.cta': 'Update Now',
  'force_update.retry': 'Try Again',
  'force_update.install_blocked':
      'Cannot open the installer. Please contact IT',
  'force_update.downloading': 'Downloading',
  'force_update.installing': 'Installing...',
  'force_update.installing_hint':
      'Android will ask to confirm. Tap "Install"',
  'force_update.done': 'Done — relaunching the app',
  'force_update.error': 'Update failed. Tap Try Again or contact IT',
};
