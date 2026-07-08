// API Endpoints Configuration
class ApiEndpoints {
  // Base URL — production default. Override at build time with
  //   flutter run        --dart-define=BASE_URL=http://192.168.1.62:8084
  //   flutter build apk  --dart-define=BASE_URL=...
  // No override + a release build → hits production directly.
  static const String baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'https://api.odsc.gov.la',
  );
  static const String storageBaseUrl =
      'https://storage-console.odsc.gov.la/odsc-public-storage/images/medium/';

  // Authentication
  static const String loginCitizen = '/api/v1/auth/login-citizen';
  static const String loginOfficer = '/api/v1/auth/login-officer';

  // OTP
  static const String sendPhoneOtp = '/api/v1/auth/send-phone-otp';
  static const String verifyPhoneOtp = '/api/v1/auth/verify-phone-otp';
  static const String sendEmailOtp = '/api/v1/auth/send-email-otp';
  static const String verifyEmailOtp = '/api/v1/auth/verify-email-otp';
  static const String registerPhone = '/api/v1/auth/register-phone';
  static const String registerEmail = '/api/v1/auth/register-email';

  static const String resetPassword = '/api/v1/auth/reset-password';
  static const String refreshToken = '/api/auth/refresh-token';

  // User
  static const String userCitizen = '/api/v1/user/citizen';

  // Master Data
  static const String banner = '/api/v1/master-data/banner';
  static const String governmentService =
      '/api/v1/master-data/government-service';
  static const String news = '/api/v1/master-data/news';
  static const String serviceCenter = '/api/v1/master-data/service-center';
  static const String province = '/api/v1/master-data/province';
  static const String district = '/api/v1/master-data/district';
  static const String faq = '/api/v1/master-data/faq';
  static const String feedback = '/api/v1/master-data/feedback';
  static const String appVersion = '/api/v1/master-data/app-version';

  // Services
  static const String services = '/api/v1/core/services';
  static const String queues = '/api/v1/core/queues';
  static const String applications = '/api/v1/core/applications';

  // Profile / KYC
  static String citizenKyc(String userId) => '/api/v1/user/kyc/$userId';

  // Storage / File Upload
  static const String uploadImage = '/api/v1/storage/image/upload';
  static const String uploadFile = '/api/v1/storage/file/upload';
  static String deleteImage(String imageName) =>
      '/api/v1/storage/image/$imageName';
  static String deleteFile(String fileName) => '/api/v1/storage/file/$fileName';
}

// HTTP Status Codes
class HttpStatusCodes {
  static const int ok = 200;
  static const int created = 201;
  static const int accepted = 202;
  static const int noContent = 204;
  static const int badRequest = 400;
  static const int unauthorized = 401;
  static const int forbidden = 403;
  static const int notFound = 404;
  static const int conflict = 409;
  static const int unprocessableEntity = 422;
  static const int tooManyRequests = 429;
  static const int internalServerError = 500;
  static const int badGateway = 502;
  static const int serviceUnavailable = 503;
}

// API Response Status
enum ApiResponseStatus {
  success,
  error,
  loading,
  timeout,
  noConnection,
  unauthorized,
  forbidden,
  notFound,
  serverError,
}

// API Error Types
enum ApiErrorType {
  network,
  timeout,
  unauthorized,
  forbidden,
  notFound,
  validation,
  server,
  unknown,
}
