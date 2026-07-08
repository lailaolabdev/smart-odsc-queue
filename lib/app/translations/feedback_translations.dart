// Feedback wizard translations: reference-entry step, rating step, and
// confirmation panel.

const Map<String, String> feedbackLo = {
  'feedback.title': 'ຄຳຕິຊົມ',
  'feedback.subtitle': 'ທ່ານສາມາດສະແດງຄວາມຄິດເຫັນເພື່ອປັບປຸງບໍລິການຂອງພວກເຮົາ',

  // Step 1 — reference entry
  'feedback.step1.title': 'ຂັ້ນຕອນທີ່ 1: ກະລຸນາປ້ອນ ເລກອ້າງອີງຂອງທ່ານ',
  'feedback.step1.search': 'ຄົ້ນຫາ',
  'feedback.step1.scan_title': 'ສະແກນ QR ໂຄດ',
  'feedback.step1.switch_camera': 'ສະຫຼັບກ້ອງ',
  'feedback.step1.flash': 'ເປີດໄຟ',
  'camera.permission_denied': 'ກະລຸນາອະນຸຍາດໃຫ້ເຂົ້າເຖິງກ້ອງເພື່ອສະແກນ QR ໂຄດ',

  // Step 2 — rating
  'feedback.step2.kicker': 'ຂັ້ນຕອນທີ່ 2:',
  'feedback.step2.question': 'ໃຫ້ຄະແນນຄວາມເພິ່ງພໍໃຈ',
  'feedback.step2.reference_label': 'ເລກອ້າງອີງ',
  'feedback.step2.back': 'ກັບຄືນ',

  // Rating levels
  'feedback.rating.excellent': 'ດີເລີດ',
  'feedback.rating.good': 'ດີ',
  'feedback.rating.neutral': 'ປານກາງ',
  'feedback.rating.needs_improvement': 'ຄວນປັບປຸງ',
  'feedback.rating.poor': 'ບໍ່ພໍໃຈ',

  // Comment
  'feedback.comment.label': 'ເພີ່ມເຕີມ',
  'feedback.comment.optional': '(ຖ້າມີ)',
  'feedback.comment.hint': 'ພິມຂໍ້ຄວາມຂອງທ່ານທີ່ນີ້...',

  // Submit
  'feedback.submit': 'ສົ່ງຄຳຕິຊົມ',

  // Confirmation
  'feedback.thanks.title': 'ຂອບໃຈສຳລັບຄວາມຄິດເຫັນຂອງທ່ານ',
  'feedback.thanks.body':
      'ເປັນສ່ວນໜຶ່ງທີ່ຊ່ວຍໃຫ້ພວກເຮົາພັດທະນາໃຫ້ດີຂຶ້ນກວ່າເກົ່າ ຂໍຂອບໃຈ.',
  'feedback.thanks.cta': 'ສຳເລັດ',

  // Errors
  'feedback.error.reference_length':
      'ກະລຸນາປ້ອນເລກອ້າງອີງໃຫ້ຄົບ 8 ໂຕ',
  'feedback.error.reference_not_found':
      'ບໍ່ພົບເລກອ້າງອີງນີ້ ກະລຸນາກວດສອບໃໝ່',
  'feedback.error.lookup_failed':
      'ບໍ່ສາມາດກວດສອບເລກອ້າງອີງໄດ້ ກະລຸນາລອງໃໝ່',
  'feedback.error.submit_failed': 'ບໍ່ສາມາດສົ່ງຄຳຕິຊົມໄດ້ ກະລຸນາລອງໃໝ່',
  'feedback.error.network': 'ບໍ່ສາມາດສົ່ງຄຳຄິດເຫັນໄດ້ໃນເວລານີ້',
};

const Map<String, String> feedbackEn = {
  'feedback.title': 'Feedback',
  'feedback.subtitle':
      'You can share your feedback to help us improve our service',

  'feedback.step1.title': 'Step 1: Please enter your reference number',
  'feedback.step1.search': 'Search',
  'feedback.step1.scan_title': 'Scan QR Code',
  'feedback.step1.switch_camera': 'Switch Camera',
  'feedback.step1.flash': 'Flash',
  'camera.permission_denied': 'Please allow camera access to scan QR code',

  'feedback.step2.kicker': 'Step 2:',
  'feedback.step2.question': 'Rate your satisfaction',
  'feedback.step2.reference_label': 'Reference',
  'feedback.step2.back': 'Back',

  'feedback.rating.excellent': 'Excellent',
  'feedback.rating.good': 'Good',
  'feedback.rating.neutral': 'Neutral',
  'feedback.rating.needs_improvement': 'Needs improvement',
  'feedback.rating.poor': 'Poor',

  'feedback.comment.label': 'Additional comment',
  'feedback.comment.optional': '(optional)',
  'feedback.comment.hint': 'Type your message here...',

  'feedback.submit': 'Submit feedback',

  'feedback.thanks.title': 'Thank you for your feedback',
  'feedback.thanks.body':
      'It helps us keep improving. Thank you.',
  'feedback.thanks.cta': 'Done',

  'feedback.error.reference_length':
      'Please enter all 8 digits of the reference number',
  'feedback.error.reference_not_found':
      'Reference number not found. Please check and try again',
  'feedback.error.lookup_failed':
      'Could not verify the reference number. Please try again',
  'feedback.error.submit_failed':
      'Could not submit your feedback. Please try again',
  'feedback.error.network': 'Unable to submit feedback at this time',
};
