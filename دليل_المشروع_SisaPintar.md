# دليل المشروع التقييمي - تطبيق SisaPintar
## دليل شامل للّقاء التقييمي (Responsi)

**اسم التطبيق:** SisaPintar (سيسا-بينتار = "السابقون الأذكياء" / بالإندونيسية: الذكاء من البقايا)  
**أعضاء الفريق:** Mohammed Rashed (2406016105) · Dania Elsadig (2406016106) · Moh Dzikry Pradana (2300016137)  
**المادة:** Proyek Teknologi Mobile SDGs  
**الفصل:** A

---

## 1. فكرة التطبيق الأساسية (Ide Utama)

### ما هي المشكلة التي يحلّها؟
كثير من الطلاب المقيمين في السكن الجامعي (mahasiswa kos) والأسر يرمون بقايا طعام في القمامة لأنهم لا يعرفون كيف يطبخونها. هذا يُشكّل ظاهرة تُسمى **food waste (هدر الطعام)**.

### الحل:
تطبيق موبايل ذكي يُساعد المستخدم على:
1. **تتبع صلاحية البقايا** الموجودة في الثلاجة (Tracker)
2. **توليد وصفات طعام** مخصصة بالذكاء الاصطناعي بناءً على ما لديه
3. **قياس الأثر البيئي والاقتصادي** لمساعيه في تقليل الهدر

### ربط بأهداف التنمية المستدامة (SDGs):
| الهدف | التفسير |
|-------|---------|
| **Goal 2 – Zero Hunger** (لا للجوع) | تحويل البقايا إلى وجبات مفيدة بدل رميها |
| **Goal 12 – Responsible Consumption** (استهلاك مسؤول) | تشجيع الاستخدام الكامل للموارد الغذائية |

---

## 2. هيكل الملفات (Struktur File Proyek)

```
Moahmmed_Dania_ProyekTeknologi-Mobile-2026/
│
├── sisa_pintar_flutter/          ← كود Flutter الرئيسي
│   ├── assets/
│   │   └── icon.png              ← أيقونة التطبيق المخصصة
│   ├── lib/
│   │   ├── main.dart             ← نقطة انطلاق التطبيق + AppSettingsProvider
│   │   ├── models/               ← تعريفات البيانات (Data Models)
│   │   │   ├── food_item.dart    ← نموذج بيانات المادة الغذائية
│   │   │   └── history_event.dart ← نموذج سجل الأحداث
│   │   ├── database/
│   │   │   └── hive_db_helper.dart ← طبقة قاعدة البيانات (Hive) + إعدادات اللغة/الثيم
│   │   ├── services/
│   │   │   ├── groq_api_service.dart     ← خدمة API الذكاء الاصطناعي (Groq) - متعددة اللغات
│   │   │   ├── notification_service.dart ← خدمة الإشعارات المحلية
│   │   │   └── localization_service.dart ← قاموس الترجمة (AR / EN / ID)
│   │   └── screens/
│   │       ├── home_screen.dart              ← الشاشة الرئيسية
│   │       ├── recipe_screen.dart            ← وصفات AI + حفظ الوصفات
│   │       ├── expiry_tracker_screen.dart    ← متتبع الصلاحية
│   │       ├── dashboard_screen.dart         ← لوحة الإحصائيات
│   │       └── settings_screen.dart          ← ⚙️ الإعدادات العامة (جديد)
│   └── pubspec.yaml              ← تعريف المكتبات (Dependencies)
│
├── icon.png                      ← أيقونة التطبيق الأصلية
├── Diagram_User_Flow/            ← مخططات سير المستخدم (SVG)
├── Minggu_08/09/10_Panduan/      ← وثائق كل أسبوع
└── Modul_Proyek_Teknologi_Mobile_SDGs.pdf ← المرجع الأساسي للمادة
```

---

## 3. شاشات التطبيق والتنقل بينها (Navigation / Routing)

### نظام التنقل (Navigation System):
التطبيق يستخدم **BottomNavigationBar** (شريط تنقل سفلي ثابت) يحتوي على **5 تبويبات** رئيسية.

### الشاشات الخمس:

| رقم | أيقونة | اسم التبويب | الملف المسؤول | الوظيفة |
|-----|--------|------------|--------------|---------|
| 0 | 🏠 | **Beranda** (الرئيسية) | `home_screen.dart` | نظرة شاملة سريعة + تنبيهات قريبة الانتهاء |
| 1 | 👨‍🍳 | **Resep** (الوصفات) | `recipe_screen.dart` | اختيار مكونات + طلب وصفة من AI + حفظ الوصفات |
| 2 | 📅 | **Tracker** (المتتبع) | `expiry_tracker_screen.dart` | إدارة كاملة للمواد الغذائية (CRUD) |
| 3 | 📊 | **Dashboard** (اللوحة) | `dashboard_screen.dart` | إحصائيات الأثر البيئي والمالي |
| 4 | ⚙️ | **Settings** (الإعدادات) | `settings_screen.dart` | 🆕 اللغة، الثيم، API Key، مسح البيانات |

### كيف يعمل التنقل في الكود:
في ملف `main.dart` يوجد كلاس `MainNavigationShell` يحتوي على:
```dart
// الشاشات الخمس في قائمة
final List<Widget> screens = [
  HomeScreen(...),        // index 0
  RecipeScreen(...),      // index 1
  ExpiryTrackerScreen(),  // index 2
  DashboardScreen(...),   // index 3
  SettingsScreen(),       // index 4 ← جديد
];

// IndexedStack يعرض الشاشة المحددة فقط دون إعادة بناء
body: IndexedStack(index: _currentIndex, children: screens),
```
**السبب في استخدام `IndexedStack`:** يحافظ على حالة (state) كل شاشة حتى لو غادر المستخدم إليها وعاد، بخلاف `PageView` الذي يُعيد البناء.

---

## 4. قاعدة البيانات المحلية (Database - Hive)

### ما هو Hive؟
**Hive** هو قاعدة بيانات محلية تعمل بصيغة **Key-Value** مخصصة لـ Flutter. أسرع من SQLite لأنها مكتوبة بـ Dart خالصاً ولا تحتاج قناة Native.

### الجداول (Boxes) الموجودة:

#### صندوق 1: `food_items_box` (بيانات المواد الغذائية)
| الحقل | النوع | الوصف |
|-------|-------|-------|
| `id` | String | معرّف فريد (UUID) |
| `emoji` | String | رمز تعبيري للبصر السريع |
| `name` | String | اسم المادة |
| `category` | String | تصنيف (Sayur / Protein / Minuman...) |
| `daysLeft` | int | عدد الأيام المتبقية |
| `weight` | double | الوزن بالكيلوغرام |
| `price` | int | السعر بالروبية الإندونيسية (IDR) |

#### صندوق 2: `history_events_box` (سجل الأحداث)
| الحقل | النوع | الوصف |
|-------|-------|-------|
| `id` | String | معرّف فريد |
| `name` | String | اسم المادة المستخدمة |
| `emoji` | String | أيقونة المادة |
| `weight` | double | وزنها |
| `price` | int | قيمتها |
| `action` | String | `consumed` (تم طبخها) أو `wasted` (أُهدرت) |
| `timestamp` | int | وقت الحدث (milliseconds epoch) |

### عمليات CRUD في الكود:
```dart
// قراءة كل العناصر
HiveDbHelper.getFoodItems();

// إضافة أو تحديث عنصر
HiveDbHelper.saveFoodItem(item);

// حذف عنصر بمعرفه
HiveDbHelper.deleteFoodItem(item.id);

// حفظ حدث في السجل
HiveDbHelper.saveHistoryEvent(event);
```

---

## 5. خدمة الذكاء الاصطناعي - Groq API

### الخدمة المستخدمة:
**Groq** هي خدمة سحابية توفر واجهة برمجية (API) للوصول إلى نماذج لغوية كبيرة (LLM) بسرعة فائقة.

### الموديل المستخدم:
```
llama-3.3-70b-versatile
```
(نموذج Meta's Llama 3.3 بـ 70 مليار معامل — مجاني بحدود معينة)

### عنوان API النقطة (Endpoint):
```
POST https://api.groq.com/openai/v1/chat/completions
```

### كيفية الاستدعاء:
```dart
// في groq_api_service.dart
final response = await http.post(
  Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
  headers: {
    'Authorization': 'Bearer $GROQ_API_KEY',
    'Content-Type': 'application/json',
  },
  body: jsonEncode({
    'model': 'llama-3.3-70b-versatile',
    'messages': [
      { 'role': 'system', 'content': 'أنت طاهٍ ذكي...' },
      { 'role': 'user', 'content': 'المكونات: بيضة، خبز، حليب' }
    ],
  }),
);
```

### نظام الاحتياط (Fallback):
إذا لم يكن هناك `GROQ_API_KEY` في ملف `.env`، يعرض التطبيق **وصفة وهمية جاهزة (Mock Response)** — وهذا يضمن أن التطبيق يعمل حتى بدون إنترنت أو مفتاح.

```dart
// أول ما يفعله الكود عند استدعاء generateRecipes()
if (_apiKey.isEmpty) {
  return _getMockRecipeResponse(ingredients); // ← بديل تلقائي
}
```

### ملف إعداد المفتاح (`.env`):
```
GROQ_API_KEY=gsk_xxxxxxxxxxxxxxxxxxxx
```
هذا الملف **لا يُرفع لـ GitHub** (مدرج في `.gitignore`) لحماية المفتاح السري.

---

## 6. خدمة الإشعارات المحلية (Local Notifications)

### الحزمة المستخدمة:
```yaml
flutter_local_notifications: ^17.x
timezone: ^0.9.x
```

### الإعداد المطلوب عند التشغيل (في `main.dart`):
```dart
// 1. تهيئة المناطق الزمنية - يجب قبل أي شيء آخر
tz.initializeTimeZones();
tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));

// 2. تهيئة خدمة الإشعارات
await NotificationService().initialize();
```
> ⚠️ **خطأ شائع:** إذا لم تُنفَّذ هاتان الخطوتان قبل استخدام `tz.local`، يظهر الخطأ:
> `LateInitializationError: Field '_local' has not been initialized.`

### متى تُرسَل الإشعارات؟
عند إضافة مادة غذائية وتحديد تاريخ انتهائها، يُجدوِل التطبيق إشعاراً قبل يوم واحد من الانتهاء تلقائياً.

---

## 7. شاشة تتبع الصلاحية بالتفصيل (Expiry Tracker Screen)

**الملف:** `lib/screens/expiry_tracker_screen.dart`

### الميزات الكاملة:
- ✅ **إضافة (Create):** نموذج (BottomSheet) لإضافة مادة جديدة مع الاسم، التصنيف، الوزن، السعر، وتاريخ الانتهاء
- ✅ **عرض (Read):** قائمة مصنفة بأيقونات وشريط حالة ملوّن (أخضر/برتقالي/أحمر) حسب عدد الأيام المتبقية
- ✅ **تعديل (Update):** النقر على عنصر يفتح نموذج التعديل مع البيانات الحالية
- ✅ **حذف (Delete):** الحذف من قاعدة البيانات مع إضافة سجل `wasted` في السجل التاريخي
- ✅ **إشعارات تلقائية:** جدولة إشعار عند الإضافة والتعديل

### مؤشرات الصلاحية اللونية:
| اللون | المعنى | عدد الأيام |
|-------|---------|-----------|
| 🔴 أحمر | عاجل جداً! | 0-2 يوم |
| 🟠 برتقالي | تحذير | 3-7 أيام |
| 🟢 أخضر | آمن | أكثر من 7 أيام |

---

## 8. شاشة الوصفات بالتفصيل (Recipe Screen)

**الملف:** `lib/screens/recipe_screen.dart`

### تدفق العمل (User Flow):
```
المستخدم يرى بطاقات المكونات من Hive
     ↓
يضغط على المكونات التي يريد طبخها (اختيار متعدد)
     ↓
يضغط "Cari Resep" (ابحث عن وصفة)
     ↓
يُرسَل الطلب لـ Groq API
     ↓
تظهر الوصفة مع خيار "Selesai Memasak" (انتهيت من الطبخ)
     ↓
[عند الضغط على "Selesai Memasak"]
يُحذف كل مكوّن مُستخدَم من Hive
ويُضاف سجل "consumed" في history_events_box
```

### الميزة الذكية (Smart Consumption):
```dart
// في recipe_screen.dart عند الضغط على "Selesai Memasak"
for (final item in _selectedItems) {
  await HiveDbHelper.deleteFoodItem(item.id); // حذف من المخزن
  await HiveDbHelper.saveHistoryEvent(        // إضافة للتاريخ
    HistoryEvent(action: 'consumed', ...)
  );
}
```
هذا يُحدّث لوحة الإحصائيات (Dashboard) تلقائياً.

---

## 9. لوحة الإحصائيات (Eco-Impact Dashboard)

**الملف:** `lib/screens/dashboard_screen.dart`

### الأرقام المعروضة:
| المقياس | الحساب |
|---------|-------|
| **مجموع ما تم استهلاكه (Dikonsumsi)** | عدد السجلات بـ `action = 'consumed'` |
| **مجموع ما أُهدر (Terbuang)** | عدد السجلات بـ `action = 'wasted'` |
| **الوزن المحفوظ (kg)** | مجموع `weight` للأحداث المستهلكة |
| **التوفير المالي (IDR)** | مجموع `price` للأحداث المستهلكة |
| **نسبة الكفاءة** | `consumed / (consumed + wasted) × 100%` |

---

## 10. الشاشة الرئيسية (Home Screen / Beranda)

**الملف:** `lib/screens/home_screen.dart`

### المحتوى:
- **بانر ترحيب** يعرض عدد المواد الموجودة في المخزن
- **قائمة التنبيهات** للمواد التي ستنتهي خلال 3 أيام
- **أزرار الوصول السريع (Quick Actions)** للانتقال مباشرة لأي شاشة
- **خيار تغيير المظهر** (وضع مظلم/مضيء - Dark Mode Toggle)

---

## 11. تدفق البيانات الكامل (Data Flow Architecture)

```
[المستخدم يُضيف بيانات]
        ↓
[ExpiryTrackerScreen - expiry_tracker_screen.dart]
        ↓
[HiveDbHelper.saveFoodItem()]
        ↓
[food_items_box في Hive (ذاكرة الجهاز)]
        ↓
[RecipeScreen تقرأ البيانات → ترسل لـ Groq API]
        ↓
[GroqApiService.generateRecipes()]
        ↓
[POST → api.groq.com → رد JSON]
        ↓
[عرض الوصفة → المستخدم يضغط "Selesai"]
        ↓
[HiveDbHelper.deleteFoodItem() + saveHistoryEvent()]
        ↓
[DashboardScreen تقرأ history_events_box → تعرض الإحصائيات]
```

---

## 12. المكتبات المستخدمة (Dependencies - pubspec.yaml)

| المكتبة | الاستخدام |
|---------|----------|
| `hive_flutter` | قاعدة البيانات المحلية (Local DB) |
| `flutter_dotenv` | قراءة ملف `.env` لمفاتيح API |
| `http` | إرسال طلبات HTTP لـ Groq API |
| `provider` | إدارة الحالة لوضع الألوان (Dark Mode) |
| `flutter_local_notifications` | إشعارات تذكير الصلاحية |
| `timezone` | دعم التواريخ بالمنطقة الزمنية (Asia/Jakarta) |
| `lucide_icons` | مجموعة أيقونات جميلة للواجهة |
| `uuid` | توليد معرّفات فريدة (ID) للعناصر |

---

## 13. كيفية تشغيل المشروع (Cara Menjalankan Proyek)

### المتطلبات:
- Flutter SDK مثبت
- Android Emulator أو هاتف فعلي
- (اختياري) مفتاح Groq API مجاني من: https://console.groq.com

### خطوات التشغيل:
```bash
# 1. الانتقال لمجلد التطبيق
cd sisa_pintar_flutter

# 2. تحميل المكتبات
flutter pub get

# 3. تشغيل التطبيق
flutter run
```

### إضافة مفتاح API (اختياري):
```bash
# أنشئ ملف .env في مجلد sisa_pintar_flutter/
echo GROQ_API_KEY=gsk_xxxxxxxx > .env
```
> بدون هذا المفتاح، يعمل التطبيق بالكامل لكن يعرض وصفة وهمية بدلاً من AI.

---

## 14. نقاط القوة والاستعداد للتقييم

### ما نجح في التطبيق (Fitur Berhasil):
- ✅ CRUD كامل للمواد الغذائية مع قاعدة بيانات دائمة
- ✅ إشعارات محلية تعمل بدون إنترنت
- ✅ تكامل مع Groq AI للوصفات الذكية
- ✅ داشبورد إحصائي ديناميكي
- ✅ دعم الوضع المظلم (Dark Mode)
- ✅ بيانات تجريبية جاهزة عند أول تشغيل

### توزيع أدوار الفريق (Team Roles):
| العضو | NIM | الدور |
|-------|-----|-------|
| **Mohammed Rashed** | 2406016105 | Full-Stack Developer (البرمجة الكاملة) |
| **Dania Elsadig** | 2406016106 | UI/UX & Quality Assurance (التصميم والاختبار) |
| **Moh Dzikry Pradana** | 2300016137 | Desainer Poster & Dokumentasi (تصميم الپوستر والتوثيق) |

### التحديات التقنية التي تمت معالجتها (Kendala & Solusi):
| المشكلة | الحل |
|---------|------|
| `LateInitializationError` في timezone | تهيئة `tz.initializeTimeZones()` في `main()` قبل كل شيء |
| `BuildContext` بعد async | حفظ `messenger` و `nav` قبل `await` |
| وصفات الـ Mock لا تعكس المكونات الفعلية | تمرير قائمة `ingredients` الحقيقية لـ `_getMockRecipeResponse()` |

### خطة التطوير المستقبلي (Future Roadmap):
1. **Cloud Sync** عبر Firebase
2. **OCR / Barcode Scanner** لمسح المنتجات
3. **Food Sharing Community** لمشاركة الطعام الزائد

---

## 15. أسئلة متوقعة وإجاباتها (Pertanyaan & Jawaban)

**س: لماذا اخترتم Hive وليس SQLite؟**
> لأن Hive أسرع في Flutter، لا يحتاج SQL Schema، وسهل الاستخدام مع Dart Objects مباشرةً.

**س: هل التطبيق يعمل بدون إنترنت؟**
> نعم! قاعدة البيانات محلية (Hive) والإشعارات محلية. فقط خاصية الوصفات الـ AI تحتاج إنترنت، وعند انقطاعه يعرض وصفة احتياطية (Mock).

**س: كيف يرتبط التطبيق بـ SDGs؟**
> يُساهم في Goal 2 (Zero Hunger) بتحويل البقايا لوجبات مفيدة، وGoal 12 (Responsible Consumption) بقياس وتقليل هدر الطعام.

**س: ما هو Groq؟**
> منصة سحابية توفر واجهة API للنماذج اللغوية الكبيرة (LLM) بأداء عالٍ. نستخدم نموذج Llama 3.3 70B من Meta مجاناً.

**س: كيف يحدّث الـ Dashboard نفسه؟**
> كل ما ضغط المستخدم "Selesai Memasak"، يُحذف المكوّن من `food_items_box` ويُضاف حدث جديد في `history_events_box` بـ `action: consumed`. الـ Dashboard يقرأ من `history_events_box` مباشرةً عند كل فتح.

**س: لماذا IndexedStack وليس Navigator؟**
> لأن `IndexedStack` يُبقي حالة (state) كل شاشة محفوظة، فعند العودة للشاشة لا تُعاد قراءة البيانات من صفر — وهذا يُحسّن الأداء وتجربة المستخدم.

---

*وُثِّق هذا الدليل استعداداً للقاء التقييمي (Responsi) — Minggu 10*  
*آخر تحديث: يونيو 2025*
