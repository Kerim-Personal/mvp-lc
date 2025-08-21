// lib/screens/support_request_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lingua_chat/widgets/store_screen/premium_animated_background.dart';
import 'package:lingua_chat/widgets/store_screen/glassmorphism.dart';
import 'dart:math' as math;
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class SupportRequestScreen extends StatefulWidget {
  const SupportRequestScreen({super.key});

  @override
  State<SupportRequestScreen> createState() => _SupportRequestScreenState();
}

class _SupportRequestScreenState extends State<SupportRequestScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _subjectCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  bool _submitting = false;
  // Animations for premium feel
  late final AnimationController _titleShimmerController;
  late final AnimationController _ctaPulseController;

  // Seçilebilir konu başlıkları (genel)
  static const List<String> _subjectOptions = [
    'Ödeme / Abonelik',
    'Eşleşme / Partner Bulma',
    'Uygulama Hata Raporu',
    'Hesap / Giriş',
    'Performans / Hız',
    'Öneri / Geri Bildirim',
    'Diğer',
  ];

  // Fotoğraf ekleri
  String? _attachmentUrl;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    _titleShimmerController = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();
    _ctaPulseController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _subjectCtrl.dispose();
    _messageCtrl.dispose();
    _titleShimmerController.dispose();
    _ctaPulseController.dispose();
    super.dispose();
  }

  Future<void> _submit({required bool isPremium}) async {
    final valid = _formKey.currentState!.validate();
    if (!valid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen konu seçin ve mesajınızı yeterli detayla girin.')),
      );
      return;
    }
    if (_uploading) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fotoğraf yükleniyor, lütfen bekleyin.')),
      );
      return;
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Devam etmek için giriş yapın.')),
      );
      return;
    }
    if (!isPremium) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bu özellik sadece Lingua Pro kullanıcılarına açıktır.')),
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      final usersDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final udata = usersDoc.data();
      final displayName = (udata?['displayName'] as String?) ?? '';
      final email = user.email ?? (udata?['email'] as String?);

      await FirebaseFirestore.instance.collection('support').add({
        'userId': user.uid,
        'email': email,
        'displayName': displayName,
        'subject': _subjectCtrl.text.trim(),
        'message': _messageCtrl.text.trim(),
        'attachments': _attachmentUrl != null ? [_attachmentUrl] : [],
        'status': 'open',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'platform': Theme.of(context).platform.name,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Talebin alındı! Destek ekibi en kısa sürede dönüş yapacak.')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gönderilemedi: $e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _pickSubject() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text('Konu Seç', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _subjectOptions.length,
                  itemBuilder: (context, index) {
                    final item = _subjectOptions[index];
                    final isSelected = item == _subjectCtrl.text;
                    return ListTile(
                      leading: Icon(
                        isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                        color: isSelected ? Colors.amber : Colors.grey,
                      ),
                      title: Text(item),
                      onTap: () => Navigator.of(context).pop(item),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );

    if (selected != null) {
      setState(() => _subjectCtrl.text = selected);
    }
  }

  Future<void> _chooseImageSource() async {
    final src = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galeriden Seç'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Kameradan Çek'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            if (_attachmentUrl != null)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Ekli Fotoğrafı Kaldır', style: TextStyle(color: Colors.red)),
                onTap: () => Navigator.pop(context, null),
              ),
          ],
        ),
      ),
    );

    if (src == null) {
      // null burada "kaldır" anlamında kullanıldı
      if (_attachmentUrl != null) setState(() => _attachmentUrl = null);
      return;
    }

    final picker = ImagePicker();
    try {
      final picked = await picker.pickImage(source: src, maxWidth: 1920, imageQuality: 85);
      if (picked == null) return;

      setState(() => _uploading = true);
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw 'Oturum bulunamadı';

      final fileName = 'support_${DateTime.now().millisecondsSinceEpoch}_${picked.name}';
      final ref = FirebaseStorage.instance.ref().child('support').child(user.uid).child(fileName);
      await ref.putData(await picked.readAsBytes());
      final url = await ref.getDownloadURL();

      if (!mounted) return;
      setState(() {
        _attachmentUrl = url;
        _uploading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _uploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fotoğraf yüklenemedi: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Destek')),
        body: const Center(child: Text('Destek göndermek için giriş yapın.')),
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
      builder: (context, snap) {
        final isPremium = (snap.data?.data()?['isPremium'] as bool?) ?? false;

        if (!isPremium) {
          return Scaffold(
            appBar: AppBar(title: const Text('Destek')),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.lock, size: 48, color: Colors.grey),
                    SizedBox(height: 12),
                    Text('Bu özellik sadece Lingua Pro kullanıcılarına açıktır.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          );
        }

        // PREMIUM GÖRÜNÜM
        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: const Text(''),
          ),
          body: Stack(
            children: [
              const PremiumAnimatedBackground(),
              SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Shimmer Title + Badge
                      Center(
                        child: Column(
                          children: [
                            AnimatedBuilder(
                              animation: _titleShimmerController,
                              builder: (context, _) {
                                final v = _titleShimmerController.value;
                                final stops = [
                                  (v - 0.25).clamp(0.0, 1.0),
                                  v,
                                  (v + 0.25).clamp(0.0, 1.0),
                                ];
                                return ShaderMask(
                                  blendMode: BlendMode.srcIn,
                                  shaderCallback: (bounds) => LinearGradient(
                                    colors: const [Colors.amber, Colors.white, Colors.amber],
                                    stops: stops,
                                  ).createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
                                  child: const Text(
                                    'Lingua Pro Destek',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                      shadows: [Shadow(blurRadius: 10, color: Colors.black26)],
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.amber.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.amber.shade300),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(Icons.workspace_premium, color: Colors.amber, size: 18),
                                  SizedBox(width: 6),
                                  Text('Sadece Pro', style: TextStyle(fontWeight: FontWeight.w700)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Glass form card
                      GlassmorphicContainer(
                        width: double.infinity,
                        borderRadius: 24,
                        blur: 16,
                        border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 1.2),
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color.fromARGB(170, 255, 255, 255),
                            Color.fromARGB(90, 255, 255, 255),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Form(
                            key: _formKey,
                            autovalidateMode: AutovalidateMode.onUserInteraction,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Konu seçimi (read-only field + bottom sheet)
                                TextFormField(
                                  controller: _subjectCtrl,
                                  readOnly: true,
                                  onTap: _pickSubject,
                                  decoration: const InputDecoration(
                                    labelText: 'Konu',
                                    hintText: 'Konu seçin',
                                    border: OutlineInputBorder(),
                                    suffixIcon: Icon(Icons.expand_more),
                                  ),
                                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Lütfen bir konu seçin' : null,
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _messageCtrl,
                                  minLines: 6,
                                  maxLines: 12,
                                  decoration: const InputDecoration(
                                    labelText: 'Sorununuzu detaylandırın',
                                    hintText: 'Adımlar, ekran, cihaz bilgisi vb.',
                                    border: OutlineInputBorder(),
                                  ),
                                  validator: (v) => (v == null || v.trim().length < 10) ? 'Daha fazla detay ekleyin' : null,
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: _uploading ? null : _chooseImageSource,
                                        icon: const Icon(Icons.attachment),
                                        label: Text(_attachmentUrl == null ? 'Fotoğraf Ekle' : 'Fotoğrafı Değiştir'),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    if (_uploading) const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
                                  ],
                                ),
                                if (_attachmentUrl != null) ...[
                                  const SizedBox(height: 8),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Stack(
                                      children: [
                                        AspectRatio(
                                          aspectRatio: 16 / 9,
                                          child: Image.network(_attachmentUrl!, fit: BoxFit.cover),
                                        ),
                                        Positioned(
                                          top: 8,
                                          right: 8,
                                          child: Material(
                                            color: Colors.black.withValues(alpha: 0.4),
                                            shape: const CircleBorder(),
                                            child: IconButton(
                                              icon: const Icon(Icons.close, color: Colors.white, size: 18),
                                              onPressed: () => setState(() => _attachmentUrl = null),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 16),
                                AnimatedBuilder(
                                  animation: _ctaPulseController,
                                  builder: (context, child) {
                                    final v = _ctaPulseController.value;
                                    final scale = 1.0 + 0.02 * math.sin(v * 2 * math.pi);
                                    return Transform.scale(
                                      scale: scale,
                                      child: child,
                                    );
                                  },
                                  child: SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      icon: const Icon(Icons.send),
                                      label: Text(_submitting ? 'Gönderiliyor...' : 'Gönder'),
                                      onPressed: _submitting ? null : () => _submit(isPremium: isPremium),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.amber,
                                        foregroundColor: Colors.black,
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        elevation: 10,
                                        shadowColor: Colors.amber.withValues(alpha: 0.4),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            ],
          ),
        );
      },
    );
  }
}
