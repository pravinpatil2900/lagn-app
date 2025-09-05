
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:http/http.dart' as http;

const String API_BASE   = 'https://live.betablaster.in/api/send';
const String INSTANCE_ID = '6881CE8BC1285';
const String ACCESS_TOKEN = '6881cc07a4e27';

Future<bool> sendWhatsAppText({
  required String number,
  required String message,
}) async {
  String digits = number.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.startsWith('0')) digits = digits.substring(1);
  if (!digits.startsWith('91')) {
    if (digits.length == 10) digits = '91' + digits;
  }
  final uri = Uri.parse(API_BASE).replace(queryParameters: {
    'number': digits,
    'type': 'text',
    'message': message,
    'instance_id': INSTANCE_ID,
    'access_token': ACCESS_TOKEN,
  });
  try {
    final res = await http.get(uri).timeout(const Duration(seconds: 15));
    return res.statusCode == 200;
  } catch (_) {
    return false;
  }
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const LagnApp());
}

class LagnApp extends StatelessWidget {
  const LagnApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Lagn',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.red,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      const FormPage(),
      const SearchPage(),
      const ReportPage(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('लग्न — Marathi Form'),
        centerTitle: true,
      ),
      body: pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.note_add_outlined), label: 'Form'),
          NavigationDestination(icon: Icon(Icons.search), label: 'Search'),
          NavigationDestination(icon: Icon(Icons.list_alt), label: 'Report'),
        ],
      ),
    );
  }
}

class Candidate {
  final int? id;
  final String idNo;
  final String name;
  final String mobile;
  final String birthDate;
  final String age;
  final String income;
  final String otherInfo;
  final String apeksha;
  final String madhyasthiMobile;
  final String photo1Path;
  final String photo2Path;

  Candidate({
    this.id,
    required this.idNo,
    required this.name,
    required this.mobile,
    required this.birthDate,
    required this.age,
    required this.income,
    required this.otherInfo,
    required this.apeksha,
    required this.madhyasthiMobile,
    required this.photo1Path,
    required this.photo2Path,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'idNo': idNo,
        'name': name,
        'mobile': mobile,
        'birthDate': birthDate,
        'age': age,
        'income': income,
        'otherInfo': otherInfo,
        'apeksha': apeksha,
        'madhyasthiMobile': madhyasthiMobile,
        'photo1Path': photo1Path,
        'photo2Path': photo2Path,
      };

  factory Candidate.fromMap(Map<String, dynamic> m) => Candidate(
        id: m['id'] as int?,
        idNo: m['idNo'] as String,
        name: m['name'] as String,
        mobile: m['mobile'] as String,
        birthDate: m['birthDate'] as String,
        age: m['age'] as String,
        income: m['income'] as String,
        otherInfo: m['otherInfo'] as String,
        apeksha: m['apeksha'] as String,
        madhyasthiMobile: m['madhyasthiMobile'] as String,
        photo1Path: m['photo1Path'] as String,
        photo2Path: m['photo2Path'] as String,
      );
}

class DB {
  static Database? _db;

  static Future<Database> get instance async {
    if (_db != null) return _db!;
    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, 'lagn.db');
    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, v) async {
        await db.execute('''
          CREATE TABLE candidates(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            idNo TEXT,
            name TEXT,
            mobile TEXT,
            birthDate TEXT,
            age TEXT,
            income TEXT,
            otherInfo TEXT,
            apeksha TEXT,
            madhyasthiMobile TEXT,
            photo1Path TEXT,
            photo2Path TEXT
          );
        ''');
      },
    );
    return _db!;
  }

  static Future<int> insert(Candidate c) async {
    final db = await instance;
    return db.insert('candidates', c.toMap());
  }

  static Future<List<Candidate>> all() async {
    final db = await instance;
    final rows = await db.query('candidates', orderBy: 'id DESC');
    return rows.map((e) => Candidate.fromMap(e)).toList();
  }

  static Future<List<Candidate>> search({String? idNo, String? name, String? mobile}) async {
    final db = await instance;
    final where = <String>[];
    final args = <Object?>[];
    if (idNo != null && idNo.isNotEmpty) {
      where.add('idNo LIKE ?');
      args.add('%' + idNo + '%');
    }
    if (name != null && name.isNotEmpty) {
      where.add('name LIKE ?');
      args.add('%' + name + '%');
    }
    if (mobile != null && mobile.isNotEmpty) {
      where.add('mobile LIKE ?');
      args.add('%' + mobile + '%');
    }
    final res = await db.query(
      'candidates',
      where: where.isEmpty ? null : where.join(' AND '),
      whereArgs: where.isEmpty ? null : args,
      orderBy: 'id DESC',
    );
    return res.map((e) => Candidate.fromMap(e)).toList();
  }
}

class FormPage extends StatefulWidget {
  const FormPage({super.key});

  @override
  State<FormPage> createState() => _FormPageState();
}

class _FormPageState extends State<FormPage> {
  final _f = GlobalKey<FormState>();
  final tId = TextEditingController();
  final tName = TextEditingController();
  final tMobile = TextEditingController();
  final tBirth = TextEditingController();
  final tAge = TextEditingController();
  final tIncome = TextEditingController();
  final tOther = TextEditingController();
  final tApeksha = TextEditingController();
  final tMadhyasthi = TextEditingController();

  File? photo1;
  File? photo2;

  Future<void> _pick(int which) async {
    final picker = ImagePicker();
    final x = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (x == null) return;
    final dir = await getApplicationDocumentsDirectory();
    final target = File(p.join(dir.path, 'photo_' + DateTime.now().millisecondsSinceEpoch.toString() + '_' + p.basename(x.path)));
    await target.writeAsBytes(await x.readAsBytes());
    setState(() {
      if (which == 1) { photo1 = target; } else { photo2 = target; }
    });
  }

  void _new() {
    _f.currentState?.reset();
    tId.clear(); tName.clear(); tMobile.clear(); tBirth.clear();
    tAge.clear(); tIncome.clear(); tOther.clear(); tApeksha.clear(); tMadhyasthi.clear();
    setState(() { photo1 = null; photo2 = null; });
  }

  Future<void> _submit() async {
    if (!_f.currentState!.validate()) return;
    final c = Candidate(
      idNo: tId.text.trim(),
      name: tName.text.trim(),
      mobile: tMobile.text.trim(),
      birthDate: tBirth.text.trim(),
      age: tAge.text.trim(),
      income: tIncome.text.trim(),
      otherInfo: tOther.text.trim(),
      apeksha: tApeksha.text.trim(),
      madhyasthiMobile: tMadhyasthi.text.trim(),
      photo1Path: photo1?.path ?? '',
      photo2Path: photo2?.path ?? '',
    );
    await DB.insert(c);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('जतन झाले')));
      _new();
    }
  }

  Future<void> _sendNow() async {
    if (tMobile.text.trim().isEmpty && tMadhyasthi.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('मोबाईल/मध्यस्थी मोबाईल भरा')));
      return;
    }
    final parts = tName.text.trim().split(' ').where((s) => s.trim().isNotEmpty).toList();
    final lastName = parts.isNotEmpty ? parts.last : tName.text.trim();
    final msg = (
      "*आपले स्वागत आहे*\n"
      "*मॅरेज बिरो विवाह कंपनी सातारा*\n\n"
      "नाव: " + tName.text.trim() + "\n"
      "जन्मतारीख: " + tBirth.text.trim() + "\n"
      "वय: " + tAge.text.trim() + "\n"
      "अपेक्षा: " + tApeksha.text.trim() + "\n\n"
      + lastName + " साहेब/मॅडम, कृपया ऑफिसला भेट देण्यासाठी आपण सोयीचा वेळ कळवा.\n"
      "धन्यवाद!"
    );

    final to = tMadhyasthi.text.trim().isNotEmpty ? tMadhyasthi.text.trim() : tMobile.text.trim();
    final ok = await sendWhatsAppText(number: to, message: msg);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? 'WhatsApp संदेश पाठवला' : 'संदेश पाठवण्यात अडचण आली')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _f,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(children: [
              Expanded(child: _tf(tId, 'ID No.')), const SizedBox(width: 8),
              Expanded(child: _tf(tName, 'नाव', required: true)),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: _tf(tMobile, 'मोबाईल नंबर', required: true, kb: TextInputType.phone)),
              const SizedBox(width: 8),
              Expanded(child: _tf(tBirth, 'जन्मतारीख (DD-MM-YYYY)')),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: _tf(tAge, 'वय (auto/हस्ते)')),
              const SizedBox(width: 8),
              Expanded(child: _tf(tIncome, 'उत्पन्न')),
            ]),
            const SizedBox(height: 8),
            _tf(tOther, 'इतर माहिती'),
            const SizedBox(height: 8),
            _tf(tApeksha, 'अपेक्षा'),
            const SizedBox(height: 8),
            _tf(tMadhyasthi, 'मध्यस्थी मोबाईल'),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: OutlinedButton.icon(onPressed: () => _pick(1), icon: const Icon(Icons.photo), label: const Text('Photo 1 निवडा'))),
              const SizedBox(width: 8),
              Expanded(child: OutlinedButton.icon(onPressed: () => _pick(2), icon: const Icon(Icons.photo), label: const Text('Photo 2 निवडा'))),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: Container(height: 140, decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(12)),
                child: photo1 == null ? const Center(child: Text('Photo 1 Preview'))
                  : ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(photo1!, fit: BoxFit.cover)))),
              const SizedBox(width: 8),
              Expanded(child: Container(height: 140, decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(12)),
                child: photo2 == null ? const Center(child: Text('Photo 2 Preview')
                  ) : ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(photo2!, fit: BoxFit.cover)))),
            ]),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: FilledButton.icon(onPressed: _submit, icon: const Icon(Icons.save), label: const Text('Submit'))),
              const SizedBox(width: 8),
              Expanded(child: OutlinedButton.icon(onPressed: _new, icon: const Icon(Icons.refresh), label: const Text('New'))),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: FilledButton.icon(onPressed: _sendNow, icon: const Icon(Icons.send), label: const Text('Send WhatsApp'))),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _tf(TextEditingController c, String label, {bool required = false, TextInputType? kb}) {
    return TextFormField(
      controller: c,
      keyboardType: kb,
      decoration: InputDecoration(labelText: label, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
      validator: required ? (v) => (v == null || v.trim().isEmpty) ? 'आवश्यक' : null : null,
    );
  }
}

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});
  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final sId = TextEditingController();
  final sName = TextEditingController();
  final sMobile = TextEditingController();
  List<Candidate> results = [];

  Future<void> _doSearch() async {
    results = await DB.search(idNo: sId.text.trim(), name: sName.text.trim(), mobile: sMobile.text.trim());
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: _tf(sId, 'ID No')), const SizedBox(width: 8),
          Expanded(child: _tf(sName, 'नाव')), const SizedBox(width: 8),
          Expanded(child: _tf(sMobile, 'मोबाईल')),
        ]),
        const SizedBox(height: 8),
        Align(alignment: Alignment.centerRight, child: FilledButton.icon(onPressed: _doSearch, icon: const Icon(Icons.search), label: const Text('Search'))),
        const SizedBox(height: 12),
        Expanded(child: results.isEmpty ? const Center(child: Text('निकाल नाहीत')) : ListView.separated(
          itemBuilder: (c, i) {
            final x = results[i];
            return ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              tileColor: Colors.grey.shade100,
              leading: _thumb(x.photo1Path),
              title: Text('${x.name}  (${x.idNo})'),
              subtitle: Text('मोबाईल: ${x.mobile}\nजन्म: ${x.birthDate}  |  वय: ${x.age}\nअपेक्षा: ${x.apeksha}'),
              isThreeLine: true,
              trailing: IconButton(icon: const Icon(Icons.send), onPressed: () async {
                final ok = await sendWhatsAppText(
                  number: x.madhyasthiMobile.isNotEmpty ? x.madhyasthiMobile : x.mobile,
                  message: '*${x.name}* (${x.idNo})\nजन्म: ${x.birthDate} | वय: ${x.age}\nअपेक्षा: ${x.apeksha}\n— मॅरेज बिरो विवाह कंपनी सातारा',
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? 'WhatsApp संदेश पाठवला' : 'संदेश पाठवण्यात अडचण आली')));
                }
              }),
            );
          },
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemCount: results.length,
        )),
      ]),
    );
  }

  Widget _tf(TextEditingController c, String label) => TextField(
    controller: c,
    decoration: InputDecoration(labelText: label, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
  );

  Widget _thumb(String path) {
    if (path.isEmpty) return const CircleAvatar(child: Icon(Icons.person));
    final f = File(path);
    if (!f.existsSync()) return const CircleAvatar(child: Icon(Icons.person));
    return CircleAvatar(backgroundImage: FileImage(f));
  }
}

class ReportPage extends StatefulWidget {
  const ReportPage({super.key});
  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  Future<List<Candidate>>? _future;
  @override
  void initState() { super.initState(); _future = DB.all(); }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: FutureBuilder<List<Candidate>>(
        future: _future,
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final data = snap.data!;
          if (data.isEmpty) return const Center(child: Text('रेकॉर्ड उपलब्ध नाहीत'));
          return ListView.separated(
            itemCount: data.length,
            itemBuilder: (c, i) {
              final x = data[i];
              return Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      _bigThumb(x.photo1Path),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('${x.name}  •  ${x.idNo}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text('मोबाईल: ${x.mobile}'),
                        Text('जन्मतारीख: ${x.birthDate}  |  वय: ${x.age}'),
                        Text('उत्पन्न: ${x.income}'),
                      ])),
                      IconButton(icon: const Icon(Icons.send), onPressed: () async {
                        final ok = await sendWhatsAppText(
                          number: x.madhyasthiMobile.isNotEmpty ? x.madhyasthiMobile : x.mobile,
                          message: '*${x.name}* (${x.idNo})\nजन्म: ${x.birthDate} | वय: ${x.age}\nअपेक्षा: ${x.apeksha}\n— मॅरेज बिरो विवाह कंपनी सातारा',
                        );
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? 'WhatsApp संदेश पाठवला' : 'संदेश पाठवण्यात अडचण आली')));
                        }
                      }),
                    ]),
                    const Divider(height: 20),
                    Text('इतर माहिती: ' + x.otherInfo),
                    Text('अपेक्षा: ' + x.apeksha),
                    Text('मध्यस्थी मोबाईल: ' + x.madhyasthiMobile),
                  ]),
                ),
              );
            },
            separatorBuilder: (_, __) => const SizedBox(height: 8),
          );
        },
      ),
    );
  }

  Widget _bigThumb(String path) {
    if (path.isEmpty) {
      return const SizedBox(width: 72, height: 72, child: CircleAvatar(child: Icon(Icons.person)));
    }
    final f = File(path);
    if (!f.existsSync()) {
      return const SizedBox(width: 72, height: 72, child: CircleAvatar(child: Icon(Icons.person)));
    }
    return ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(f, width: 72, height: 72, fit: BoxFit.cover));
  }
}
