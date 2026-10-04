enum AppLanguage { english, sinhala, tamil }

class SAMSStrings {
  static AppLanguage currentLanguage = AppLanguage.english;

  static void setLanguage(AppLanguage lang) {
    currentLanguage = lang;
  }

  static String get(Map<AppLanguage, String> localized) {
    return localized[currentLanguage] ?? localized[AppLanguage.english] ?? '';
  }

  // ── General / Branding ─────────────────────────────────────────────────────
  static String get appName => get({
    AppLanguage.english: 'EduNexus',
    AppLanguage.sinhala: 'EduNexus',
    AppLanguage.tamil: 'EduNexus',
  });
  static String get schoolPortal => get({
    AppLanguage.english: 'School Attendance & Management System',
    AppLanguage.sinhala: 'පාසල් පැමිණීමේ හා කළමනාකරණ පද්ධතිය',
    AppLanguage.tamil: 'பள்ளி வருகை மற்றும் மேலாண்மை அமைப்பு',
  });
  static String get sriLanka => get({
    AppLanguage.english: 'Democratic Socialist Republic of Sri Lanka',
    AppLanguage.sinhala: 'ශ්‍රී ලංකා ප්‍රජාතාන්ත්‍රික සමාජවාදී ජනරජය',
    AppLanguage.tamil: 'இலங்கை ஜனநாயக சோசலிச குடியரசு',
  });
  static String get loginTitle => get({
    AppLanguage.english: 'Student & Parent Portal',
    AppLanguage.sinhala: 'ශිෂ්‍ය සහ දෙමාපිය පද්ධතිය',
    AppLanguage.tamil: 'மாணவர் & பெற்றோர் போர்டல்',
  });

  // ── Login / Auth ───────────────────────────────────────────────────────────
  static String get login => get({
    AppLanguage.english: 'Login',
    AppLanguage.sinhala: 'ඇතුල් වන්න',
    AppLanguage.tamil: 'உள்நுழைக',
  });
  static String get username => get({
    AppLanguage.english: 'Username',
    AppLanguage.sinhala: 'පරිශීලක නාමය',
    AppLanguage.tamil: 'பயனர்பெயர்',
  });
  static String get password => get({
    AppLanguage.english: 'Password',
    AppLanguage.sinhala: 'මුරපදය',
    AppLanguage.tamil: 'கடவுச்சொல்',
  });
  static String get forgotPassword => get({
    AppLanguage.english: 'Forgot Password?',
    AppLanguage.sinhala: 'මුරපදය අමතකද?',
    AppLanguage.tamil: 'கடவுச்சொல் மறந்துவிட்டதா?',
  });
  static String get forgotPasswordTitle => get({
    AppLanguage.english: 'Forgot Password',
    AppLanguage.sinhala: 'මුරපදය අමතකද',
    AppLanguage.tamil: 'கடவுச்சொல் மறந்துவிட்டதா',
  });
  static String get forgotPasswordSub => get({
    AppLanguage.english: 'Reset your password via SMS verification',
    AppLanguage.sinhala: 'SMS තහවුරු කිරීම මඟින් ඔබගේ මුරපදය යළි සකසන්න',
    AppLanguage.tamil: 'SMS சரிபார்ப்பு மூலம் உங்கள் கடவுச்சொல்லை மீட்டமைக்கவும்',
  });
  static String get enterUsername => get({
    AppLanguage.english: 'Please enter your username',
    AppLanguage.sinhala: 'කරුණාකර පරිශීලක නාමය ඇතුළත් කරන්න',
    AppLanguage.tamil: 'உங்கள் பயனர்பெயரை உள்ளிடவும்',
  });
  static String get enterPassword => get({
    AppLanguage.english: 'Please enter your password',
    AppLanguage.sinhala: 'කරුණාකර මුරපදය ඇතුළත් කරන්න',
    AppLanguage.tamil: 'உங்கள் கடவுச்சொல்லை உள்ளிடவும்',
  });
  static String get invalidCredentials => get({
    AppLanguage.english: 'Invalid username or password',
    AppLanguage.sinhala: 'වලංගු නොවන පරිශීලක නාමයක් හෝ මුරපදයක්',
    AppLanguage.tamil: 'தவறான பயனர்பெயர் அல்லது கடவுச்சொல்',
  });

  // ── Forgot Password Flow ───────────────────────────────────────────────────
  static String get resetPasswordTitle => get({
    AppLanguage.english: 'Reset Password',
    AppLanguage.sinhala: 'මුරපදය යළි සකසන්න',
    AppLanguage.tamil: 'கடவுச்சொல்லை மீட்டமைக்கவும்',
  });
  static String get resetPasswordSubtitle => get({
    AppLanguage.english: 'Enter your username to receive an SMS verification code',
    AppLanguage.sinhala: 'SMS තහවුරු කිරීමේ කේතයක් ලබා ගැනීමට ඔබගේ පරිශීලක නාමය ඇතුළත් කරන්න',
    AppLanguage.tamil: 'SMS சரிபார்ப்புக் குறியீட்டைப் பெற உங்கள் பயனர்பெயரை உள்ளிடவும்',
  });
  static String get sendOtp => get({
    AppLanguage.english: 'Send Verification OTP',
    AppLanguage.sinhala: 'තහවුරු කිරීමේ OTP යවන්න',
    AppLanguage.tamil: 'சரிபார்ப்பு OTP அனுப்புக',
  });
  static String get enterOtp => get({
    AppLanguage.english: 'Enter 6-Digit OTP',
    AppLanguage.sinhala: 'ඉලක්කම් 6ක OTP කේතය ඇතුළත් කරන්න',
    AppLanguage.tamil: '6 இலக்க OTP குறியீட்டை உள்ளிடவும்',
  });
  static String get otpSentTo => get({
    AppLanguage.english: 'OTP code sent to registered number',
    AppLanguage.sinhala: 'ලියාපදිංචි දුරකථන අංකයට OTP යවා ඇත',
    AppLanguage.tamil: 'பதிவுசெய்த தொலைபேசி எண்ணிற்கு OTP அனுப்பப்பட்டது',
  });
  static String get verifyOtp => get({
    AppLanguage.english: 'Verify OTP',
    AppLanguage.sinhala: 'OTP තහවුරු කරන්න',
    AppLanguage.tamil: 'OTP சரிபார்க்கவும்',
  });
  static String get resendOtp => get({
    AppLanguage.english: 'Resend OTP',
    AppLanguage.sinhala: 'නැවත OTP යවන්න',
    AppLanguage.tamil: 'OTP மீண்டும் அனுப்புக',
  });
  static String get resendIn => get({
    AppLanguage.english: 'Resend in',
    AppLanguage.sinhala: 'නැවත යැවීමට',
    AppLanguage.tamil: 'மீண்டும் அனுப்ப',
  });
  static String get newPassword => get({
    AppLanguage.english: 'New Password',
    AppLanguage.sinhala: 'නව මුරපදය',
    AppLanguage.tamil: 'புதிய கடவுச்சொல்',
  });
  static String get confirmNewPassword => get({
    AppLanguage.english: 'Confirm New Password',
    AppLanguage.sinhala: 'නව මුරපදය තහවුරු කරන්න',
    AppLanguage.tamil: 'புதிய கடவுச்சொல்லை உறுதிப்படுத்தவும்',
  });
  static String get resetPasswordButton => get({
    AppLanguage.english: 'Update Password',
    AppLanguage.sinhala: 'මුරපදය සුරකින්න',
    AppLanguage.tamil: 'கடவுச்சொல்லைப் புதுப்பிக்கவும்',
  });
  static String get passwordResetSuccess => get({
    AppLanguage.english: 'Password reset successfully! Please log in with your new password.',
    AppLanguage.sinhala: 'මුරපදය සාර්ථකව වෙනස් කරන ලදී! කරුණාකර ඔබගේ නව මුරපදයෙන් ප්‍රවේශ වන්න.',
    AppLanguage.tamil: 'கடவுச்சொல் வெற்றிகரமாக மீட்டமைக்கப்பட்டது! உங்கள் புதிய கடவுச்சொல்லுடன் உள்நுழைக.',
  });
  static String get passwordsDoNotMatch => get({
    AppLanguage.english: 'Passwords do not match.',
    AppLanguage.sinhala: 'මුරපද නොගැලපේ.',
    AppLanguage.tamil: 'கடவுச்சொற்கள் பொருந்தவில்லை.',
  });
  static String get passwordTooShort => get({
    AppLanguage.english: 'Password must be at least 6 characters.',
    AppLanguage.sinhala: 'මුරපදය අවම වශයෙන් අකුරු 6ක් විය යුතුය.',
    AppLanguage.tamil: 'கடவுச்சொல் குறைந்தது 6 எழுத்துக்களாக இருக்க வேண்டும்.',
  });
  static String get invalidOtp => get({
    AppLanguage.english: 'Invalid or expired OTP code. Please try again.',
    AppLanguage.sinhala: 'වලංගු නොවන හෝ කල් ඉකුත් වූ OTP. නැවත උත්සාහ කරන්න.',
    AppLanguage.tamil: 'தவறான அல்லது காலாவதியான OTP. மீண்டும் முயற்சிக்கவும்.',
  });
  static String get noPhoneRegistered => get({
    AppLanguage.english: 'No registered phone number found for this account. Please contact school administration.',
    AppLanguage.sinhala: 'මෙම ගිණුමට ලියාපදිංචි දුරකථන අංකයක් නොමැත. කරුණාකර පාසල් පරිපාලනය අමතන්න.',
    AppLanguage.tamil: 'இந்த கணக்கிற்கு பதிவுசெய்த தொலைபேசி எண் எதுவும் இல்லை. பள்ளி நிர்வாகத்தை தொடர்பு கொள்ளவும்.',
  });
  static String get backToLogin => get({
    AppLanguage.english: 'Back to Login',
    AppLanguage.sinhala: 'නැවත ප්‍රවේශයට',
    AppLanguage.tamil: 'மீண்டும் உள்நுழைவிற்கு',
  });

  // ── Registration & Roles ───────────────────────────────────────────────────
  static String get register => get({
    AppLanguage.english: 'Register',
    AppLanguage.sinhala: 'ලියාපදිංචි වන්න',
    AppLanguage.tamil: 'பதிவு செய்க',
  });
  static String get registerTitle => get({
    AppLanguage.english: 'Create Account',
    AppLanguage.sinhala: 'ගිණුමක් සාදන්න',
    AppLanguage.tamil: 'கணக்கை உருவாக்கவும்',
  });
  static String get registerSub => get({
    AppLanguage.english: 'Join EduNexus Academic Portal',
    AppLanguage.sinhala: 'EduNexus අධ්‍යාපනික පද්ධතියට එක්වන්න',
    AppLanguage.tamil: 'EduNexus கல்வி தளத்தில் இணையுங்கள்',
  });
  static String get fullName => get({
    AppLanguage.english: 'Full Name',
    AppLanguage.sinhala: 'සම්පූර්ණ නම',
    AppLanguage.tamil: 'முழுப் பெயர்',
  });
  static String get parentFullName => get({
    AppLanguage.english: 'Parent / Guardian Full Name',
    AppLanguage.sinhala: 'දෙමාපිය / භාරකරුගේ සම්පූර්ණ නම',
    AppLanguage.tamil: 'பெற்றோர் / பாதுகாவலர் முழுப் பெயர்',
  });
  static String get roleSelect => get({
    AppLanguage.english: 'Account Role',
    AppLanguage.sinhala: 'භූමිකාව',
    AppLanguage.tamil: 'பங்கு',
  });
  static String get roleStudent => get({
    AppLanguage.english: 'Student',
    AppLanguage.sinhala: 'ශිෂ්‍ය',
    AppLanguage.tamil: 'மாணவர்',
  });
  static String get roleParent => get({
    AppLanguage.english: 'Parent',
    AppLanguage.sinhala: 'දෙමාපිය',
    AppLanguage.tamil: 'பெற்றோர்',
  });
  static String get roleTeacher => get({
    AppLanguage.english: 'Teacher',
    AppLanguage.sinhala: 'ගුරු',
    AppLanguage.tamil: 'ஆசிரியர்',
  });
  static String get rolePrincipal => get({
    AppLanguage.english: 'Principal',
    AppLanguage.sinhala: 'විදුහල්පති',
    AppLanguage.tamil: 'அதிபர்',
  });
  static String get schoolLabel => get({
    AppLanguage.english: 'School',
    AppLanguage.sinhala: 'පාසල',
    AppLanguage.tamil: 'பாடசாலை',
  });
  static String get selectSchool => get({
    AppLanguage.english: 'Select School',
    AppLanguage.sinhala: 'පාසල තෝරන්න',
    AppLanguage.tamil: 'பாடசாலையைத் தேர்ந்தெடுக்கவும்',
  });
  static String get classTeacherLabel => get({
    AppLanguage.english: 'Class Teacher',
    AppLanguage.sinhala: 'පන්ති භාර ගුරුතුමා/ගුරුතුමිය',
    AppLanguage.tamil: 'வகுப்பு ஆசிரியர்',
  });
  static String get classTeacherSuggested => get({
    AppLanguage.english: 'Auto-suggested Class Teacher',
    AppLanguage.sinhala: 'යෝජිත පන්ති භාර ගුරුතුමා/ගුරුතුමිය',
    AppLanguage.tamil: 'பரிந்துரைக்கப்பட்ட வகுப்பு ஆசிரியர்',
  });
  static String get gradeLabel => get({
    AppLanguage.english: 'Grade',
    AppLanguage.sinhala: 'ශ්‍රේණිය',
    AppLanguage.tamil: 'தரம்',
  });
  static String get grade => get({
    AppLanguage.english: 'Grade',
    AppLanguage.sinhala: 'ශ්‍රේණිය',
    AppLanguage.tamil: 'தரம்',
  });
  static String get classRoomLabel => get({
    AppLanguage.english: 'Class / Section',
    AppLanguage.sinhala: 'පන්තිය',
    AppLanguage.tamil: 'வகுப்பு',
  });
  static String get parentContactLabel => get({
    AppLanguage.english: 'Contact Phone Number',
    AppLanguage.sinhala: 'දුරකථන අංකය',
    AppLanguage.tamil: 'தொலைபேசி எண்',
  });
  static String get linkedStudentId => get({
    AppLanguage.english: 'Student Admission Number',
    AppLanguage.sinhala: 'ශිෂ්‍ය ඇතුළත් කිරීමේ අංකය',
    AppLanguage.tamil: 'மாணவர் சேர்க்கை எண்',
  });
  static String get studentAdmissionHint => get({
    AppLanguage.english: 'e.g. ADM-44424',
    AppLanguage.sinhala: 'උදා: ADM-44424',
    AppLanguage.tamil: 'எ.கா. ADM-44424',
  });
  static String get verifyAdmissionNumber => get({
    AppLanguage.english: 'Verify Admission & Send OTP',
    AppLanguage.sinhala: 'ඇතුළත් කිරීමේ අංකය තහවුරු කර OTP යවන්න',
    AppLanguage.tamil: 'சேர்க்கை எண்ணைச் சரிபார்த்து OTP அனுப்புக',
  });
  static String get studentFound => get({
    AppLanguage.english: 'Student Verified',
    AppLanguage.sinhala: 'ශිෂ්‍යයා තහවුරු කරන ලදී',
    AppLanguage.tamil: 'மாணவர் சரிபார்க்கப்பட்டார்',
  });
  static String get studentNotFound => get({
    AppLanguage.english: 'Student admission number not found. Please check and try again.',
    AppLanguage.sinhala: 'මෙම ශිෂ්‍ය ඇතුළත් කිරීමේ අංකය හමු නොවීය. කරුණාකර නැවත පරීක්ෂා කරන්න.',
    AppLanguage.tamil: 'மாணவர் சேர்க்கை எண் கிடைக்கவில்லை. சரிபார்த்து மீண்டும் முயற்சிக்கவும்.',
  });
  static String get parentMustRegisterFirst => get({
    AppLanguage.english: 'Parent Verification Required: Your parent must register and verify this Admission Number before student account creation.',
    AppLanguage.sinhala: 'දෙමාපිය තහවුරු කිරීම අවශ්‍යයි: සිසු ගිණුම සෑදීමට පෙර ඔබගේ දෙමාපියන් මෙම ඇතුළත් කිරීමේ අංකය සමඟ ලියාපදිංචි විය යුතුය.',
    AppLanguage.tamil: 'பெற்றோர் சரிபார்ப்பு தேவை: மாணவர் கணக்கை உருவாக்குவதற்கு முன் உங்கள் பெற்றோர் இந்த சேர்க்கை எண்ணுடன் பதிவு செய்ய வேண்டும்.',
  });
  static String get askParentToRegister => get({
    AppLanguage.english: 'Please ask your parent to register first via the Parent Portal.',
    AppLanguage.sinhala: 'කරුණාකර පළමුව ඔබගේ දෙමාපියන්ට දෙමාපිය පෝටලය හරහා ලියාපදිංචි වීමට පවසන්න.',
    AppLanguage.tamil: 'தயவுசெய்து உங்கள் பெற்றோரை முதலில் பெற்றோர் போர்டல் வழியாக பதிவு செய்யுமாறு கூறவும்.',
  });
  static String get studentAdmissionRequired => get({
    AppLanguage.english: 'Please enter your student admission number (e.g. ADM-44424)',
    AppLanguage.sinhala: 'කරුණාකර ඔබගේ ශිෂ්‍ය ඇතුළත් කිරීමේ අංකය ඇතුළත් කරන්න (උදා: ADM-44424)',
    AppLanguage.tamil: 'உங்கள் மாணவர் சேர்க்கை எண்ணை உள்ளிடவும் (எ.கா. ADM-44424)',
  });
  static String get parentVerifiedSuccess => get({
    AppLanguage.english: 'Parent verified! You can proceed with registration.',
    AppLanguage.sinhala: 'දෙමාපියන් තහවුරු කරන ලදී! ඔබට ලියාපදිංචි විය හැක.',
    AppLanguage.tamil: 'பெற்றோர் சரிபார்க்கப்பட்டார்! நீங்கள் பதிவைத் தொடரலாம்.',
  });
  static String get noParentPhoneRegistered => get({
    AppLanguage.english: 'No parent phone number registered for this student. Please contact school administration.',
    AppLanguage.sinhala: 'මෙම සිසුවා සඳහා ලියාපදිංචි දෙමාපිය දුරකථන අංකයක් නොමැත. කරුණාකර පාසල් පරිපාලනය අමතන්න.',
    AppLanguage.tamil: 'இந்த மாணவருக்கு பதிவு செய்யப்பட்ட பெற்றோர் தொலைபேசி எண் இல்லை. பள்ளி நிர்வாகத்தை தொடர்பு கொள்ளவும்.',
  });
  static String get parentOtpSentTo => get({
    AppLanguage.english: 'OTP sent to parent contact on student file',
    AppLanguage.sinhala: 'ශිෂ්‍ය ලිපිගොනුවේ ඇති දෙමාපිය දුරකථන අංකයට OTP යවන ලදී',
    AppLanguage.tamil: 'மாணவர் கோப்பில் உள்ள பெற்றோர் எண்ணிற்கு OTP அனுப்பப்பட்டது',
  });
  static String get parentAccountDetails => get({
    AppLanguage.english: 'Parent Account Details',
    AppLanguage.sinhala: 'දෙමාපිය ගිණුම් විස්තර',
    AppLanguage.tamil: 'பெற்றோர் கணக்கு விவரங்கள்',
  });
  static String get parentAccountSub => get({
    AppLanguage.english: 'Set your parent login credentials',
    AppLanguage.sinhala: 'ඔබගේ දෙමාපිය ප්‍රවේශ තොරතුරු ඇතුළත් කරන්න',
    AppLanguage.tamil: 'உங்கள் பெற்றோர் உள்நுழைவு விவரங்களை அமைக்கவும்',
  });
  static String get completeRegistration => get({
    AppLanguage.english: 'Complete Registration',
    AppLanguage.sinhala: 'ලියාපදිංචිය සම්පූර්ණ කරන්න',
    AppLanguage.tamil: 'பதிவை முடிக்கவும்',
  });
  static String get changeAdmissionNumber => get({
    AppLanguage.english: 'Change Admission No.',
    AppLanguage.sinhala: 'ඇතුළත් කිරීමේ අංකය වෙනස් කරන්න',
    AppLanguage.tamil: 'சேர்க்கை எண்ணை மாற்றவும்',
  });
  static String get step1Admission => get({
    AppLanguage.english: 'Step 1: Admission No.',
    AppLanguage.sinhala: 'පියවර 1: ඇතුළත් කිරීමේ අංකය',
    AppLanguage.tamil: 'படி 1: சேர்க்கை எண்',
  });
  static String get step2Otp => get({
    AppLanguage.english: 'Step 2: SMS OTP',
    AppLanguage.sinhala: 'පියවර 2: SMS OTP',
    AppLanguage.tamil: 'படி 2: SMS OTP',
  });
  static String get step3Profile => get({
    AppLanguage.english: 'Step 3: Setup Account',
    AppLanguage.sinhala: 'පියවර 3: ගිණුම සාදන්න',
    AppLanguage.tamil: 'படி 3: கணக்கு அமைப்பு',
  });
  static String get alreadyHaveAccount => get({
    AppLanguage.english: 'Already have an account? Sign in',
    AppLanguage.sinhala: 'දැනටමත් ගිණුමක් තිබේද? ඇතුල් වන්න',
    AppLanguage.tamil: 'ஏற்கனவே கணக்கு உள்ளதா? உள்நுழைக',
  });
  static String get dontHaveAccount => get({
    AppLanguage.english: 'Don\'t have an account? Register',
    AppLanguage.sinhala: 'ගිණුමක් නොමැතිද? ලියාපදිංචි වන්න',
    AppLanguage.tamil: 'கணக்கு இல்லையா? பதிவு செய்க',
  });

  // ── Navigation Tabs ────────────────────────────────────────────────────────
  static String get navHome => get({
    AppLanguage.english: 'Home',
    AppLanguage.sinhala: 'මුල් පිටුව',
    AppLanguage.tamil: 'முகப்பு',
  });
  static String get navAttendance => get({
    AppLanguage.english: 'Attendance',
    AppLanguage.sinhala: 'පැමිණීම',
    AppLanguage.tamil: 'வருகை',
  });
  static String get navProgress => get({
    AppLanguage.english: 'Progress',
    AppLanguage.sinhala: 'ප්‍රගතිය',
    AppLanguage.tamil: 'முன்னேற்றம்',
  });
  static String get navTimetable => get({
    AppLanguage.english: 'Timetable',
    AppLanguage.sinhala: 'කාලසටහන',
    AppLanguage.tamil: 'பாடவேளை',
  });
  static String get navMore => get({
    AppLanguage.english: 'More',
    AppLanguage.sinhala: 'තවත්',
    AppLanguage.tamil: 'மேலும்',
  });
  static String get tabDashboard => get({
    AppLanguage.english: 'Dashboard',
    AppLanguage.sinhala: 'මුල් පිටුව',
    AppLanguage.tamil: 'முகப்பு',
  });
  static String get tabAttendance => get({
    AppLanguage.english: 'Attendance',
    AppLanguage.sinhala: 'පැමිණීම',
    AppLanguage.tamil: 'வருகை',
  });
  static String get tabTimetable => get({
    AppLanguage.english: 'Timetable',
    AppLanguage.sinhala: 'කාලසටහන',
    AppLanguage.tamil: 'பாடவேளை',
  });
  static String get tabNotices => get({
    AppLanguage.english: 'Notices',
    AppLanguage.sinhala: 'නිවේදන',
    AppLanguage.tamil: 'அறிவிப்புகள்',
  });
  static String get tabSettings => get({
    AppLanguage.english: 'Settings',
    AppLanguage.sinhala: 'සැකසුම්',
    AppLanguage.tamil: 'அமைப்புகள்',
  });

  // ── Dashboard Overview ─────────────────────────────────────────────────────
  static String get welcomeBack => get({
    AppLanguage.english: 'Welcome back,',
    AppLanguage.sinhala: 'නැවත සාදරයෙන් පිළිගනිමු,',
    AppLanguage.tamil: 'மீண்டும் வருக,',
  });
  static String get goodMorning => get({
    AppLanguage.english: 'Good Morning',
    AppLanguage.sinhala: 'සුබ උදෑසනක්',
    AppLanguage.tamil: 'காலை வணக்கம்',
  });
  static String get goodAfternoon => get({
    AppLanguage.english: 'Good Afternoon',
    AppLanguage.sinhala: 'සුබ දහවලක්',
    AppLanguage.tamil: 'மதிய வணக்கம்',
  });
  static String get goodEvening => get({
    AppLanguage.english: 'Good Evening',
    AppLanguage.sinhala: 'සුබ සන්ධ්‍යාවක්',
    AppLanguage.tamil: 'மாலை வணக்கம்',
  });
  static String get parent => get({
    AppLanguage.english: 'Parent',
    AppLanguage.sinhala: 'දෙමාපිය',
    AppLanguage.tamil: 'பெற்றோர்',
  });
  static String get student => get({
    AppLanguage.english: 'Student',
    AppLanguage.sinhala: 'ශිෂ්‍ය',
    AppLanguage.tamil: 'மாணவர்',
  });
  static String get overallAttendance => get({
    AppLanguage.english: 'Overall Attendance',
    AppLanguage.sinhala: 'සමස්ත පැමිණීම',
    AppLanguage.tamil: 'ஒட்டுமொத்த வருகை',
  });
  static String get daysPresent => get({
    AppLanguage.english: 'Days Present',
    AppLanguage.sinhala: 'පැමිණි දින ගණන',
    AppLanguage.tamil: 'வந்த நாட்கள்',
  });
  static String get daysAbsent => get({
    AppLanguage.english: 'Days Absent',
    AppLanguage.sinhala: 'නොපැමිණි දින ගණන',
    AppLanguage.tamil: 'வராத நாட்கள்',
  });
  static String get todayStatus => get({
    AppLanguage.english: 'Today\'s Status',
    AppLanguage.sinhala: 'අද දින තත්ත්වය',
    AppLanguage.tamil: 'இன்றைய நிலை',
  });
  static String get statusPresent => get({
    AppLanguage.english: 'Present',
    AppLanguage.sinhala: 'පැමිණ ඇත',
    AppLanguage.tamil: 'வந்துள்ளார்',
  });
  static String get statusAbsent => get({
    AppLanguage.english: 'Absent',
    AppLanguage.sinhala: 'නොපැමිණි',
    AppLanguage.tamil: 'வரவில்லை',
  });
  static String get statusLate => get({
    AppLanguage.english: 'Late',
    AppLanguage.sinhala: 'ප්‍රමාද වී',
    AppLanguage.tamil: 'தாமதம்',
  });
  static String get statusExcused => get({
    AppLanguage.english: 'Excused',
    AppLanguage.sinhala: 'නිවාඩු අනුමත',
    AppLanguage.tamil: 'அனுமதிக்கப்பட்டது',
  });
  static String get present => get({
    AppLanguage.english: 'Present',
    AppLanguage.sinhala: 'පැමිණ ඇත',
    AppLanguage.tamil: 'வந்துள்ளார்',
  });
  static String get absent => get({
    AppLanguage.english: 'Absent',
    AppLanguage.sinhala: 'නොපැමිණි',
    AppLanguage.tamil: 'வரவில்லை',
  });
  static String get late => get({
    AppLanguage.english: 'Late',
    AppLanguage.sinhala: 'ප්‍රමාද වී',
    AppLanguage.tamil: 'தாமதம்',
  });
  static String get excused => get({
    AppLanguage.english: 'Excused',
    AppLanguage.sinhala: 'නිවාඩු අනුමත',
    AppLanguage.tamil: 'அனுமதிக்கப்பட்டது',
  });
  static String get recentAttendance => get({
    AppLanguage.english: 'Recent Attendance',
    AppLanguage.sinhala: 'මෑත පැමිණීම් වාර්තා',
    AppLanguage.tamil: 'சமீபத்திய வருகை',
  });
  static String get viewAll => get({
    AppLanguage.english: 'View All',
    AppLanguage.sinhala: 'සියල්ල බලන්න',
    AppLanguage.tamil: 'அனைத்தையும் பார்க்க',
  });
  static String get latestTerm => get({
    AppLanguage.english: 'Latest Term',
    AppLanguage.sinhala: 'නවතම වාරය',
    AppLanguage.tamil: 'சமீபத்திய தவணை',
  });
  static String get classRank => get({
    AppLanguage.english: 'Class Rank',
    AppLanguage.sinhala: 'පන්ති ස්ථානය',
    AppLanguage.tamil: 'வகுப்பு தரம்',
  });
  static String get recentNotices => get({
    AppLanguage.english: 'Recent Notices',
    AppLanguage.sinhala: 'මෑත නිවේදන',
    AppLanguage.tamil: 'சமீபத்திய அறிவிப்புகள்',
  });
  static String get latestAttendanceUpdate => get({
    AppLanguage.english: 'Latest Attendance Update',
    AppLanguage.sinhala: 'නවතම පැමිණීම් වාර්තාව',
    AppLanguage.tamil: 'சமீபத்திய வருகை புதுப்பிப்பு',
  });
  static String get recordedByTeacher => get({
    AppLanguage.english: 'Recorded by Class Teacher',
    AppLanguage.sinhala: 'පන්ති භාර ගුරුතුමා සටහන් කළේය',
    AppLanguage.tamil: 'வகுப்பு ஆசிரியரால் பதிவு செய்யப்பட்டது',
  });
  static String get parentNotifications => get({
    AppLanguage.english: 'Parent Notifications',
    AppLanguage.sinhala: 'දෙමාපිය දැනුම්දීම්',
    AppLanguage.tamil: 'பெற்றோர் அறிவிப்புகள்',
  });
  static String get markAllRead => get({
    AppLanguage.english: 'Mark all as read',
    AppLanguage.sinhala: 'සියල්ල කියවූ බව සටහන් කරන්න',
    AppLanguage.tamil: 'அனைத்தையும் படித்ததாகக் குறிக்கவும்',
  });
  static String get noNotifications => get({
    AppLanguage.english: 'No notifications yet',
    AppLanguage.sinhala: 'දැනට දැනුම්දීම් නොමැත',
    AppLanguage.tamil: 'இன்னும் அறிவிப்புகள் இல்லை',
  });

  // ── Attendance Screen ──────────────────────────────────────────────────────
  static String get monthlyAttendance => get({
    AppLanguage.english: 'Monthly Attendance',
    AppLanguage.sinhala: 'මාසික පැමිණීම',
    AppLanguage.tamil: 'மாதாந்திர வருகை',
  });
  static String get attendanceHistory => get({
    AppLanguage.english: 'Attendance History',
    AppLanguage.sinhala: 'පැමිණීමේ ඉතිහාසය',
    AppLanguage.tamil: 'வருகை வரலாறு',
  });
  static String get alertAbsent => get({
    AppLanguage.english: 'Absent Alert',
    AppLanguage.sinhala: 'නොපැමිණීමේ නිවේදනය',
    AppLanguage.tamil: 'வராதமை எச்சரிக்கை',
  });
  static String get selectMonth => get({
    AppLanguage.english: 'Select Month',
    AppLanguage.sinhala: 'මාසය තෝරන්න',
    AppLanguage.tamil: 'மாதத்தைத் தேர்ந்தெடுக்கவும்',
  });
  static String get totalWorkingDays => get({
    AppLanguage.english: 'Total Working Days',
    AppLanguage.sinhala: 'මුළු පාසල් දින ගණන',
    AppLanguage.tamil: 'மொத்த வேலை நாட்கள்',
  });
  static String get attendanceRate => get({
    AppLanguage.english: 'Attendance Rate',
    AppLanguage.sinhala: 'පැමිණීමේ ප්‍රතිශතය',
    AppLanguage.tamil: 'வருகை சதவீதம்',
  });
  static String get noAttendanceRecords => get({
    AppLanguage.english: 'No attendance records found for this period.',
    AppLanguage.sinhala: 'මෙම කාලසීමාව සඳහා පැමිණීමේ වාර්තා නොමැත.',
    AppLanguage.tamil: 'இந்த காலத்திற்கான வருகை பதிவுகள் எதுவும் இல்லை.',
  });

  // ── Timetable Screen ───────────────────────────────────────────────────────
  static String get weeklyTimetable => get({
    AppLanguage.english: 'Weekly Timetable',
    AppLanguage.sinhala: 'සතිපතා කාලසටහන',
    AppLanguage.tamil: 'வாராந்திர பாடவேளை',
  });
  static String get todaysSchedule => get({
    AppLanguage.english: 'Today\'s Schedule',
    AppLanguage.sinhala: 'අද දින කාලසටහන',
    AppLanguage.tamil: 'இன்றைய அட்டவணை',
  });
  static String get substituteAlert => get({
    AppLanguage.english: 'Substitute Teacher Alert',
    AppLanguage.sinhala: 'ආදේශක ගුරු නිවේදනය',
    AppLanguage.tamil: 'மாற்று ஆசிரியர் எச்சரிக்கை',
  });
  static String get substitute => get({
    AppLanguage.english: 'Substitute',
    AppLanguage.sinhala: 'ආදේශක',
    AppLanguage.tamil: 'மாற்று',
  });
  static String get period => get({
    AppLanguage.english: 'Period',
    AppLanguage.sinhala: 'පීරියඩ් එක',
    AppLanguage.tamil: 'பாடவேளை',
  });
  static String get interval => get({
    AppLanguage.english: 'Interval / Lunch',
    AppLanguage.sinhala: 'විවේක කාලය',
    AppLanguage.tamil: 'இடைவேளை',
  });
  static String get noTimetable => get({
    AppLanguage.english: 'Timetable not available for this class.',
    AppLanguage.sinhala: 'මෙම පන්තිය සඳහා කාලසටහනක් නොමැත.',
    AppLanguage.tamil: 'இந்த வகுப்பிற்கு பாடவேளை அட்டவணை கிடைக்கவில்லை.',
  });
  static String get monday => get({
    AppLanguage.english: 'Monday',
    AppLanguage.sinhala: 'සඳුදා',
    AppLanguage.tamil: 'திங்கள்',
  });
  static String get tuesday => get({
    AppLanguage.english: 'Tuesday',
    AppLanguage.sinhala: 'අඟහරුවාදා',
    AppLanguage.tamil: 'செவ்வாய்',
  });
  static String get wednesday => get({
    AppLanguage.english: 'Wednesday',
    AppLanguage.sinhala: 'බදාදා',
    AppLanguage.tamil: 'புதன்',
  });
  static String get thursday => get({
    AppLanguage.english: 'Thursday',
    AppLanguage.sinhala: 'බ්‍රහස්පතින්දා',
    AppLanguage.tamil: 'வியாழன்',
  });
  static String get friday => get({
    AppLanguage.english: 'Friday',
    AppLanguage.sinhala: 'සිකුරාදා',
    AppLanguage.tamil: 'வெள்ளி',
  });

  // ── Notices & Circulars ────────────────────────────────────────────────────
  static String get schoolNotices => get({
    AppLanguage.english: 'School Notices',
    AppLanguage.sinhala: 'පාසල් නිවේදන',
    AppLanguage.tamil: 'பள்ளி அறிவிப்புகள்',
  });
  static String get circulars => get({
    AppLanguage.english: 'School Circulars',
    AppLanguage.sinhala: 'පාසල් චක්‍රලේඛ',
    AppLanguage.tamil: 'பள்ளி சுற்றறிக்கைகள்',
  });
  static String get allGrades => get({
    AppLanguage.english: 'All Grades',
    AppLanguage.sinhala: 'සියලු ශ්‍රේණි',
    AppLanguage.tamil: 'அனைத்து தரங்கள்',
  });
  static String get urgentNotice => get({
    AppLanguage.english: 'URGENT',
    AppLanguage.sinhala: 'හදිසි',
    AppLanguage.tamil: 'அவசரம்',
  });
  static String get noNotices => get({
    AppLanguage.english: 'No active notices at this moment.',
    AppLanguage.sinhala: 'දැනට නව නිවේදන නොමැත.',
    AppLanguage.tamil: 'தற்போது எந்த அறிவிப்புகளும் இல்லை.',
  });
  static String get noAnnouncements => get({
    AppLanguage.english: 'No announcements at this moment.',
    AppLanguage.sinhala: 'දැනට නව නිවේදන නොමැත.',
    AppLanguage.tamil: 'தற்போது எந்த அறிவிப்புகளும் இல்லை.',
  });

  // ── Progress & Academics ───────────────────────────────────────────────────
  static String get academicProgress => get({
    AppLanguage.english: 'Academic Progress',
    AppLanguage.sinhala: 'අධ්‍යාපනික ප්‍රගතිය',
    AppLanguage.tamil: 'கல்வி முன்னேற்றம்',
  });
  static String get downloadReportCard => get({
    AppLanguage.english: 'Download Report Card',
    AppLanguage.sinhala: 'ප්‍රගති වාර්තාව බාගන්න',
    AppLanguage.tamil: 'அறிக்கை அட்டையைப் பதிவிறக்கவும்',
  });

  static String get selectTerm => get({
    AppLanguage.english: 'Select Term',
    AppLanguage.sinhala: 'වාරය තෝරන්න',
    AppLanguage.tamil: 'தவணையைத் தேர்ந்தெடுக்கவும்',
  });
  static String get allTerms => get({
    AppLanguage.english: 'All Terms',
    AppLanguage.sinhala: 'සියලු වාර',
    AppLanguage.tamil: 'அனைத்து தவணைகள்',
  });
  static String get term1 => get({
    AppLanguage.english: 'Term 1',
    AppLanguage.sinhala: '1 වන වාරය',
    AppLanguage.tamil: 'முதல் தவணை',
  });
  static String get term2 => get({
    AppLanguage.english: 'Term 2',
    AppLanguage.sinhala: '2 වන වාරය',
    AppLanguage.tamil: 'இரண்டாம் தவணை',
  });
  static String get term3 => get({
    AppLanguage.english: 'Term 3',
    AppLanguage.sinhala: '3 වන වාරය',
    AppLanguage.tamil: 'மூன்றாம் தவணை',
  });
  static String get termAverage => get({
    AppLanguage.english: 'Term Average',
    AppLanguage.sinhala: 'වාර සාමාන්‍යය',
    AppLanguage.tamil: 'தவணை சராசரி',
  });
  static String get totalMarks => get({
    AppLanguage.english: 'Total Marks',
    AppLanguage.sinhala: 'මුළු ලකුණු',
    AppLanguage.tamil: 'மொத்த மதிப்பெண்கள்',
  });
  static String get topSubject => get({
    AppLanguage.english: 'Top Subject',
    AppLanguage.sinhala: 'ඉහළම විෂය',
    AppLanguage.tamil: 'சிறந்த பாடம்',
  });
  static String get needsFocus => get({
    AppLanguage.english: 'Needs Focus',
    AppLanguage.sinhala: 'අවධානය අවශ්‍යයි',
    AppLanguage.tamil: 'கவனம் தேவை',
  });
  static String get noMarksForTerm => get({
    AppLanguage.english: 'No marks recorded for this term yet.',
    AppLanguage.sinhala: 'මෙම වාරය සඳහා තවමත් ලකුණු සටහන් කර නොමැත.',
    AppLanguage.tamil: 'இந்த தவணைக்கான மதிப்பெண்கள் இன்னும் பதிவு செய்யப்படவில்லை.',
  });

  static String get subjects => get({
    AppLanguage.english: 'Subjects',
    AppLanguage.sinhala: 'විෂයයන්',
    AppLanguage.tamil: 'பாடங்கள்',
  });

  // ── A/L Advisor & EWS ──────────────────────────────────────────────────────
  static String get alAdvisor => get({
    AppLanguage.english: 'A/L Stream Advisor',
    AppLanguage.sinhala: 'උ/පෙළ අංශ උපදේශක',
    AppLanguage.tamil: 'உ/த பிரிவு ஆலோசகர்',
  });
  static String get streamPredictor => get({
    AppLanguage.english: 'Stream Predictor',
    AppLanguage.sinhala: 'අංශ පුරෝකථනය',
    AppLanguage.tamil: 'பிரிவு கணிப்பான்',
  });
  static String get bioScience => get({
    AppLanguage.english: 'Bio Science',
    AppLanguage.sinhala: 'ජීව විද්‍යා අංශය',
    AppLanguage.tamil: 'உயிரியல் அறிவியல்',
  });
  static String get mathsStream => get({
    AppLanguage.english: 'Physical Science (Maths)',
    AppLanguage.sinhala: 'භෞතික විද්‍යා (ගණිත) අංශය',
    AppLanguage.tamil: 'இயற்பியல் அறிவியல் (கணிதம்)',
  });
  static String get commerceStream => get({
    AppLanguage.english: 'Commerce',
    AppLanguage.sinhala: 'වාණිජ අංශය',
    AppLanguage.tamil: 'வணிகப் பிரிவு',
  });
  static String get technologyStream => get({
    AppLanguage.english: 'Technology',
    AppLanguage.sinhala: 'තාක්ෂණවේදය අංශය',
    AppLanguage.tamil: 'தொழில்நுட்பப் பிரிவு',
  });
  static String get artsStream => get({
    AppLanguage.english: 'Arts',
    AppLanguage.sinhala: 'කලා අංශය',
    AppLanguage.tamil: 'கலைப் பிரிவு',
  });
  static String get eligible => get({
    AppLanguage.english: 'Eligible',
    AppLanguage.sinhala: 'සුදුසුකම් ලත්',
    AppLanguage.tamil: 'தகுதியுடையது',
  });
  static String get borderline => get({
    AppLanguage.english: 'Borderline',
    AppLanguage.sinhala: 'සීමාකාරී',
    AppLanguage.tamil: 'விளிம்புநிலை',
  });
  static String get notEligible => get({
    AppLanguage.english: 'Not Eligible',
    AppLanguage.sinhala: 'සුදුසුකම් නොලත්',
    AppLanguage.tamil: 'தகுதியற்றது',
  });
  static String get earlyWarning => get({
    AppLanguage.english: 'Early Warning System',
    AppLanguage.sinhala: 'මුල් අනතුරු ඇඟවීමේ පද්ධතිය',
    AppLanguage.tamil: 'ஆரம்ப எச்சரிக்கை அமைப்பு',
  });
  static String get academicHealth => get({
    AppLanguage.english: 'Academic Health Indicator',
    AppLanguage.sinhala: 'අධ්‍යාපනික සෞඛ්‍ය දර්ශකය',
    AppLanguage.tamil: 'கல்வி நலக் காட்டி',
  });

  // ── Settings Screen ────────────────────────────────────────────────────────
  static String get settings => get({
    AppLanguage.english: 'Settings',
    AppLanguage.sinhala: 'සැකසුම්',
    AppLanguage.tamil: 'அமைப்புகள்',
  });
  static String get profile => get({
    AppLanguage.english: 'Profile',
    AppLanguage.sinhala: 'පැතිකඩ',
    AppLanguage.tamil: 'சுயவிவரம்',
  });
  static String get language => get({
    AppLanguage.english: 'Language',
    AppLanguage.sinhala: 'භාෂාව',
    AppLanguage.tamil: 'மொழி',
  });
  static String get darkMode => get({
    AppLanguage.english: 'Dark Mode',
    AppLanguage.sinhala: 'අඳුරු තේමාව',
    AppLanguage.tamil: 'இருண்ட பயன்முறை',
  });
  static String get notifications => get({
    AppLanguage.english: 'Push Notifications',
    AppLanguage.sinhala: 'දැනුම්දීම්',
    AppLanguage.tamil: 'அறிவிப்புகள்',
  });
  static String get logout => get({
    AppLanguage.english: 'Logout',
    AppLanguage.sinhala: 'පිටවීම',
    AppLanguage.tamil: 'வெளியேறு',
  });
  static String get logoutConfirm => get({
    AppLanguage.english: 'Are you sure you want to log out?',
    AppLanguage.sinhala: 'ඔබට නිසැකවම පිටවීමට අවශ්‍යද?',
    AppLanguage.tamil: 'நிச்சயமாக வெளியேற விரும்புகிறீர்களா?',
  });
  static String get cancel => get({
    AppLanguage.english: 'Cancel',
    AppLanguage.sinhala: 'අවලංගු කරන්න',
    AppLanguage.tamil: 'ரத்து செய்',
  });
  static String get save => get({
    AppLanguage.english: 'Save',
    AppLanguage.sinhala: 'සුරකින්න',
    AppLanguage.tamil: 'சேமி',
  });
}
