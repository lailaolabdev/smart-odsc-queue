// Kiosk queue-flow translations: gender, ethnicity, age, disability,
// purpose, service-choice step, and shared step prompts. Grouped here so
// they can be reviewed independently of welcome / ticket strings.

const Map<String, String> kioskLo = {
  // Step titles + subtitles
  'step.gender.title': 'ເພດຂອງທ່ານ',
  'step.gender.subtitle': 'ກະລຸນາເລືອກເພດຂອງທ່ານ',

  'step.ethnicity.title': 'ຊົນເຜົ່າຂອງທ່ານ',
  'step.ethnicity.subtitle': 'ກະລຸນາເລືອກຊົນເຜົ່າຂອງທ່ານ',

  'step.age.title': 'ອາຍຸຂອງທ່ານ',
  'step.age.subtitle': 'ກະລຸນາເລືອກຊ່ວງອາຍຸຂອງທ່ານ',

  'step.disability.title': 'ທ່ານມີຄວາມພິການບໍ່?',
  'step.disability.no': 'ບໍ່ແມ່ນ (ຂ້ອຍບໍ່ພິການ)',
  'step.disability.yes': 'ແມ່ນ, ຂ້ອຍມີຄວາມພິການ (ຕ້ອງການຄວາມຊ່ວຍເຫຼືອ)',

  'step.purpose.title': 'ຈຸດປະສົງ',
  'step.purpose.subtitle': 'ກະລຸນາເລືອກຈຸດປະສົງການມາໃນຄັ້ງນີ້',

  'step.service_choice.title': 'ເລືອກບໍລິການ',
  'step.service_choice.subtitle': 'ທ່ານຕ້ອງການເລຶອກບໍລິການບໍ່?',
  'step.service_choice.helper':
      'ທ່ານຕ້ອງການເລຶອກບໍລິການບໍ່ (ຫຼືຖ້າຍັງບໍ່ແນ່ໃຈສາມາດຂ້າມຂັ້ນຕອນນີ້ໄດ້)',
  'step.service_choice.pick': 'ເລືອກບໍລິການ',
  'step.service_choice.skip': 'ຂ້າມຂັ້ນຕອນນີ້',
  'step.service_choice.unspecified': 'ບໍ່ລະບຸບໍລິການ',

  'step.service.title': 'ລາຍການບໍລິການ',
  'step.service.subtitle.pick': 'ກະລຸນາເລືອກບໍລິການທີ່ທ່ານຕ້ອງການ',
  'step.service.subtitle.view': 'ທ່ານສາມາດເບິ່ງຂໍ້ມູນບໍລິການທັງໝົດໄດ້ທີ່ນີ້',
  'step.service.search_hint': 'ຄົ້ນຫາບໍລິການທີ່ນີ້...',
  'step.service.empty': 'ບໍ່ພົບຂໍ້ມູນບໍລິການ',
  'step.service.clear_search': 'ລຶບການຄົ້ນຫາ',
  'step.service.unnamed': 'ບໍ່ລະບຸຊື່ບໍລິການ',
  'step.service.page_prefix': 'ໜ້າ',
  'step.service.search_button': 'ຄົ້ນຫາ',

  // Print-vs-photo choice (shown after user taps "Skip" on service_choice)
  'step.print_choice.title': 'ຮັບບັດຄິວ',
  'step.print_choice.subtitle': 'ກະລຸນາເລືອກວິທີຮັບບັດຄິວຂອງທ່ານ',
  'step.print_choice.print': 'ພິມບັດຄິວ',
  'step.print_choice.photo': 'ຖ່າຍຮູບ QR',

  // Gender options
  'gender.male': 'ຊາຍ',
  'gender.female': 'ຍິງ',
  'gender.other': 'ອື່ນໆ',

  // Ethnicity options
  'ethnicity.lao': 'ລາວ',
  'ethnicity.khmu': 'ຂະມຸ',
  'ethnicity.hmong': 'ມົ້ງ',
  'ethnicity.other': 'ອື່ນໆ',

  // Age ranges
  'age.0_12': '0 - 12 ປີ',
  'age.13_20': '13 - 20 ປີ',
  'age.21_35': '21 - 35 ປີ',
  'age.36_45': '36 - 45 ປີ',
  'age.46_60': '46 - 60 ປີ',
  'age.60_up': '60 ປີ ຂຶ້ນໄປ',

  // Purpose
  'purpose.inquiry': 'ສອບຖາມຂໍ້ມູນ',
  'purpose.service_usage': 'ມາໃຊ້ບໍລິການ',
  'purpose.certificate_request': 'ຂໍໃບຢັ້ງຢືນ',

  // Ticket result screen (in-app, not the printed ticket)
  'result.title': 'ສຳເລັດແລ້ວ!',
  'result.subtitle': 'ກະລຸນາຮັບບັດຄິວຂອງທ່ານ',
  'result.subtitle.photo': 'ກະລຸນາຖ່າຍຮູບ ຫຼື ສະແກນ QR ໂຄດນີ້',
  'result.your_ticket': 'ບັດຄິວຂອງທ່ານ',
  'result.scan_to_track': 'ສະແກນເພື່ອຕິດຕາມຄິວ',
  'result.scan_to_track_en': '(Scan to Track Status)',
  'result.back_to_home': 'ກັບຄືນຫາໜ້າຫຼັກ',
  'result.auto_return': 'ລະບົບຈະກັບຄືນສູ່ໜ້າຫຼັກອັດຕະໂນມັດພາຍໃນ',
  'result.seconds': 'ວິນາທີ',

  // Booking errors / loading
  'booking.issuing': 'ກຳລັງອອກບັດຄິວ...',
  'booking.error.not_logged_in': 'ບັນຊີຍັງບໍ່ໄດ້ເຂົ້າສູ່ລະບົບ',
  'booking.error.no_service_center':
      'ບັນຊີນີ້ຍັງບໍ່ມີຂໍ້ມູນສູນ ຫຼື ໜ່ວຍງານທີ່ຜູກກັບບໍລິການ',
  'booking.error.no_organization':
      'ບໍ່ພົບຂໍ້ມູນຫຼັກຂອງບໍລິການ (organization) ສໍາລັບການຈັດລຳດັບ',
  'booking.error.cannot_issue': 'ບໍ່ສາມາອອກບັດຄິວໄດ້ໃນເວລານີ້',
};

const Map<String, String> kioskEn = {
  'step.gender.title': 'Your gender',
  'step.gender.subtitle': 'Please select your gender',

  'step.ethnicity.title': 'Your ethnicity',
  'step.ethnicity.subtitle': 'Please select your ethnicity',

  'step.age.title': 'Your age',
  'step.age.subtitle': 'Please select your age range',

  'step.disability.title': 'Do you have a disability?',
  'step.disability.no': 'No (I do not have a disability)',
  'step.disability.yes': 'Yes, I have a disability (assistance needed)',

  'step.purpose.title': 'Purpose',
  'step.purpose.subtitle': 'Please select the purpose of your visit',

  'step.service_choice.title': 'Choose service',
  'step.service_choice.subtitle': 'Would you like to choose a service?',
  'step.service_choice.helper':
      'Would you like to choose a service? (You can skip this step if you are not sure)',
  'step.service_choice.pick': 'Choose service',
  'step.service_choice.skip': 'Skip this step',
  'step.service_choice.unspecified': 'Service unspecified',

  'step.service.title': 'Services',
  'step.service.subtitle.pick': 'Please select the service you need',
  'step.service.subtitle.view': 'You can browse all service information here',
  'step.service.search_hint': 'Search for a service here...',
  'step.service.empty': 'No services found',
  'step.service.clear_search': 'Clear search',
  'step.service.unnamed': 'Unnamed service',
  'step.service.page_prefix': 'Page',
  'step.service.search_button': 'Search',

  'step.print_choice.title': 'Receive ticket',
  'step.print_choice.subtitle': 'How would you like to receive your queue?',
  'step.print_choice.print': 'Print ticket',
  'step.print_choice.photo': 'Take photo of QR',

  'gender.male': 'Male',
  'gender.female': 'Female',
  'gender.other': 'Other',

  'ethnicity.lao': 'Lao',
  'ethnicity.khmu': 'Khmu',
  'ethnicity.hmong': 'Hmong',
  'ethnicity.other': 'Other',

  'age.0_12': '0 - 12 years',
  'age.13_20': '13 - 20 years',
  'age.21_35': '21 - 35 years',
  'age.36_45': '36 - 45 years',
  'age.46_60': '46 - 60 years',
  'age.60_up': '60 years and above',

  'purpose.inquiry': 'Inquiry',
  'purpose.service_usage': 'Use Service',
  'purpose.certificate_request': 'Request Certificate',

  'result.title': 'All done!',
  'result.subtitle': 'Please collect your queue ticket',
  'result.subtitle.photo': 'Please take a photo or scan this QR code',
  'result.your_ticket': 'Your queue ticket',
  'result.scan_to_track': 'Scan to track your queue',
  'result.scan_to_track_en': '(Scan to Track Status)',
  'result.back_to_home': 'Back to Home',
  'result.auto_return': 'Automatically returning to home screen in',
  'result.seconds': 'seconds',

  'booking.issuing': 'Issuing your ticket...',
  'booking.error.not_logged_in': 'User not logged in',
  'booking.error.no_service_center':
      'This account is not linked to a service centre or unit',
  'booking.error.no_organization':
      'Service organization data not found for queuing',
  'booking.error.cannot_issue': 'Unable to issue a ticket at this time',
};
