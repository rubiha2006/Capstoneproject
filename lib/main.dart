import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker_web/image_picker_web.dart';
import 'package:translator/translator.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';

void main() {
  setUrlStrategy(PathUrlStrategy());
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AgriSense AI',
      theme: ThemeData(
        colorSchemeSeed: Colors.green,
        useMaterial3: true,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const PlantDiseaseScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class PlantDiseaseScreen extends StatefulWidget {
  const PlantDiseaseScreen({super.key});
  @override
  State<PlantDiseaseScreen> createState() => _PlantDiseaseScreenState();
}

class _PlantDiseaseScreenState extends State<PlantDiseaseScreen> {
  Uint8List? _imageBytes;
  bool _isLoading = false;
  Map<String, dynamic>? _diagnosisResult;
  String? _error;
  final List<Map<String, dynamic>> _history = [];
  String _selectedLanguage = 'en';
  final translator = GoogleTranslator();

  final Map<String, String> _languageNames = const {
    'en': 'English',
    'es': 'Español',
    'fr': 'Français',
    'de': 'Deutsch',
    'hi': 'हिन्दी',
    'ta': 'தமிழ்',
    'te': 'తెలుగు',
    'kn': 'ಕನ್ನಡ',
    'ml': 'മലയാളം',
    'bn': 'বাংলা',
    'ar': 'العربية',
    'zh': '中文',
    'ja': '日本語',
    'ru': 'Русский',
    'pt': 'Português',
    'it': 'Italiano',
    'ko': '한국어',
  };

  final Map<String, Map<String, String>> _appTranslations = {
    'en': {
      'title': 'AgriSense AI',
      'selectImage': 'Select Plant Image',
      'captureImage': 'Capture Image',
      'analyzing': 'Analyzing...',
      'analyze': 'Analyze Plant',
      'diagnosis': 'Diagnosis Result',
      'disease': 'Disease',
      'description': 'Description',
      'recommendations': 'Recommendations',
      'sources': 'Sources',
      'history': 'History',
      'offlineMode': 'Offline Mode',
      'shareResult': 'Share Result',
      'error': 'Error',
      'noImage': 'No image selected',
      'tryAgain': 'Try Again',
      'viewDetails': 'View Details',
      'save': 'Save to History',
      'confidence': 'Confidence',
      'treatment': 'Treatment',
      'prevention': 'Prevention',
      'lastAnalysis': 'Last Analysis',
      'clearHistory': 'Clear History',
      'settings': 'Settings',
      'language': 'Language',
    },
    'es': {
      'title': 'AgriSense AI',
      'selectImage': 'Seleccionar imagen de planta',
      'captureImage': 'Capturar imagen',
      'analyzing': 'Analizando...',
      'analyze': 'Analizar planta',
      'diagnosis': 'Resultado del diagnóstico',
      'disease': 'Enfermedad',
      'description': 'Descripción',
      'recommendations': 'Recomendaciones',
      'sources': 'Fuentes',
      'history': 'Historial',
      'offlineMode': 'Modo sin conexión',
      'shareResult': 'Compartir resultado',
      'error': 'Error',
      'noImage': 'No se seleccionó ninguna imagen',
      'tryAgain': 'Intentar de nuevo',
      'viewDetails': 'Ver detalles',
      'save': 'Guardar en el historial',
      'confidence': 'Confianza',
      'treatment': 'Tratamiento',
      'prevention': 'Prevención',
      'lastAnalysis': 'Último análisis',
      'clearHistory': 'Limpiar historial',
      'settings': 'Configuración',
      'language': 'Idioma',
    },
    'fr': {
      'title': 'AgriSense AI',
      'selectImage': 'Sélectionner une image de plante',
      'captureImage': 'Capturer une image',
      'analyzing': 'Analyse en cours...',
      'analyze': 'Analyser la plante',
      'diagnosis': 'Résultat du diagnostic',
      'disease': 'Maladie',
      'description': 'Description',
      'recommendations': 'Recommandations',
      'sources': 'Sources',
      'history': 'Historique',
      'offlineMode': 'Mode hors ligne',
      'shareResult': 'Partager le résultat',
      'error': 'Erreur',
      'noImage': 'Aucune image sélectionnée',
      'tryAgain': 'Réessayer',
      'viewDetails': 'Voir les détails',
      'save': 'Enregistrer dans l\'historique',
      'confidence': 'Confiance',
      'treatment': 'Traitement',
      'prevention': 'Prévention',
      'lastAnalysis': 'Dernière analyse',
      'clearHistory': 'Effacer l\'historique',
      'settings': 'Paramètres',
      'language': 'Langue',
    },
    'de': {
      'title': 'AgriSense AI',
      'selectImage': 'Pflanzenbild auswählen',
      'captureImage': 'Bild aufnehmen',
      'analyzing': 'Analysiere...',
      'analyze': 'Pflanze analysieren',
      'diagnosis': 'Diagnoseergebnis',
      'disease': 'Krankheit',
      'description': 'Beschreibung',
      'recommendations': 'Empfehlungen',
      'sources': 'Quellen',
      'history': 'Verlauf',
      'offlineMode': 'Offline-Modus',
      'shareResult': 'Ergebnis teilen',
      'error': 'Fehler',
      'noImage': 'Kein Bild ausgewählt',
      'tryAgain': 'Erneut versuchen',
      'viewDetails': 'Details anzeigen',
      'save': 'Im Verlauf speichern',
      'confidence': 'Konfidenz',
      'treatment': 'Behandlung',
      'prevention': 'Prävention',
      'lastAnalysis': 'Letzte Analyse',
      'clearHistory': 'Verlauf löschen',
      'settings': 'Einstellungen',
      'language': 'Sprache',
    },
    'hi': {
      'title': 'एग्रीसेंस एआई',
      'selectImage': 'पौधे की छवि चुनें',
      'captureImage': 'छवि लें',
      'analyzing': 'विश्लेषण कर रहे हैं...',
      'analyze': 'पौधे का विश्लेषण करें',
      'diagnosis': 'निदान परिणाम',
      'disease': 'रोग',
      'description': 'विवरण',
      'recommendations': 'सिफारिशें',
      'sources': 'स्रोत',
      'history': 'इतिहास',
      'offlineMode': 'ऑफलाइन मोड',
      'shareResult': 'परिणाम साझा करें',
      'error': 'त्रुटि',
      'noImage': 'कोई छवि चयनित नहीं',
      'tryAgain': 'पुनः प्रयास करें',
      'viewDetails': 'विवरण देखें',
      'save': 'इतिहास में सहेजें',
      'confidence': 'विश्वसनीयता',
      'treatment': 'उपचार',
      'prevention': 'रोकथाम',
      'lastAnalysis': 'अंतिम विश्लेषण',
      'clearHistory': 'इतिहास साफ करें',
      'settings': 'सेटिंग्स',
      'language': 'भाषा',
    },
    'ta': {
      'title': 'அக்ரிசென்ஸ் AI',
      'selectImage': 'தாவர படத்தைத் தேர்ந்தெடுக்கவும்',
      'captureImage': 'படத்தை எடுக்கவும்',
      'analyzing': 'பகுப்பாய்வு செய்கிறது...',
      'analyze': 'தாவரத்தை பகுப்பாய்வு செய்க',
      'diagnosis': 'நோய் கண்டறிதல் முடிவு',
      'disease': 'நோய்',
      'description': 'விளக்கம்',
      'recommendations': 'பரிந்துரைகள்',
      'sources': 'மூலங்கள்',
      'history': 'வரலாறு',
      'offlineMode': 'ஆஃப்லைன் முறை',
      'shareResult': 'முடிவைப் பகிரவும்',
      'error': 'பிழை',
      'noImage': 'படம் தேர்ந்தெடுக்கப்படவில்லை',
      'tryAgain': 'மீண்டும் முயல்க',
      'viewDetails': 'விவரங்களைக் காண்க',
      'save': 'வரலாற்றில் சேமிக்கவும்',
      'confidence': 'நம்பகத்தன்மை',
      'treatment': 'சிகிச்சை',
      'prevention': 'தடுப்பு',
      'lastAnalysis': 'கடைசி பகுப்பாய்வு',
      'clearHistory': 'வரலாற்றை அழி',
      'settings': 'அமைப்புகள்',
      'language': 'மொழி',
    },
    'te': {
      'title': 'అగ్రీసెన్స్ AI',
      'selectImage': 'ప్లాంట్ ఇమేజ్ ఎంచుకోండి',
      'captureImage': 'ఇమేజ్ ని క్యాప్చర్ చేయండి',
      'analyzing': 'విశ్లేషిస్తోంది...',
      'analyze': 'ప్లాంట్ ను విశ్లేషించండి',
      'diagnosis': 'డయాగ్నోసిస్ రిజల్ట్',
      'disease': 'వ్యాధి',
      'description': 'వివరణ',
      'recommendations': 'సిఫార్సులు',
      'sources': 'మూలాలు',
      'history': 'చరిత్ర',
      'offlineMode': 'ఆఫ్లైన్ మోడ్',
      'shareResult': 'రిజల్ట్ షేర్ చేయండి',
      'error': 'లోపం',
      'noImage': 'ఇమేజ్ ఎంచుకోలేదు',
      'tryAgain': 'మళ్లీ ప్రయత్నించండి',
      'viewDetails': 'వివరాలు చూడండి',
      'save': 'హిస్టరీలో సేవ్ చేయండి',
      'confidence': 'నమ్మకం',
      'treatment': 'చికిత్స',
      'prevention': 'నివారణ',
      'lastAnalysis': 'చివరి విశ్లేషణ',
      'clearHistory': 'చరిత్ర తొలగించు',
      'settings': 'సెట్టింగ్స్',
      'language': 'భాష',
    },
    'kn': {
      'title': 'ಆಗ್ರಿಸೆನ್ಸ್ AI',
      'selectImage': 'ಸಸ್ಯದ ಚಿತ್ರವನ್ನು ಆಯ್ಕೆಮಾಡಿ',
      'captureImage': 'ಚಿತ್ರವನ್ನು ತೆಗೆದುಕೊಳ್ಳಿ',
      'analyzing': 'ವಿಶ್ಲೇಷಿಸುತ್ತಿದೆ...',
      'analyze': 'ಸಸ್ಯವನ್ನು ವಿಶ್ಲೇಷಿಸಿ',
      'diagnosis': 'ರೋಗನಿರ್ಣಯ ಫಲಿತಾಂಶ',
      'disease': 'ರೋಗ',
      'description': 'ವಿವರಣೆ',
      'recommendations': 'ಶಿಫಾರಸುಗಳು',
      'sources': 'ಮೂಲಗಳು',
      'history': 'ಇತಿಹಾಸ',
      'offlineMode': 'ಆಫ್ಲೈನ್ ಮೋಡ್',
      'shareResult': 'ಫಲಿತಾಂಶವನ್ನು ಹಂಚಿಕೊಳ್ಳಿ',
      'error': 'ದೋಷ',
      'noImage': 'ಯಾವುದೇ ಚಿತ್ರ ಆಯ್ಕೆ ಮಾಡಲಾಗಿಲ್ಲ',
      'tryAgain': 'ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ',
      'viewDetails': 'ವಿವರಗಳನ್ನು ವೀಕ್ಷಿಸಿ',
      'save': 'ಇತಿಹಾಸದಲ್ಲಿ ಸಂರಕ್ಷಿಸಿ',
      'confidence': 'ನಂಬಿಕೆ',
      'treatment': 'ಚಿಕಿತ್ಸೆ',
      'prevention': 'ತಡೆಗಟ್ಟುವಿಕೆ',
      'lastAnalysis': 'ಕೊನೆಯ ವಿಶ್ಲೇಷಣೆ',
      'clearHistory': 'ಇತಿಹಾಸವನ್ನು ಅಳಿಸಿ',
      'settings': 'ಸettingsಟಿಂಗ್ಸ್',
      'language': 'ಭಾಷೆ',
    },
    'ml': {
      'title': 'അഗ്രിസെൻസ് AI',
      'selectImage': 'ചെടിയുടെ ഇമേജ് തിരഞ്ഞെടുക്കുക',
      'captureImage': 'ഇമേജ് കാപ്ചർ ചെയ്യുക',
      'analyzing': 'വിശകലനം ചെയ്യുന്നു...',
      'analyze': 'ചെടി വിശകലനം ചെയ്യുക',
      'diagnosis': 'രോഗനിർണയ ഫലം',
      'disease': 'രോഗം',
      'description': 'വിവരണം',
      'recommendations': 'ശുപാർശകൾ',
      'sources': 'ഉറവിടങ്ങൾ',
      'history': 'ചരിത്രം',
      'offlineMode': 'ഓഫ്ലൈൻ മോഡ്',
      'shareResult': 'ഫലം പങ്കിടുക',
      'error': 'പിശക്',
      'noImage': 'ഇമേജ് തിരഞ്ഞെടുത്തിട്ടില്ല',
      'tryAgain': 'വീണ്ടും ശ്രമിക്കുക',
      'viewDetails': 'വിശദാംശങ്ങൾ കാണുക',
      'save': 'ചരിത്രത്തിൽ സംരക്ഷിക്കുക',
      'confidence': 'ആത്മവിശ്വാസം',
      'treatment': 'ചികിത്സ',
      'prevention': 'തടയൽ',
      'lastAnalysis': 'അവസാന വിശകലനം',
      'clearHistory': 'ചരിത്രം മായ്‌ക്കുക',
      'settings': 'സെറ്റിംഗുകൾ',
      'language': 'ഭാഷ',
    },
    'bn': {
      'title': 'এগ্রিসেন্স AI',
      'selectImage': 'গাছের ছবি নির্বাচন করুন',
      'captureImage': 'ছবি তুলুন',
      'analyzing': 'বিশ্লেষণ করা হচ্ছে...',
      'analyze': 'গাছ বিশ্লেষণ করুন',
      'diagnosis': 'রোগ নির্ণয়ের ফলাফল',
      'disease': 'রোগ',
      'description': 'বর্ণনা',
      'recommendations': 'সুপারিশ',
      'sources': 'উত্স',
      'history': 'ইতিহাস',
      'offlineMode': 'অফলাইন মোড',
      'shareResult': 'ফলাফল শেয়ার করুন',
      'error': 'ত্রুটি',
      'noImage': 'কোন ছবি নির্বাচন করা হয়নি',
      'tryAgain': 'আবার চেষ্টা করুন',
      'viewDetails': 'বিস্তারিত দেখুন',
      'save': 'ইতিহাসে সংরক্ষণ করুন',
      'confidence': 'আত্মবিশ্বাস',
      'treatment': 'চিকিত্সা',
      'prevention': 'প্রতিরোধ',
      'lastAnalysis': 'শেষ বিশ্লেষণ',
      'clearHistory': 'ইতিহাস সাফ করুন',
      'settings': 'সেটিংস',
      'language': 'ভাষা',
    },
    'ar': {
      'title': 'أجريسينس الذكاء الاصطناعي',
      'selectImage': 'اختر صورة النبات',
      'captureImage': 'التقاط صورة',
      'analyzing': 'جاري التحليل...',
      'analyze': 'تحليل النبات',
      'diagnosis': 'نتيجة التشخيص',
      'disease': 'المرض',
      'description': 'الوصف',
      'recommendations': 'التوصيات',
      'sources': 'المصادر',
      'history': 'السجل',
      'offlineMode': 'وضع عدم الاتصال',
      'shareResult': 'مشاركة النتيجة',
      'error': 'خطأ',
      'noImage': 'لم يتم اختيار صورة',
      'tryAgain': 'حاول مرة أخرى',
      'viewDetails': 'عرض التفاصيل',
      'save': 'حفظ في السجل',
      'confidence': 'الثقة',
      'treatment': 'العلاج',
      'prevention': 'الوقاية',
      'lastAnalysis': 'آخر تحليل',
      'clearHistory': 'مسح السجل',
      'settings': 'الإعدادات',
      'language': 'اللغة',
    },
    'zh': {
      'title': 'AgriSense AI',
      'selectImage': '选择植物图像',
      'captureImage': '捕获图像',
      'analyzing': '分析中...',
      'analyze': '分析植物',
      'diagnosis': '诊断结果',
      'disease': '疾病',
      'description': '描述',
      'recommendations': '建议',
      'sources': '来源',
      'history': '历史',
      'offlineMode': '离线模式',
      'shareResult': '分享结果',
      'error': '错误',
      'noImage': '未选择图像',
      'tryAgain': '再试一次',
      'viewDetails': '查看详情',
      'save': '保存到历史',
      'confidence': '置信度',
      'treatment': '治疗',
      'prevention': '预防',
      'lastAnalysis': '最后分析',
      'clearHistory': '清除历史',
      'settings': '设置',
      'language': '语言',
    },
    'ja': {
      'title': 'AgriSense AI',
      'selectImage': '植物画像を選択',
      'captureImage': '画像をキャプチャ',
      'analyzing': '分析中...',
      'analyze': '植物を分析',
      'diagnosis': '診断結果',
      'disease': '病気',
      'description': '説明',
      'recommendations': '推奨事項',
      'sources': '情報源',
      'history': '履歴',
      'offlineMode': 'オフラインモード',
      'shareResult': '結果を共有',
      'error': 'エラー',
      'noImage': '画像が選択されていません',
      'tryAgain': '再試行',
      'viewDetails': '詳細を表示',
      'save': '履歴に保存',
      'confidence': '信頼度',
      'treatment': '治療',
      'prevention': '予防',
      'lastAnalysis': '最終分析',
      'clearHistory': '履歴をクリア',
      'settings': '設定',
      'language': '言語',
    },
    'ru': {
      'title': 'AgriSense AI',
      'selectImage': 'Выбрать изображение растения',
      'captureImage': 'Сделать снимок',
      'analyzing': 'Анализ...',
      'analyze': 'Анализировать растение',
      'diagnosis': 'Результат диагностики',
      'disease': 'Заболевание',
      'description': 'Описание',
      'recommendations': 'Рекомендации',
      'sources': 'Источники',
      'history': 'История',
      'offlineMode': 'Автономный режим',
      'shareResult': 'Поделиться результатом',
      'error': 'Ошибка',
      'noImage': 'Изображение не выбрано',
      'tryAgain': 'Попробовать снова',
      'viewDetails': 'Просмотреть детали',
      'save': 'Сохранить в историю',
      'confidence': 'Доверие',
      'treatment': 'Лечение',
      'prevention': 'Профилактика',
      'lastAnalysis': 'Последний анализ',
      'clearHistory': 'Очистить историю',
      'settings': 'Настройки',
      'language': 'Язык',
    },
    'pt': {
      'title': 'AgriSense AI',
      'selectImage': 'Selecionar imagem da planta',
      'captureImage': 'Capturar imagem',
      'analyzing': 'Analisando...',
      'analyze': 'Analisar planta',
      'diagnosis': 'Resultado do diagnóstico',
      'disease': 'Doença',
      'description': 'Descrição',
      'recommendations': 'Recomendações',
      'sources': 'Fontes',
      'history': 'Histórico',
      'offlineMode': 'Modo offline',
      'shareResult': 'Compartilhar resultado',
      'error': 'Erro',
      'noImage': 'Nenhuma imagem selecionada',
      'tryAgain': 'Tentar novamente',
      'viewDetails': 'Ver detalhes',
      'save': 'Salvar no histórico',
      'confidence': 'Confiança',
      'treatment': 'Tratamento',
      'prevention': 'Prevenção',
      'lastAnalysis': 'Última análise',
      'clearHistory': 'Limpar histórico',
      'settings': 'Configurações',
      'language': 'Idioma',
    },
    'it': {
      'title': 'AgriSense AI',
      'selectImage': 'Seleziona immagine pianta',
      'captureImage': 'Cattura immagine',
      'analyzing': 'Analizzando...',
      'analyze': 'Analizza pianta',
      'diagnosis': 'Risultato diagnosi',
      'disease': 'Malattia',
      'description': 'Descrizione',
      'recommendations': 'Raccomandazioni',
      'sources': 'Fonti',
      'history': 'Cronologia',
      'offlineMode': 'Modalità offline',
      'shareResult': 'Condividi risultato',
      'error': 'Errore',
      'noImage': 'Nessuna immagine selezionata',
      'tryAgain': 'Riprova',
      'viewDetails': 'Visualizza dettagli',
      'save': 'Salva nella cronologia',
      'confidence': 'Affidabilità',
      'treatment': 'Trattamento',
      'prevention': 'Prevenzione',
      'lastAnalysis': 'Ultima analisi',
      'clearHistory': 'Cancella cronologia',
      'settings': 'Impostazioni',
      'language': 'Lingua',
    },
    'ko': {
      'title': 'AgriSense AI',
      'selectImage': '식물 이미지 선택',
      'captureImage': '이미지 캡처',
      'analyzing': '분석 중...',
      'analyze': '식물 분석',
      'diagnosis': '진단 결과',
      'disease': '질병',
      'description': '설명',
      'recommendations': '권장 사항',
      'sources': '출처',
      'history': '기록',
      'offlineMode': '오프라인 모드',
      'shareResult': '결과 공유',
      'error': '오류',
      'noImage': '이미지가 선택되지 않았습니다',
      'tryAgain': '다시 시도',
      'viewDetails': '세부 정보 보기',
      'save': '기록에 저장',
      'confidence': '신뢰도',
      'treatment': '치료',
      'prevention': '예방',
      'lastAnalysis': '마지막 분석',
      'clearHistory': '기록 지우기',
      'settings': '설정',
      'language': '언어',
    },
  };

  String _t(String key) {
    return _appTranslations[_selectedLanguage]?[key] ??
        _appTranslations['en']?[key] ??
        key;
  }

  Future<String> _translateText(String text, {String? to}) async {
    if (_selectedLanguage == 'en') return text;
    try {
      final translation = await translator.translate(
        text,
        to: to ?? _selectedLanguage,
      );
      return translation.text;
    } catch (e) {
      print('Translation error: $e');
      return text;
    }
  }

  Future<Map<String, dynamic>> _translateDiagnosis(
    Map<String, dynamic> result,
  ) async {
    if (_selectedLanguage == 'en') return result;

    final translated = Map<String, dynamic>.from(result);

    try {
      translated['disease'] = await _translateText(
        result['disease'] ?? 'Unknown Disease',
      );
      translated['description'] = await _translateText(
        result['description'] ?? '',
      );
      translated['summary'] = await _translateText(result['summary'] ?? '');

      if (result['recommendations'] != null) {
        final recs = <String>[];
        for (final r in (result['recommendations'] as List)) {
          recs.add(await _translateText(r.toString()));
        }
        translated['recommendations'] = recs;
      }
    } catch (e) {
      print('Diagnosis translation error: $e');
    }

    return translated;
  }

  Future<void> _pickImage() async {
    try {
      final Uint8List? imageBytes = await ImagePickerWeb.getImageAsBytes();
      setState(() {
        _imageBytes = imageBytes;
        _diagnosisResult = null;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to pick image: $e';
      });
    }
  }

  Future<void> _analyzeImage() async {
    if (_imageBytes == null) {
      setState(() {
        _error = _t('noImage');
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _diagnosisResult = null;
    });

    try {
      await Future.delayed(const Duration(seconds: 2));

      final mockResponse = {
        'disease': 'Tomato Early Blight',
        'confidence': 0.92,
        'description':
            'A common fungal disease affecting tomato plants, characterized by concentric rings on leaves.',
        'summary':
            'Early blight is caused by the fungus Alternaria solani and can significantly reduce yield.',
        'recommendations': [
          'Remove infected leaves immediately',
          'Apply copper-based fungicides',
          'Ensure proper plant spacing for air circulation',
          'Water at the base to avoid wetting leaves',
        ],
      };

      final translatedResult = await _translateDiagnosis(mockResponse);

      setState(() {
        _diagnosisResult = translatedResult;
        _history.insert(0, {
          ...translatedResult,
          'timestamp': DateTime.now(),
          'imageBytes': _imageBytes,
        });
      });
    } catch (e) {
      setState(() {
        _error = 'Analysis failed: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _changeLanguage(String? newLanguage) {
    if (newLanguage != null) {
      setState(() {
        _selectedLanguage = newLanguage;
      });
      if (_diagnosisResult != null) {
        _translateDiagnosis(_diagnosisResult!).then((translated) {
          setState(() {
            _diagnosisResult = translated;
          });
        });
      }
    }
  }

  Widget _buildLanguageSelector() {
    return DropdownButton<String>(
      value: _selectedLanguage,
      icon: const Icon(Icons.language),
      onChanged: _changeLanguage,
      items: _languageNames.entries.map((entry) {
        return DropdownMenuItem(value: entry.key, child: Text(entry.value));
      }).toList(),
    );
  }

  void _clearHistory() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_t('clearHistory')),
        content: const Text('Are you sure you want to clear all history?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _history.clear();
              });
              Navigator.pop(context);
            },
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_t('title')),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          _buildLanguageSelector(),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: _showHistoryDialog,
            tooltip: _t('history'),
          ),
          if (_history.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear_all),
              onPressed: _clearHistory,
              tooltip: _t('clearHistory'),
            ),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE8F5E8), Color(0xFFF1F8E9)],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Header Section
              Container(
                margin: const EdgeInsets.only(bottom: 30),
                child: Column(
                  children: [
                    Icon(Icons.eco, size: 60, color: Colors.green[700]),
                    const SizedBox(height: 10),
                    Text(
                      _t('title'),
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[800],
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'AI-Powered Plant Disease Detection',
                      style: TextStyle(fontSize: 16, color: Colors.green[600]),
                    ),
                  ],
                ),
              ),

              // Image Upload Section
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Text(
                        'Upload Plant Image',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[800],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Image Display
                      Container(
                        width: 300,
                        height: 250,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.green[300]!,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.grey[50],
                        ),
                        child: _imageBytes != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.memory(
                                  _imageBytes!,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                ),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.photo_camera,
                                    size: 60,
                                    color: Colors.green[300],
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    _t('noImage'),
                                    style: TextStyle(
                                      color: Colors.green[600],
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                      ),

                      const SizedBox(height: 20),

                      // Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _pickImage,
                            icon: const Icon(Icons.photo_library),
                            label: Text(_t('selectImage')),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Analyze Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _analyzeImage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 2,
                  ),
                  child: _isLoading
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const CircularProgressIndicator(
                              color: Colors.white,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              _t('analyzing'),
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        )
                      : Text(
                          _t('analyze'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 20),

              // Error Display
              if (_error != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red[100]!),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _error!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () => setState(() => _error = null),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 20),

              // Results Display
              if (_diagnosisResult != null) _buildDiagnosisResult(),

              // History Preview
              if (_history.isNotEmpty) _buildHistoryPreview(),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDiagnosisResult() {
    final result = _diagnosisResult!;
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _t('diagnosis'),
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[800],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.share),
                  onPressed: () => _shareResult(result),
                  tooltip: _t('shareResult'),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Disease and Confidence
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_t('disease')}:',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          result['disease'],
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (result['confidence'] != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${(result['confidence'] * 100).toStringAsFixed(1)}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Description
            if (result['description'] != null) ...[
              Text(
                '${_t('description')}:',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(result['description']),
              ),
              const SizedBox(height: 16),
            ],

            // Recommendations
            if (result['recommendations'] != null) ...[
              Text(
                _t('recommendations'),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),
              ...(result['recommendations'] as List)
                  .map(
                    (rec) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.arrow_right,
                            color: Colors.green[700],
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              rec,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryPreview() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _t('history'),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[800],
                  ),
                ),
                TextButton(
                  onPressed: _showHistoryDialog,
                  child: Text(_t('viewDetails')),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ..._history
                .take(2)
                .map(
                  (entry) => Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.green[100]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            image: DecorationImage(
                              image: MemoryImage(entry['imageBytes']),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                entry['disease'] ?? 'Unknown',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${entry['timestamp'].toString().substring(0, 16)}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.visibility,
                            color: Colors.green[700],
                          ),
                          onPressed: () {
                            setState(() {
                              _diagnosisResult = entry;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ],
        ),
      ),
    );
  }

  void _showHistoryDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: 500,
          height: 600,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _t('history'),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _history.isEmpty
                    ? Center(
                        child: Text(
                          'No analysis history',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _history.length,
                        itemBuilder: (context, index) {
                          final entry = _history[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.green[100]!),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(6),
                                    image: DecorationImage(
                                      image: MemoryImage(entry['imageBytes']),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        entry['disease'] ?? 'Unknown',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        '${entry['timestamp'].toString().substring(0, 16)}',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.visibility,
                                    color: Colors.green[700],
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _diagnosisResult = entry;
                                    });
                                    Navigator.pop(context);
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _shareResult(Map<String, dynamic> result) {
    final shareText =
        '''
🌱 Plant Disease Diagnosis

Disease: ${result['disease']}
Description: ${result['description']}

Recommendations:
${(result['recommendations'] as List).map((r) => '• $r').join('\n')}

Diagnosed by AgriSense AI
''';

    Share.share(shareText, subject: 'Plant Disease Diagnosis');
  }
}
