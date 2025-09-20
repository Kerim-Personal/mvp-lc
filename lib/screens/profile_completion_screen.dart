import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vocachat/services/translation_service.dart';
import 'package:circle_flags/circle_flags.dart';

// Bayrak eşleme ve bastırma setleri tek yerde tanımlandı
const _flagMap = <String,String>{
  'af':'za','sq':'al','ar':'sa','be':'by','bg':'bg','bn':'bd','ca':'ad','zh':'cn','hr':'hr','cs':'cz','da':'dk','nl':'nl','en':'gb','et':'ee','fi':'fi','fr':'fr','gl':'es','ka':'ge','de':'de','el':'gr','he':'il','hi':'in','hu':'hu','is':'is','id':'id','ga':'ie','it':'it','ja':'jp','ko':'kr','lv':'lv','lt':'lt','mk':'mk','ms':'my','mt':'mt','no':'no','fa':'ir','pl':'pl','pt':'pt','ro':'ro','ru':'ru','sk':'sk','sl':'si','es':'es','sw':'tz','sv':'se','tl':'ph','ta':'lk','th':'th','tr':'tr','uk':'ua','ur':'pk','vi':'vn','ht':'ht','gu':'in','kn':'in','te':'in','mr':'in'};
// Sadece bayrağı olmayan/sembolik diller
const _suppressFlag = {'eo','cy'};
// Hindistan grubu (aynı bayrak gösterilecek)
const _indianGroup = {'hi','gu','kn','te','mr'};

String? _countryGroup(String code){
  if (_indianGroup.contains(code)) return 'in';
  if (_flagMap.containsKey(code)) return _flagMap[code];
  return null; // sembolik ya da özel
}

class ProfileCompletionScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  const ProfileCompletionScreen({super.key, required this.userData});

  @override
  State<ProfileCompletionScreen> createState() => _ProfileCompletionScreenState();
}

class _ProfileCompletionScreenState extends State<ProfileCompletionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _birthDateController = TextEditingController();
  String? _nativeLanguageCode; // ISO code
  DateTime? _birthDate;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _displayNameController.text = widget.userData['displayName'] ?? '';
    _nativeLanguageCode = widget.userData['nativeLanguage'];
    final ts = widget.userData['birthDate'];
    if (ts is Timestamp) {
      _birthDate = ts.toDate();
      _birthDateController.text = DateFormat('dd/MM/yyyy').format(_birthDate!);
    }
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _birthDateController.dispose();
    super.dispose();
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final initial = _birthDate ?? DateTime(now.year - 20);
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(1940),
      lastDate: now,
      initialDate: initial,
    );
    if (picked != null) {
      setState(() {
        _birthDate = picked;
        _birthDateController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  void _selectLanguage() {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        // Kopya ve sıralama
        final langs = List<Map<String,String>>.from(TranslationService.supportedLanguages);
        langs.sort((a,b){
          final ca = _countryGroup(a['code']!);
            final cb = _countryGroup(b['code']!);
          final gc = (ca ?? 'zzz').compareTo(cb ?? 'zzz'); // null'lar sona
          if (gc != 0) return gc;
          return a['label']!.toLowerCase().compareTo(b['label']!.toLowerCase());
        });

        String? prevGroup;
        final tiles = <Widget>[const ListTile(title: Text('Select Native Language'))];
        for (final m in langs){
          final code = m['code']!;
          final label = m['label']!;
          final group = _countryGroup(code) ?? code; // sembolikler kendi koduyla ayırıcı
          if (prevGroup != null && group != prevGroup){
            tiles.add(const Divider(height: 4, thickness: 0.5));
          }
          prevGroup = group;
          final selected = code == _nativeLanguageCode;
          tiles.add(ListTile(
            leading: _Flag(code: code),
            title: Text(label),
            trailing: selected ? const Icon(Icons.check, color: Colors.teal) : null,
            onTap: () { setState(()=> _nativeLanguageCode = code); Navigator.pop(context); },
          ));
        }
        return SafeArea(child: ListView(children: tiles));
      },
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _birthDate == null || _nativeLanguageCode == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields'), backgroundColor: Colors.red),
      );
      return;
    }
    setState(() { _saving = true; });
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final docRef = FirebaseFirestore.instance.collection('users').doc(uid);
      final displayName = _displayNameController.text.trim();
      await docRef.update({
        'displayName': displayName,
        'username_lowercase': displayName.toLowerCase(),
        'birthDate': Timestamp.fromDate(_birthDate!),
        'nativeLanguage': _nativeLanguageCode,
        'profileCompleted': true,
        'lastActivityDate': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() { _saving = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Your Profile'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Welcome! Before continuing, a few details:'),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _displayNameController,
                  maxLength: 30,
                  decoration: const InputDecoration(labelText: 'Display Name'),
                  validator: (v) {
                    final t = v?.trim() ?? '';
                    if (t.length < 3) return 'At least 3 characters';
                    if (t.length > 29) return 'At most 29 characters';
                    return null;
                  },
                ),
                TextFormField(
                  controller: _birthDateController,
                  readOnly: true,
                  decoration: const InputDecoration(labelText: 'Date of Birth'),
                  onTap: _pickBirthDate,
                  validator: (v) => (v==null||v.isEmpty)?'Select':null,
                ),
                const SizedBox(height: 10),
                const SizedBox(height: 10),
                InkWell(
                  onTap: _selectLanguage,
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: 'Native Language'),
                    child: Row(
                      children: [
                        if (_nativeLanguageCode != null) _Flag(code: _nativeLanguageCode!),
                        if (_nativeLanguageCode != null) const SizedBox(width: 8),
                        Text(
                          _nativeLanguageCode == null
                            ? 'Select'
                            : (TranslationService.supportedLanguages.firstWhere(
                                (m)=>m['code']==_nativeLanguageCode,
                                orElse: ()=>{'label': _nativeLanguageCode!.toUpperCase()},
                              )['label'])!,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: _saving? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _saving ? const SizedBox(height:20,width:20,child:CircularProgressIndicator(color: Colors.white,strokeWidth:2)) : const Text('Save and Continue'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Flag extends StatelessWidget {
  final String code;
  const _Flag({required this.code});
  @override
  Widget build(BuildContext context) {
    if (!_flagMap.containsKey(code) || _suppressFlag.contains(code)) {
      return Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(color: Colors.grey.shade300, shape: BoxShape.circle),
        alignment: Alignment.center,
        child: Text(code.toUpperCase(), style: const TextStyle(fontSize: 10,fontWeight: FontWeight.w600,color: Colors.black87)),
      );
    }
    return CircleFlag(_flagMap[code]!.toLowerCase(), size: 28);
  }
}
