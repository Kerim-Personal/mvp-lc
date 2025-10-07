// lib/screens/vocabot_chat_screen.dart
// This is not a chat screen, it's a language universe simulator.
// v2.4.0: Star animations have been calmed and naturalized. The environment is now authentic and not distracting.

import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:vocachat/services/vocabot_service.dart';
import 'package:vocachat/models/grammar_analysis.dart';
import 'package:vocachat/models/message_unit.dart';
import 'package:vocachat/widgets/linguabot/linguabot.dart';
import 'package:vocachat/utils/text_metrics.dart';
import 'package:vocachat/widgets/message_composer.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:circle_flags/circle_flags.dart';
import 'package:vocachat/services/local_chat_storage.dart';
import 'package:vocachat/models/lesson_model.dart';
import 'package:vocachat/services/streak_service.dart';

// --- MAIN SCREEN: THE HEART OF THE SIMULATOR ---

class LinguaBotChatScreen extends StatefulWidget {
  final bool isPremium;
  const LinguaBotChatScreen({super.key, this.isPremium = false});

  @override
  State<LinguaBotChatScreen> createState() => _LinguaBotChatScreenState();
}

class _LinguaBotChatScreenState extends State<LinguaBotChatScreen> with TickerProviderStateMixin, WidgetsBindingObserver {
  late LinguaBotService _botService; // hedef dil değiştikçe yeniden oluşturulacak
  final ScrollController _scrollController = ScrollController();
  final List<MessageUnit> _messages = [];
  bool _isBotThinking = false;
  String _nativeLanguage = 'en';
  String _targetLanguage = 'en'; // öğrenilmek istenen dil
  String _learningLevel = 'medium'; // kullanıcının seçtiği seviye
  bool _botReady = false;
  bool _isPremium = false;
  bool _allowPop = false; // allow programmatic pop after confirm
  bool _composerEmojiOpen = false; // composer emoji panel durumu
  String? _scenario; // seçili senaryo
  bool _showScrollToBottom = false; // scroll to bottom butonunu göster/gizle

  // Desteklenen diller (öğrenilecek dil seçenekleri)
  static const Map<String, String> _supportedLanguages = {
    'en': 'English',
    'es': 'Spanish',
    'de': 'German',
    'fr': 'French',
    'tr': 'Turkish',
    'it': 'Italian',
    'pt': 'Portuguese',
    // New languages
    'ar': 'Arabic',
    'ru': 'Russian',
    'ja': 'Japanese',
    'ko': 'Korean',
    'zh': 'Chinese',
    'nl': 'Dutch',
    'sv': 'Swedish',
    // Yeni eklenenler
    'pl': 'Polish',
    'el': 'Greek',
    'hu': 'Hungarian',
    'cs': 'Czech',
    'da': 'Danish',
    'fi': 'Finnish',
    'no': 'Norwegian',
    'th': 'Thai',
    'hi': 'Hindi',
    'id': 'Indonesian',
    'vi': 'Vietnamese',
    'uk': 'Ukrainian',
    'ro': 'Romanian',
    // Yeni eklenen genişletilmiş set
    'bg': 'Bulgarian',
    'hr': 'Croatian',
    'sr': 'Serbian',
    'sk': 'Slovak',
    'sl': 'Slovenian',
    'fa': 'Persian',
    'ms': 'Malay',
    'tl': 'Filipino',
    'bn': 'Bengali',
    'ur': 'Urdu',
    'sw': 'Swahili',
    'af': 'Afrikaans',
    'et': 'Estonian',
    'lt': 'Lithuanian',
    'lv': 'Latvian',
    // Ek genişletme
    'ga': 'Irish',
    'sq': 'Albanian',
    'bs': 'Bosnian',
    'mk': 'Macedonian',
    'az': 'Azerbaijani',
    'ka': 'Georgian',
    'am': 'Amharic',
    'kk': 'Kazakh',
    'mn': 'Mongolian',
    'ne': 'Nepali',
    'ta': 'Tamil',
    'te': 'Telugu',
    'gu': 'Gujarati',
    'mr': 'Marathi',
    'kn': 'Kannada',
    'si': 'Sinhala',
    // Değer katan eklemeler (ML Kit destekli)
    'ca': 'Catalan',
    'gl': 'Galician',
    'be': 'Belarusian',
    'is': 'Icelandic',
    'mt': 'Maltese',
    // Kolay bayraklı yeni eklenenler
    'pa': 'Punjabi',
    'ml': 'Malayalam',
    'or': 'Odia',
    'as': 'Assamese',
    'km': 'Khmer',
    'my': 'Burmese',
    'lo': 'Lao',
    'eu': 'Basque',
    'hy': 'Armenian',
    'cy': 'Welsh',
    'uz': 'Uzbek',
    'ps': 'Pashto',
    'ha': 'Hausa',
    'yo': 'Yoruba',
    'ig': 'Igbo',
    'so': 'Somali',
    'zu': 'Zulu',
    'xh': 'Xhosa',
    'tg': 'Tajik',
    'tk': 'Turkmen',
    'ky': 'Kyrgyz',
    // Newly added languages
    'yue': 'Cantonese', // Yue Chinese (spoken); written form reuses Chinese characters
    'eo': 'Esperanto',
    'ht': 'Haitian Creole',
    // Newly added (user request)
    'mi': 'Maori',
    'gn': 'Guarani',
    'qu': 'Quechua',
    'om': 'Oromo',
    'mg': 'Malagasy',
    'rw': 'Kinyarwanda',
    'rn': 'Kirundi',
    'sn': 'Shona',
    'tn': 'Tswana',
    'dz': 'Dzongkha',
    'jv': 'Javanese',
    'gd': 'Scottish Gaelic',
    'me': 'Montenegrin',
  };

  // Dil kodları ile bayrak kodları eşleştirmesi
  static const Map<String, String> _languageFlags = {
    'en': 'gb', // İngilizce için İngiltere bayrağı
    'es': 'es',
    'de': 'de',
    'fr': 'fr',
    'tr': 'tr',
    'it': 'it',
    'pt': 'pt',
    // New flags
    'ar': 'sa', // Arabic - Saudi Arabia flag
    'ru': 'ru',
    'ja': 'jp',
    'ko': 'kr',
    'zh': 'cn',
    'nl': 'nl',
    'sv': 'se',
    // Yeni eklenenler
    'pl': 'pl',
    'el': 'gr',
    'hu': 'hu',
    'cs': 'cz',
    'da': 'dk',
    'fi': 'fi',
    'no': 'no',
    'th': 'th',
    'hi': 'in',
    'id': 'id',
    'vi': 'vn',
    'uk': 'ua',
    'ro': 'ro',
    // Yeni eklenenler
    'bg': 'bg',
    'hr': 'hr',
    'sr': 'rs',
    'sk': 'sk',
    'sl': 'si',
    'fa': 'ir',
    'ms': 'my',
    'tl': 'ph',
    'bn': 'bd',
    'ur': 'pk',
    'sw': 'ke',
    'af': 'za',
    'et': 'ee', // Estonian
    'lt': 'lt',
    'lv': 'lv',
    // Ek genişletme (doğru bayrak eşleşmeleri)
    'ga': 'ie', // Irish Gaelic -> Ireland
    'sq': 'al', // Albanian -> Albania
    'bs': 'ba', // Bosnian -> Bosnia and Herzegovina
    'mk': 'mk', // Macedonian -> North Macedonia
    'az': 'az', // Azerbaijani -> Azerbaijan
    'ka': 'ge', // Georgian -> Georgia
    'am': 'et', // Amharic -> Ethiopia (daha önce fallback Armenia idi)
    'kk': 'kz', // Kazakh -> Kazakhstan
    'mn': 'mn', // Mongolian -> Mongolia
    'ne': 'np', // Nepali -> Nepal (fallback Niger yanlış olurdu)
    'ta': 'in', // Tamil -> India (ana konuşur nüfus)
    'te': 'in', // Telugu -> India
    'gu': 'in', // Gujarati -> India (fallback Guam olmaz)
    'mr': 'in', // Marathi -> India (fallback Mauritania yanlış)
    'kn': 'in', // Kannada -> India (fallback St Kitts & Nevis yanlış)
    'si': 'lk', // Sinhala -> Sri Lanka (fallback Slovenia yanlış)
    // Eklenenler
    'ca': 'ad', // Catalan -> Andorra (tarafsız seçim)
    'gl': 'es', // Galician -> Spain
    'be': 'by', // Belarusian -> Belarus
    'is': 'is', // Icelandic -> Iceland
    'mt': 'mt', // Maltese -> Malta
    // Yeni eklenenler (kolay bayrak)
    'pa': 'in', // Punjabi
    'ml': 'in', // Malayalam
    'or': 'in', // Odia
    'as': 'in', // Assamese
    'km': 'kh', // Khmer -> Cambodia
    'my': 'mm', // Burmese -> Myanmar
    'lo': 'la', // Lao -> Laos
    'eu': 'es', // Basque -> Spain (çoğunluk)
    'hy': 'am', // Armenian -> Armenia
    'cy': 'gb', // Welsh -> United Kingdom
    'uz': 'uz', // Uzbek -> Uzbekistan
    'ps': 'af', // Pashto -> Afghanistan (primer)
    'ha': 'ng', // Hausa -> Nigeria (en büyük nüfus)
    'yo': 'ng', // Yoruba -> Nigeria
    'ig': 'ng', // Igbo -> Nigeria
    'so': 'so', // Somali -> Somalia
    'zu': 'za', // Zulu -> South Africa
    'xh': 'za', // Xhosa -> South Africa
    'tg': 'tj', // Tajik -> Tajikistan
    'tk': 'tm', // Turkmen -> Turkmenistan
    'ky': 'kg', // Kyrgyz -> Kyrgyzstan
    // Newly added flags
    'yue': 'hk', // Cantonese -> Hong Kong flag as primary locale
    'eo': 'un', // Esperanto -> using UN flag as neutral fallback (library must support; else consider 'ad' or a generic)
    'ht': 'ht', // Haitian Creole -> Haiti
    // Newly added flags (user request)
    'mi': 'nz', // Maori -> New Zealand
    'gn': 'py', // Guarani -> Paraguay
    'qu': 'pe', // Quechua -> Peru (principal modern association)
    'om': 'et', // Oromo -> Ethiopia (shared with Amharic)
    'mg': 'mg', // Malagasy -> Madagascar
    'rw': 'rw', // Kinyarwanda -> Rwanda
    'rn': 'bi', // Kirundi -> Burundi
    'sn': 'zw', // Shona -> Zimbabwe
    'tn': 'bw', // Tswana -> Botswana
    'dz': 'bt', // Dzongkha -> Bhutan
    'jv': 'id', // Javanese -> Indonesia
    'gd': 'gb-sct', // Scottish Gaelic -> Scotland flag (subdivision)
    'me': 'me', // Montenegrin -> Montenegro
  };

  // Açılış selamları (hedef öğrenilen dilde)
  static const Map<String, String> _welcomeMessages = {
    'en': 'Welcome back to the language universe. Ready to push your limits?',
    'es': 'Bienvenido de nuevo al universo de los idiomas. ¿Listo para superarte?',
    'de': 'Willkommen zurück im Sprachen-Universum. Bereit, deine Grenzen zu pushen?',
    'fr': 'Bon retour dans l’univers des langues. Prêt(e) à repousser tes limites?',
    'tr': 'Dil evrenine tekrar hoş geldin. Sınırlarını zorlamaya hazır mısın?',
    'it': 'Bentornato nell\'universo delle lingue. Pronto a superare i tuoi limiti?',
    'pt': 'Bem-vindo de volta ao universo dos idiomas. Pronto para ir além?',
    // New language welcomes
    'ar': 'مرحبًا بعودتك إلى كون اللغات. هل أنت مستعد لتتحدى حدودك؟',
    'ru': 'С возвращением во вселенную языков. Готов расширять свои границы?',
    'ja': '言語の宇宙へようこそ。限界に挑戦する準備はできた？',
    'ko': '언어의 우주에 다시 온 걸 환영해. 한계를 넘어볼 준비 됐어?',
    'zh': '欢迎回到语言宇宙。准备好挑战你的极限了吗？',
    'nl': 'Welkom terug in het taaluniversum. Klaar om je grenzen te verleggen?',
    'sv': 'Välkommen tillbaka till språkets universum. Redo att tänja på dina gränser?',
    // Yeni eklenenler
    'pl': 'Witaj ponownie w językowym uniwersum. Gotowy na wyzwanie?',
    'el': 'Καλώς επέστρεψες στο σύμπαν των γλωσσών. Έτοιμος για πρόκληση;',
    'hu': 'Üdv újra a nyelvi univerzumban. Készen állsz a kihívásra?',
    'cs': 'Vítej zpět ve vesmíru jazyků. Připraven posunout své limity?',
    'da': 'Velkommen tilbage til sproguniverset. Klar til at presse dine grænser?',
    'fi': 'Tervetuloa takaisin kieliuniversumiin. Valmis haastamaan rajasi?',
    'no': 'Velkommen tilbake til språkuniverset. Klar til å presse grensene dine?',
    'th': 'ยินดีต้อนรับกลับสู่จักรวาลภาษา พร้อมท้าทายขีดจำกัดไหม?',
    'hi': 'भाषा ब्रह्मांड में फिर स्वागत है। तैयार हो अपनी सीमाएँ बढ���ाने के लिए?',
    'id': 'Selamat datang kembali di jagat bahasa. Siap menantang batasmu?',
    'vi': 'Chào mừng trở lại vũ trụ ngôn ngữ. Sẵn sàng thử thách giới hạn chứ?',
    'uk': 'Ласкаво просимо назад у мовний всесвіт. Готовий розширювати межі?',
    'ro': 'Bine ai revenit în universul limbilor. Gata să îți depășești limitele?',
    // Yeni eklenen genişletilmiş set
    'bg': 'Добре дошъл отново в езиковата вселена. Готов ли си?',
    'hr': 'Dobrodošao natrag u svemir jezika. Spreman?',
    'sr': 'Добро вратио си се у језички универзум. Спреман?',
    'sk': 'Vitaj späť vo vesmíre jazykov. Pripravený?',
    'sl': 'Dobrodošel nazaj v jezikovnem vesolju. Pripravljen?',
    'fa': 'به دنیای زبان‌ها برگشتی، آماده‌ای خودت را به چالش بکشی؟',
    'ms': 'Selamat kembali ke alam bahasa. Sedia cabar diri?',
    'tl': 'Balik ka na sa uniberso ng wika. Handa ka na ba?',
    'bn': 'ভাষার মহাবিশ্বে আবার স্বাগতম। প্রস্তুত তো?',
    'ur': 'زبانوں کی کائنات میں واپسی پر خوش آمدید، تیار ہو؟',
    'sw': 'Karibu tena kwenye ulimwengu wa lugha. Uko tayari?',
    'af': 'Welkom terug in die taalheelal. Gereed?',
    'et': 'Tere tulemast tagasi keelte universumisse. Valmis?',
    'lt': 'Sveikas sugrįžęs į kalbų visatą. Pasiruošęs?',
    'lv': 'Laipni lūdzam atpakaļ valodu visumā. Gatavs?',
    // Ek genişletme
    'ga': 'Fáilte ar ais chuig cruinne na dteangacha. Réidh?',
    'sq': 'Mirë se u ktheve në universin e gjuhëve. Gati?',
    'bs': 'Dobrodošao nazad u svemir jezika. Spreman?',
    'mk': 'Добредојде назад во јазичната вселена. Подготвен?',
    'az': 'Dil kainatına yenidən xoş gəldin. Hazırsan?',
    'ka': 'კეთილი იყოს შენი დაბრუნება ენების სამყაროში. მზად ხარ?',
    'am': 'እንኳን ወደ ቋንቋዎች አለም በደህና መጣህ። ዝግጁ ነህ?',
    'kk': 'Тілдер әлеміне қайта қош келдің. Дайынсың ба?',
    'mn': 'Хэлний ертөнцөд дахин тавтай морил. Бэлэн үү?',
    'ne': 'भाषा ब्रह्माण्डमा फेरि स्वागत छ। तयार?',
    'ta': 'மொழி பிரபஞ்சத்திற்கு மறுபடியும் வரவேற்கிறேன். தயார்?',
    'te': 'భాషా విశ్వానికి తిరిగి స్వాగతం. సిద్ధమేనా?',
    'gu': 'ભાષા બ્રહ્માંડમાં ફરી સ્વાગત. તૈયાર?',
    'mr': 'भाषा विश्वात परत स्वागत. तयार?',
    'kn': 'ಭಾಷಾ ಬ್ರಹ್ಮಾಂಡಕ್ಕೆ ಮರಳಿ ಸುಸ್ವಾಗತ. ಸಿದ್ಧವಾ?',
    'si': 'භාෂා බ්‍රහ්මාණ්ඩයට නැවත සාදරයෙන් පිළිගන්නවා. සූදානම්ද?',
    // Yeni eklenenler
    'ca': 'Benvingut de nou a l\'univers de les llengües. Preparat?',
    'gl': 'Benvido de novo ao universo das linguas. Listo?',
    'be': 'Вітаем зноў у моўным сусвеце. Гатовы?',
    'is': 'Velkominn aftur í tungumálaalheiminn. Tilbúinn?',
    'mt': 'Merħba lura fl-univers tal-lingwi. Lest?',
    // Yeni eklenen karşılamalar
    'pa': 'ਭਾਸ਼ਾ ਬ੍ਰਹਿਮੰਡ ਵਿੱਚ ਵਾਪਸ ਸਵਾਗਤ ਹੈ। ਤਿਆਰ?',
    'ml': 'ഭാഷാ ബ്രഹ്മാണ്ഡത്തിലേക്ക് വീണ്ടും സ്വാഗതം. തയ്യാറ��?',
    'or': 'ଭାଷା ବ୍ରହ୍ମାଣ୍ଡକୁ ପୁନଃ ସ୍ୱାଗତ। ପ୍ରସ୍ତୁତ?',
    'as': 'ভাষাৰ মহাবিশ্বৰলৈ আকৌ স্বাগতম। প্ৰস্তুত?',
    'km': 'សូមស្វាគមន៍ត្រឡប់មកកាន់ចក្រវាលភាសា។ រៀបចំរួចហើយ?',
    'my': 'ဘာသာစကားဗဟုလောကသို့ ပြန်လာခြင်းကို ကြိုဆိုပါသည်။ အဆင်သင့်လား?',
    'lo': 'ຍິນດີຕ້ອນຮັບກັບສູ່ຈັກກະວານພາສາ. ພ້ອມບໍ?',
    'eu': 'Ongi etorri berriro hizkuntzen unibertsora. Prest?',
    'hy': 'Բարի վերադարձ լեզուների տիեզերք։ Պատրա՞ստ ես։',
    'cy': 'Croeso yn ôl i fydysawd yr ieithoedd. Barod?',
    'uz': 'Til olamiga qaytganingga xush kelibsan. Tayyor?',
    'ps': 'بېرته د ژبو کاینات ته ښه راغلې. تیار یې؟',
    'ha': 'Barka da dawowa zuwa sararin harsuna. Shirye kake?',
    'yo': 'Kaabo sí ayé èdè lẹ́ẹ̀kansi. Ṣé ṣetán?',
    'ig': 'Nnọọ azụ na ụwa asụsụ. Ị kwadebere?',
    'so': 'Ku soo dhawoow mar kale caalamka luqadaha. Diyaar miyaa?',
    'zu': 'Uyemukelwa futhi emkhathini wezilimi. Ulungele?',
    'xh': 'Wamkelekile kwakhona kwindalo yeelwimi. Ulungile?',
    'tg': 'Боз ба коиноти забонҳо хуш омадед. Омодаед?',
    'tk': 'Dil älemine gaýdyp geldiň. Taýýar?',
    'ky': 'Тилдер ааламына кайра кош келиңиз. Даярсызбы?',
    // Newly added welcome messages
    'yue': '歡迎返嚟語言宇宙。準備好未？', // Cantonese (Traditional script)
    'eo': 'Bonvenon reen al la lingva universo. Pretas?',
    'ht': 'Byenveni tounen nan inivè lang yo. Pare?',
    // Newly added welcome messages (user request)
    'mi': 'Haere mai anō ki te ao reo. Kua rite?',
    'gn': 'Ejujey ñeʼẽ arapýpe. ¿Ikatúpa?',
    'qu': 'Simikuna pachasman kutiy. Listo kachkanki?',
    'om': 'Baga gara unka afaanotaatti deebiʼte. Qophiidhaa?',
    'mg': 'Tongasoa indray eto amin\'ny tontolon\'ny fiteny. Vonona?',
    'rw': 'Murakaza neza kongera mu isanzure ry\'indimi. Witeguye?',
    'rn': 'Urakaze gusubira mu isi y\'indimi. Witeguye?',
    'sn': 'Gamuchirai zvakare munyika yemitauro. Wakagadzirira?',
    'tn': 'O amogetswe gape mo lefatsheng la diteme. O lokile?',
    'dz': 'སྐད་ཡིག་ཀྱི་འཛམ་གླིང་ལ་ལོག་འབྱོར་བཀའ་དྲིན་ཆེ། གྲ་སྒྲིག་ཡོད་མིན?',
    'jv': 'Sugeng rawuh maneh ing jagad basa. Siyap?',
    'gd': 'Fàilte air ais do chruinne nan cànan. Deiseil?',
    'me': 'Dobrodošao nazad u jezički svemir. Spreman?',
  };

  late AnimationController _backgroundController;
  late AnimationController _entryController;
  late Animation<double> _blurAnimation;

  // Oturum süresi takibi (leaderboard için totalRoomTime)
  DateTime? _sessionStart;
  static const int _maxSessionSeconds = 6 * 60 * 60; // 6 saat güvenlik sınırı

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _sessionStart = DateTime.now();

    _backgroundController = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat();
    _entryController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _blurAnimation = Tween<double>(begin: 20.0, end: 0.0).animate(CurvedAnimation(parent: _entryController, curve: Curves.easeOut));

    // Eski: İngilizce sabit mesaj ekleniyordu. Artık profil yüklendikten sonra hedef dile göre eklenecek.
    _entryController.forward();
    _loadUserProfile();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _commitAndResetSessionTime();
    _backgroundController.dispose();
    _entryController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _commitAndResetSessionTime();
    } else if (state == AppLifecycleState.resumed) {
      // Yeni dilim için başlangıcı sıfırla
      _sessionStart = DateTime.now();
    }
    super.didChangeAppLifecycleState(state);
  }

  Future<void> _commitAndResetSessionTime() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final start = _sessionStart;
    if (start == null) {
      _sessionStart = DateTime.now();
      return;
    }
    final seconds = DateTime.now().difference(start).inSeconds;
    if (seconds > 0) {
      final safeSeconds = seconds > _maxSessionSeconds ? _maxSessionSeconds : seconds;
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'totalRoomTime': FieldValue.increment(safeSeconds)});
        // Kullanıcı etkinliği gerçekleşti: streak'i güncelle
        try {
          await StreakService.updateStreakOnActivity(uid: user.uid);
        } catch (_) {
          // sessizce geç: offline veya yarış koşulu olabilir
        }
      } catch (_) {
        // sessiz: offline veya yetki hatası olabilir
      }
    }
    // Yeni dilim için başlangıcı sıfırla
    _sessionStart = DateTime.now();
  }

  Future<void> _loadUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final snap = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final data = snap.data();
      if (!mounted || data == null) return;
      setState(() {
        _nativeLanguage = (data['nativeLanguage'] as String?) ?? 'en';
        _targetLanguage = (data['learningLanguage'] as String?) ?? 'en';
        _learningLevel = (data['learningLanguageLevel'] as String?) ?? 'medium';
        _isPremium = (data['isPremium'] as bool?) ?? false;
      });
      // Yerel model indirme (on-device) kaldırıldı: Bu ekranda sadece AI tabanlı çeviri kullanılacak.
      _initBotService();
    } catch (_) {
      // sessizce geç
    }
  }

  void _initBotService() {
    _botService = LinguaBotService(targetLanguage: _targetLanguage, nativeLanguage: _nativeLanguage, learningLevel: _learningLevel);
    setState(() => _botReady = true);
    // Açılış mesajını sadece ilk kez (liste boşsa) ekle
    if (_messages.isEmpty) {
      _addWelcomeMessage();
    }
    // Hedef dile göre son 20 mesajı yükle (varsa karşılama mesajını yerini alır)
    _loadRecentMessages();
    // Scroll listener ekle
    _scrollController.addListener(_onScroll);
    // Dil değişimi durumunda scroll durumunu sıfırla
    setState(() => _showScrollToBottom = false);
  }

  // Scroll durumunu takip et
  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final position = _scrollController.position;
    final maxScroll = position.maxScrollExtent;
    final currentScroll = position.pixels;

    // Reverse ListView için:
    // - 0 = en alt (en yeni mesajlar) - BURADA BUTON GİZLENMELİ
    // - maxScrollExtent = en üst (en eski mesajlar)
    // Kullanıcı yukarı kaydırıp eski mesajlara baktığında butonu göster
    // En alttayken (currentScroll yaklaşık 0) butonu gizle
    final shouldShow = maxScroll > 50 && currentScroll > 50;

    if (shouldShow != _showScrollToBottom) {
      setState(() => _showScrollToBottom = shouldShow);
    }
  }

  Future<void> _loadRecentMessages() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final list = await LocalChatStorage.instance.load(user.uid, _targetLanguage);
    if (!mounted) return;
    if (list.isNotEmpty) {
      setState(() {
        _messages
          ..clear()
          ..addAll(list);
      });
    }
    // Artık _scrollToBottom() çağrısına gerek yok - reverse: true ile otomatik altta görünür
  }

  void _addWelcomeMessage() {
    final msg = _welcomeMessages[_targetLanguage] ?? _welcomeMessages['en']!;
    setState(() {
      _messages.add(
        MessageUnit(
          text: msg,
          sender: MessageSender.bot,
          grammarAnalysis: const GrammarAnalysis(
            tense: 'Present Simple',
            verbCount: 1,
            nounCount: 2,
            complexity: 0.3,
            sentiment: 0.7,
          ),
        ),
      );
    });
  }

  // Modern level picker (EN, with flag & language)
  Future<String?> _promptLearningLevel(String langCode) async {
    final langName = _supportedLanguages[langCode] ?? langCode.toUpperCase();
    final flagCode = _languageFlags[langCode] ?? langCode;
    const levels = [
      {'code': 'none', 'label': "None", 'desc': "I don't know it yet"},
      {'code': 'low', 'label': "A little", 'desc': "Basic words and phrases"},
      {'code': 'medium', 'label': "Intermediate", 'desc': "Can hold simple conversations"},
      {'code': 'high', 'label': "Good", 'desc': "Comfortable in most situations"},
      {'code': 'very_high', 'label': "Very good", 'desc': "Near-fluent or fluent"},
    ];

    String tempSelected = _learningLevel; // pre-select current

    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black.withAlpha(235),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) {
        final bottomInset = MediaQuery.of(ctx).viewInsets.bottom;
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding: EdgeInsets.only(bottom: bottomInset > 0 ? bottomInset : 16),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(18),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.cyanAccent.withAlpha(100), width: 1),
                            ),
                            child: CircleFlag(flagCode, size: 24),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Select your level',
                                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                                ),
                                Text(
                                  langName,
                                  style: TextStyle(color: Colors.cyanAccent.withAlpha(220), fontSize: 13, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(null),
                            icon: const Icon(Icons.close, color: Colors.white70),
                          )
                        ],
                      ),
                      const SizedBox(height: 6),
                      ...levels.map((lvl) {
                        final code = lvl['code'] as String;
                        final isSelected = tempSelected == code;
                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: isSelected ? Colors.cyanAccent : Colors.white24, width: 1),
                            color: isSelected ? Colors.cyanAccent.withAlpha(22) : Colors.white.withAlpha(10),
                          ),
                          child: RadioListTile<String>(
                            value: code,
                            groupValue: tempSelected,
                            onChanged: (v) => setSheetState(() => tempSelected = v ?? tempSelected),
                            activeColor: Colors.cyanAccent,
                            dense: true,
                            title: Text(
                              lvl['label'] as String,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              lvl['desc'] as String,
                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: Colors.white24),
                                foregroundColor: Colors.white70,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: () => Navigator.of(context).pop(null),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.cyanAccent,
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: () => Navigator.of(context).pop(tempSelected),
                              child: const Text('Save level'),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _changeTargetLanguage(String newCode, {String? level}) async {
    final isSameLanguage = newCode == _targetLanguage;
    if (isSameLanguage && (level == null || level == _learningLevel)) return; // değişiklik yok
    final user = FirebaseAuth.instance.currentUser;
    setState(() => _botReady = false);
    try {
      if (user != null) {
        final Map<String, dynamic> payload = {};
        if (!isSameLanguage) payload['learningLanguage'] = newCode;
        if (level != null) payload['learningLanguageLevel'] = level;
        if (payload.isNotEmpty) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set(payload, SetOptions(merge: true));
        }
      }
    } catch (_) {
      // offline vs yetki: kullanıcıya yine de yerel güncelleme
    }
    setState(() {
      if (!isSameLanguage) {
        _targetLanguage = newCode;
        _messages.clear(); // Dil değişince sohbet temizlenir
      }
      if (level != null) _learningLevel = level;
    });
    _initBotService();
  }

  // Dil kartı tıklananca: aynı dilse sadece seviye değiştir, farklıysa seviye sorup dili değiştir
  Future<void> _onSelectLanguage(String langCode) async {
    if (langCode == _targetLanguage) {
      final selected = await _promptLearningLevel(langCode);
      if (selected == null || selected == _learningLevel) return;
      await _changeTargetLanguage(langCode, level: selected);
      if (mounted) Navigator.of(context).pop();
      return;
    }
    final selected = await _promptLearningLevel(langCode);
    if (selected == null) return; // kullanıcı vazgeçti
    await _changeTargetLanguage(langCode, level: selected);
    if (mounted) Navigator.of(context).pop(); // ayarlar ekranını kapat
  }

  List<String> _computeSuggestions() {
    // Kullanıcı isteği: tüm hazır öneri cümleleri kaldırıldı.
    return const [];
  }

  Widget _buildLanguageTile(String langCode) {
    final langName = _supportedLanguages[langCode]!;
    final isSelected = langCode == _targetLanguage;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6), // biraz daha dar
      decoration: BoxDecoration(
        gradient: isSelected
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.cyanAccent.withAlpha(55),
                  Colors.cyanAccent.withAlpha(15),
                ],
              )
            : LinearGradient(
                colors: [
                  const Color(0xFF1B1B1B),
                  Colors.black.withAlpha(150),
                ],
              ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected ? Colors.cyanAccent : Colors.cyanAccent.withAlpha(40),
          width: isSelected ? 1.6 : 1.0,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            _onSelectLanguage(langCode);
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedScale(
                scale: isSelected ? 1.07 : 1.0,
                duration: const Duration(milliseconds: 180),
                child: CircleFlag(
                  _languageFlags[langCode] ?? langCode,
                  size: 42, // eski boyuta yakın
                ),
              ),
              const SizedBox(height: 5),
              Text(
                langName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isSelected ? Colors.cyanAccent : Colors.white70,
                  fontSize: 12.5,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  letterSpacing: 0.15,
                ),
              ),
              if (isSelected)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  width: 20,
                  height: 2,
                  decoration: BoxDecoration(
                    color: Colors.cyanAccent,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _sendMessage(String text) async {
    if (text.isEmpty || !_botReady) return;

    // Gramer analizi: her durumda paralel başlat
    final Future<GrammarAnalysis?> analysisFuture = _botService.analyzeGrammar(text);

    final userMessage = MessageUnit(
      text: text,
      sender: MessageSender.user,
      grammarAnalysis: null, // analiz hazır olduğunda doldurulacak
      vocabularyRichness: TextMetrics.vocabularyRichness(text),
    );

    setState(() {
      _messages.add(userMessage);
      _isBotThinking = true;
    });
    // Yerel kaydet (kullanıcı mesajı eklendi)
    final u1 = FirebaseAuth.instance.currentUser;
    if (u1 != null) {
      LocalChatStorage.instance.save(u1.uid, _targetLanguage, _messages);
    }

    // Analiz tamamlanınca mesajı güncelle
    analysisFuture.then((analysis) {
      if (!mounted) return;
      if (analysis != null) {
        setState(() {
          final idx = _messages.indexWhere((m) => m.id == userMessage.id);
          if (idx != -1) {
            _messages[idx].grammarAnalysis = analysis;
          }
        });
        // Analiz güncellemesi sonrası da kaydetmek gerekmiyor; sadece metinler saklanıyor.
      }
    }).catchError((_) {
      // sessizce yoksay
    });

    final botStartTime = DateTime.now();

    try {
      await Future.delayed(Duration(milliseconds: 1500 + Random().nextInt(1500)));
      final botResponseText = await _botService.sendMessage(text, scenario: _scenario);
      final botResponseTime = DateTime.now().difference(botStartTime);

      final botMessage = MessageUnit(
        text: botResponseText,
        sender: MessageSender.bot,
        botResponseTime: botResponseTime,
        grammarAnalysis: null, // bot mesajları analiz edilmez
        vocabularyRichness: TextMetrics.vocabularyRichness(botResponseText),
      );

      if (!mounted) return;
      setState(() {
        _messages.add(botMessage);
      });
      // Bot yanıtı eklendi -> kaydet
      final u2 = FirebaseAuth.instance.currentUser;
      if (u2 != null) {
        LocalChatStorage.instance.save(u2.uid, _targetLanguage, _messages);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('There was a problem sending the message.')));
    } finally {
      if (!mounted) return;
      setState(() => _isBotThinking = false);
      // Artık _scrollToBottom() çağrısına gerek yok - reverse: true ile otomatik görünür
    }
  }

  void _updateMessageText(String messageId, String newText) {
    setState(() {
      final messageIndex = _messages.indexWhere((m) => m.id == messageId);
      if (messageIndex != -1) {
        _messages[messageIndex].text = newText;
      }
    });
    // Düzeltme sonrası kaydet
    final u3 = FirebaseAuth.instance.currentUser;
    if (u3 != null) {
      LocalChatStorage.instance.save(u3.uid, _targetLanguage, _messages);
    }
  }

  void _openSettings() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'close',
      barrierColor: Colors.black.withValues(alpha: 0.55), // arka plan hafif görünür
      transitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (context, a1, a2) {
        return _FullScreenSettings(
          supportedLanguages: _supportedLanguages,
          languageFlags: _languageFlags,
          targetLanguage: _targetLanguage,
          buildTile: _buildLanguageTile,
          onClose: () => Navigator.of(context).pop(),
          onChange: (code) {
            _changeTargetLanguage(code);
            Navigator.of(context).pop();
          },
        );
      },
      transitionBuilder: (context, anim, sec, child) {
        final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  // Quiz başlat (composer -> gramer seçimi)
  Future<void> _startGrammarQuiz(Lesson lesson) async {
    if (!_botReady) return;
    try {
      final quiz = await _botService.getGrammarQuiz(
        topicPath: lesson.contentPath,
        topicTitle: lesson.title,
      );
      if (quiz == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Quiz oluşturulamadı.')));
        return;
      }
      final msg = MessageUnit(
        text: quiz.question,
        sender: MessageSender.bot,
        botResponseTime: const Duration(milliseconds: 0),
        grammarAnalysis: null,
        vocabularyRichness: TextMetrics.vocabularyRichness(quiz.question),
        quiz: quiz,
        selectedOptionIndex: null,
      );
      if (!mounted) return;
      setState(() {
        _messages.add(msg);
      });
      final u4 = FirebaseAuth.instance.currentUser;
      if (u4 != null) {
        LocalChatStorage.instance.save(u4.uid, _targetLanguage, _messages);
      }
      // Artık _scrollToBottom() çağrısına gerek yok - reverse: true ile otomatik görünür
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Quiz yüklenirken hata oluştu.')));
    }
  }

  // Quiz şık seçimi işlensin
  void _handleQuizAnswer(MessageUnit message, int index) {
    final idx = _messages.indexWhere((m) => m.id == message.id);
    if (idx == -1) return;
    if (_messages[idx].selectedOptionIndex != null) return; // zaten seçilmiş
    setState(() {
      _messages[idx].selectedOptionIndex = index;
    });
    final u5 = FirebaseAuth.instance.currentUser;
    if (u5 != null) {
      LocalChatStorage.instance.save(u5.uid, _targetLanguage, _messages);
    }
  }

  // Chat exit confirmation dialog
  Future<bool> _confirmExit() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.black.withAlpha(235),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
          title: const Text('Leave chat?', style: TextStyle(color: Colors.white)),
          content: const Text(
            'Are you sure you want to exit this chat screen?',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel', style: TextStyle(color: Colors.cyanAccent)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyanAccent,
                foregroundColor: Colors.black,
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Exit'),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final suggestions = _computeSuggestions();
    return PopScope(
      canPop: _allowPop,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        // Eğer alt composer geri tuşunu emoji/klavye kapatmak için kullandıysa, onay diyaloğunu açmayalım
        final primaryFocus = FocusManager.instance.primaryFocus;
        if (_composerEmojiOpen || (primaryFocus != null && primaryFocus.hasFocus)) {
          return;
        }
        _confirmExit().then((shouldPop) async {
          if (shouldPop && mounted) {
            await _commitAndResetSessionTime();
            setState(() => _allowPop = true);
            Navigator.of(context).pop();
          }
        });
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            CelestialBackground(controller: _backgroundController),
            AnimatedBuilder(
              animation: _entryController,
              builder: (context, child) => BackdropFilter(
                filter: ImageFilter.blur(sigmaX: _blurAnimation.value, sigmaY: _blurAnimation.value),
                child: child,
              ),
              child: Container(color: Colors.black.withAlpha(26)),
            ),
            SafeArea(
              child: Column(
                children: [
                  HolographicHeader(
                    isBotThinking: _isBotThinking,
                    onSettingsTap: _openSettings,
                    selectedLanguage: _targetLanguage,
                    languageFlags: _languageFlags,
                  ),
                  Expanded(
                    child: Stack(
                      children: [
                        ListView.builder(
                          controller: _scrollController,
                          reverse: true, // Her zaman reverse - ChatGPT tarzı
                          padding: const EdgeInsets.symmetric(horizontal: 12.0),
                          itemCount: _messages.length + (_isBotThinking ? 1 : 0),
                          itemBuilder: (context, index) {
                            // Reverse ListView için index hesaplama
                            if (_isBotThinking && index == 0) {
                              return const MessageEntranceAnimator(child: TypingIndicator());
                            }

                            final messageIndex = _isBotThinking ? index - 1 : index;
                            if (messageIndex >= _messages.length) return const SizedBox.shrink();

                            final actualIndex = _messages.length - 1 - messageIndex;
                            if (actualIndex < 0) return const SizedBox.shrink();

                            final message = _messages[actualIndex];
                            return MessageEntranceAnimator(
                              key: ValueKey(message.id),
                              child: MessageBubble(
                                message: message,
                                onCorrect: (newText) => _updateMessageText(message.id, newText),
                                isUserPremium: _isPremium,
                                nativeLanguage: _nativeLanguage,
                                isPremium: _isPremium,
                                onQuizAnswer: (idx) => _handleQuizAnswer(message, idx),
                              ),
                            );
                          },
                        ),
                        // Scroll to bottom button
                        if (_showScrollToBottom)
                          Positioned(
                            bottom: 16,
                            right: 16,
                            child: AnimatedSlide(
                              offset: _showScrollToBottom ? Offset.zero : const Offset(0, 1),
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeInOut,
                              child: AnimatedOpacity(
                                opacity: _showScrollToBottom ? 1.0 : 0.0,
                                duration: const Duration(milliseconds: 200),
                                child: Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.cyanAccent.withAlpha(240),
                                        Colors.cyanAccent.withAlpha(200),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(
                                      color: Colors.cyanAccent.withAlpha(100),
                                      width: 1,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.cyanAccent.withAlpha(80),
                                        blurRadius: 12,
                                        spreadRadius: 0,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(24),
                                      onTap: () {
                                        _scrollController.animateTo(
                                          0,
                                          duration: const Duration(milliseconds: 400),
                                          curve: Curves.easeInOut,
                                        );
                                      },
                                      child: const Icon(
                                        Icons.keyboard_arrow_down_rounded,
                                        color: Colors.black,
                                        size: 26,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (suggestions.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.only(left: 12, right: 12, bottom: 6),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: suggestions
                              .take(6)
                              .map((s) => Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: ActionChip(
                                      label: Text(s, style: const TextStyle(color: Colors.white, fontSize: 12)),
                                      onPressed: _isBotThinking ? null : () => _sendMessage(s),
                                      backgroundColor: Colors.black.withAlpha(64),
                                      side: BorderSide(color: Colors.cyanAccent.withAlpha(100)),
                                    ),
                                  ))
                              .toList(),
                        ),
                      ),
                    ),
                  Theme(
                    data: ThemeData.dark().copyWith(
                      colorScheme: ThemeData.dark().colorScheme.copyWith(
                        primary: Colors.cyanAccent,
                        surface: const Color(0xFF121212),
                        onSurface: Colors.white,
                      ),
                      iconTheme: const IconThemeData(color: Colors.white),
                      hintColor: Colors.white70,
                      dividerColor: Colors.white24,
                      cardColor: const Color(0xFF1E1E1E),
                    ),
                    child: MessageComposer(
                      onSend: _sendMessage,
                      nativeLanguage: _nativeLanguage,
                      enableTranslation: _nativeLanguage != _targetLanguage, // anadil ile hedef dil farklı ise göster
                      enableSpeech: true,
                      enableEmojis: true,
                      hintText: _botReady ? 'Message' : 'Loading...',
                      characterLimit: 1000,
                      enabled: _botReady,
                      onEmojiVisibilityChanged: (open) => setState(() => _composerEmojiOpen = open),
                      isPremium: _isPremium,
                      useAiTranslation: true,
                      aiTargetLanguage: _targetLanguage,
                      // Senaryo
                      selectedScenario: _scenario,
                      onScenarioChanged: (s) => setState(() => _scenario = s),
                      // Gramer
                      onGrammarPractice: (lesson) => _startGrammarQuiz(lesson),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FullScreenSettings extends StatefulWidget {
  final Map<String,String> supportedLanguages;
  final Map<String,String> languageFlags; // gelecekte gerekirse
  final String targetLanguage;
  final Widget Function(String) buildTile;
  final VoidCallback onClose;
  final void Function(String) onChange;
  const _FullScreenSettings({
    required this.supportedLanguages,
    required this.languageFlags,
    required this.targetLanguage,
    required this.buildTile,
    required this.onClose,
    required this.onChange,
  });
  @override
  State<_FullScreenSettings> createState() => _FullScreenSettingsState();
}

class _FullScreenSettingsState extends State<_FullScreenSettings> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';
  bool _popularOnly = false; // sadece popüler dilleri gösterme modu

  // Uygulamada en çok öğrenilmesi muhtemel diller listesi (isteğe göre güncellenebilir)
  static const Set<String> _popularLanguages = {
    'en','es','fr','de','tr','it','pt','ru','ar','ja','ko','zh','nl','sv'
  };

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<MapEntry<String,String>> _filtered() {
    // Tüm dilleri al
    Iterable<MapEntry<String,String>> entries = widget.supportedLanguages.entries;
    // Popüler filtre açıksa önce kısıtla
    if (_popularOnly) {
      entries = entries.where((e) => _popularLanguages.contains(e.key));
    }
    // Arama uygula
    final qRaw = _query.trim();
    if (qRaw.isNotEmpty) {
      final q = qRaw.toLowerCase();
      entries = entries.where((e) => e.key.toLowerCase().contains(q) || e.value.toLowerCase().contains(q));
    }
    return entries.toList();
  }

  @override
  Widget build(BuildContext context) {
    final entries = _filtered();
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.cyanAccent.withValues(alpha: 0.30),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.cyanAccent.withValues(alpha: 1.00), width: 1),
                    ),
                    child: const Icon(Icons.settings_outlined, color: Colors.cyanAccent, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Text('Settings', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w600, letterSpacing: 0.4)),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: widget.onClose,
                    icon: const Icon(Icons.close, color: Colors.white70),
                  )
                ],
              ),
              const SizedBox(height: 20),
              // Arama Kutusu
              TextField(
                controller: _searchCtrl,
                style: const TextStyle(color: Colors.white),
                cursorColor: Colors.cyanAccent,
                decoration: InputDecoration(
                  hintText: 'Search language',
                  hintStyle: TextStyle(color: Colors.white54, fontSize: 13),
                  prefixIcon: const Icon(Icons.search, color: Colors.cyanAccent, size: 20),
                  suffixIcon: _query.isEmpty ? null : IconButton(
                    icon: const Icon(Icons.clear, color: Colors.white54, size: 18),
                    onPressed: () {
                      _searchCtrl.clear();
                      setState(() => _query = '');
                    },
                  ),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.18),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.cyanAccent.withValues(alpha: 0.60), width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Colors.cyanAccent, width: 1.3),
                  ),
                ),
                onChanged: (v) => setState(()=> _query = v),
              ),
              const SizedBox(height: 18),
              // Modern filtre toggle
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.60), width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _FilterToggle(
                      label: 'All Languages',
                      icon: Icons.public,
                      isSelected: !_popularOnly,
                      onTap: () => setState(() => _popularOnly = false),
                      count: widget.supportedLanguages.length,
                    ),
                    _FilterToggle(
                      label: 'Popular',
                      icon: Icons.star_rounded,
                      isSelected: _popularOnly,
                      onTap: () => setState(() => _popularOnly = true),
                      count: _popularLanguages.length,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.12),
                        Colors.white.withValues(alpha: 0.06),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.40), width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.translate_outlined, color: Colors.cyanAccent, size: 20),
                          const SizedBox(width: 8),
                          Text('Learning Language (${entries.length})', style: TextStyle(color: Colors.cyanAccent.withAlpha(230), fontSize: 16, fontWeight: FontWeight.w600)),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final bool narrow = constraints.maxWidth < 300;
                            final int columns = narrow ? 2 : 3;
                            if (entries.isEmpty) {
                              return Center(
                                child: Text('Sonuç yok', style: TextStyle(color: Colors.white60, fontSize: 13)),
                              );
                            }
                            return RawScrollbar(
                              thumbVisibility: true,
                              trackVisibility: false,
                              thickness: 4,
                              radius: const Radius.circular(8),
                              thumbColor: Colors.cyanAccent,
                              child: GridView.builder(
                                physics: const BouncingScrollPhysics(),
                                padding: const EdgeInsets.only(right: 4, bottom: 8),
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: columns,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 14,
                                  childAspectRatio: 1.3,
                                ),
                                itemCount: entries.length,
                                itemBuilder: (ctx, i) {
                                  final code = entries[i].key;
                                  return widget.buildTile(code);
                                },
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.orange.withValues(alpha: 0.90), width: 1),
                        ),
                        child: const Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(Icons.info_outline, color: Colors.orangeAccent, size: 16),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Last messages stored on your device.',
                                style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500, height: 1.2),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
    ),
      );
  }
}

class _FilterToggle extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final int count;

  const _FilterToggle({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          margin: const EdgeInsets.only(right: 2),
          decoration: BoxDecoration(
            color: isSelected ? Colors.cyanAccent : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: isSelected ? Colors.black : Colors.cyanAccent, size: 16),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? Colors.black : Colors.white70,
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
