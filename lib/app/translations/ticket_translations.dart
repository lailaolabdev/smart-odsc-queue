// Printable thermal-ticket label translations. The queue NUMBER itself
// stays as-is at call-site; only the LABELS around it are translated.

const Map<String, String> ticketLo = {
  'ticket.header_title': 'Smart ODSC',
  'ticket.header_subtitle': 'ບໍລິການປະຕູດຽວຂອງລັດຖະບານ',
  'ticket.queue_number_label': 'ເລກຄິວຂອງທ່ານ',
  'ticket.scan_to_track': 'Scan to Track', // intentionally English on print
  'ticket.ethnicity': 'ຊົນເຜົ່າ',
  'ticket.please_wait': 'ກະລຸນາລໍຖ້າການຮຽກຄິວ',
};

const Map<String, String> ticketEn = {
  'ticket.header_title': 'Smart ODSC',
  'ticket.header_subtitle': 'One-Door Service of the Government',
  'ticket.queue_number_label': 'Your queue number',
  'ticket.scan_to_track': 'Scan to Track',
  'ticket.ethnicity': 'Ethnicity',
  'ticket.please_wait': 'Please wait to be called',
};
