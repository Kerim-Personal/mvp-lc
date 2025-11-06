// lib/screens/user_profile_summary_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:circle_flags/circle_flags.dart';
import 'package:vocachat/screens/leaderboard_screen.dart';

// Dil kodlarını bayrak kodlarına çeviren map
const _flagMap = <String,String>{
  'af':'za','sq':'al','ar':'sa','be':'by','bg':'bg','bn':'bd','ca':'ad','zh':'cn','hr':'hr','cs':'cz','da':'dk','nl':'nl','en':'gb','et':'ee','fi':'fi','fr':'fr','gl':'es','ka':'ge','de':'de','el':'gr','hi':'in','hu':'hu','is':'is','id':'id','ga':'ie','it':'it','ja':'jp','ko':'kr','lv':'lv','lt':'lt','mk':'mk','ms':'my','mt':'mt','no':'no','fa':'ir','pl':'pl','pt':'pt','ro':'ro','ru':'ru','sk':'sk','sl':'si','es':'es','sw':'tz','sv':'se','tl':'ph','ta':'lk','th':'th','tr':'tr','uk':'ua','ur':'pk','vi':'vn','ht':'ht','gu':'in','kn':'in','te':'in','mr':'in'};
const _suppressFlag = {'eo','cy'};
const _indianGroup = {'hi','gu','kn','te','mr'};

class UserProfileSummaryScreen extends StatelessWidget {
  final LeaderboardUser user;
  const UserProfileSummaryScreen({super.key, required this.user});

  Widget _buildNativeLanguageFlag(String languageCode, double size) {
    final code = languageCode.toLowerCase();
    if (!_flagMap.containsKey(code) || _suppressFlag.contains(code)) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Text(
          code.toUpperCase(),
          style: TextStyle(
            fontSize: size * 0.35,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      );
    }
    return CircleFlag(_flagMap[code]!.toLowerCase(), size: size);
  }

  Widget _modernStatCard(BuildContext context, String label, String value, {IconData? icon, Color? iconColor}) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cs.surfaceContainerHighest.withValues(alpha: 0.8),
            cs.surfaceContainer.withValues(alpha: 0.6),
          ],
        ),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                if (icon != null)
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: (iconColor ?? cs.primary).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      icon,
                      size: 20,
                      color: iconColor ?? cs.primary,
                    ),
                  ),
                const SizedBox(height: 4),
                Text(
                  value,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: cs.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _modernStatCardWithFlag(BuildContext context, String label, String languageCode) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cs.surfaceContainerHighest.withValues(alpha: 0.8),
            cs.surfaceContainer.withValues(alpha: 0.6),
          ],
        ),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: cs.tertiary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: _buildNativeLanguageFlag(languageCode, 20),
                ),
                const SizedBox(height: 4),
                Text(
                  languageCode.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: cs.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _modernStatCardWithMultipleFlags(BuildContext context, String label, List<String> languageCodes) {
    final cs = Theme.of(context).colorScheme;

    // Boş ise placeholder göster
    if (languageCodes.isEmpty) {
      languageCodes = ['-'];
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cs.surfaceContainerHighest.withValues(alpha: 0.8),
            cs.surfaceContainer.withValues(alpha: 0.6),
          ],
        ),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: cs.tertiary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (int i = 0; i < languageCodes.length && i < 3; i++) ...[
                        if (i > 0) const SizedBox(width: 4),
                        _buildNativeLanguageFlag(languageCodes[i], 20),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  languageCodes.map((code) => code.toUpperCase()).join(' • '),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: cs.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Kamuya açık profili oku
    final docRef = FirebaseFirestore.instance.collection('publicUsers').doc(user.userId);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'User Profile',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: cs.onSurface,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              cs.primaryContainer.withValues(alpha: 0.3),
              cs.primaryContainer.withValues(alpha: 0.1),
              cs.surface,
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            future: docRef.get(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        strokeWidth: 3,
                        color: cs.primary,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Loading profile...',
                        style: TextStyle(
                          color: cs.onSurfaceVariant,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                );
              }
              if (snap.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 48,
                        color: cs.error,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Profile could not be loaded',
                        style: TextStyle(
                          color: cs.error,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              }

              final data = snap.data?.data() ?? {};
              final displayName = (data['displayName'] as String?) ?? user.name;
              final avatarUrl = (data['avatarUrl'] as String?) ?? user.avatarUrl;
              final isPremium = (data['isPremium'] as bool?) ?? user.isPremium;
              final role = user.role; // publicUsers role içermez, parametreyi kullan
              final streak = (data['streak'] as int?) ?? user.streak;
              final highestStreak = (data['highestStreak'] as int?) ?? streak;
              final nativeLanguage = (data['nativeLanguage'] as String?) ?? '-';
              final learningLanguage = (data['learningLanguage'] as String?) ?? '-';
              // Son 3 öğrenilen dili al
              List<String> recentLearningLanguages = [];
              if (data['recentLearningLanguages'] != null) {
                recentLearningLanguages = List<String>.from(data['recentLearningLanguages']);
              } else if (learningLanguage != '-') {
                recentLearningLanguages = [learningLanguage];
              }

              // Eğer learning languages boşsa, varsayılan olarak İngilizce göster
              if (recentLearningLanguages.isEmpty) {
                recentLearningLanguages = ['en'];
              }
              // Level artık public gösterimde kullanılmıyor
              // final levelRaw = data['level'];
              // final level = levelRaw == null ? '-' : levelRaw.toString();
              // Yeni: publicUsers dokümanından grammarHighestLevel oku
              String grammarHighestLevel = (data['grammarHighestLevel'] as String?) ?? '-';

              // Eğer level boşsa, varsayılan olarak Beginner göster
              if (grammarHighestLevel == '-') {
                grammarHighestLevel = 'Beginner';
              }
              final createdAtTs = data['createdAt'];
              DateTime? createdAt;
              if (createdAtTs is Timestamp) createdAt = createdAtTs.toDate();
              final createdAtStr = createdAt != null ? DateFormat('MMM d, y', 'en').format(createdAt) : '-';

              // Avatar formatı SVG olabilir (Dicebear); NetworkImage bunları gösteremez
              final bool isSvgAvatar = avatarUrl != null && (avatarUrl!.toLowerCase().endsWith('.svg') || avatarUrl!.contains('dicebear.com') || avatarUrl!.contains('image/svg'));

              List<Widget> badges = [];
              // Role badge'i
              if (role == 'admin') {
                badges.add(_compactIconBadge(
                  context,
                  Icons.admin_panel_settings,
                  '',
                  Colors.red
                ));
              } else if (role == 'moderator') {
                badges.add(_compactIconBadge(
                  context,
                  Icons.shield,
                  '',
                  Colors.orange
                ));
              }

              // Premium badge'i
              if (isPremium) {
                badges.add(_compactIconBadge(
                  context,
                  Icons.workspace_premium,
                  '',
                  const Color(0xFFE5B53A)
                ));
              }

              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Hero Profile Section - Kompakt
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            cs.primaryContainer.withValues(alpha: 0.8),
                            cs.secondaryContainer.withValues(alpha: 0.6),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: cs.shadow.withValues(alpha: 0.15),
                            blurRadius: 15,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: cs.surfaceContainerHighest,
                            child: avatarUrl == null
                                ? Icon(Icons.person, color: cs.onSurfaceVariant, size: 24)
                                : ClipOval(
                                    child: isSvgAvatar
                                        ? SvgPicture.network(
                                            avatarUrl!,
                                            width: 48,
                                            height: 48,
                                            placeholderBuilder: (_) => const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(strokeWidth: 2),
                                            ),
                                          )
                                        : Image.network(
                                            avatarUrl!,
                                            width: 48,
                                            height: 48,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) => Icon(Icons.person, color: cs.onSurfaceVariant, size: 24),
                                          ),
                                  ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  displayName,
                                  style: TextStyle(
                                    color: cs.onSurface,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: badges,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Sıralama badge'i - büyük ve gösterişli
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  cs.primary.withValues(alpha: 0.2),
                                  cs.primary.withValues(alpha: 0.15),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: cs.primary.withValues(alpha: 0.4),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: cs.primary.withValues(alpha: 0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.emoji_events,
                                  size: 24,
                                  color: cs.primary,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '#${user.rank}',
                                  style: TextStyle(
                                    color: cs.primary,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Basic stats
                    _modernStatCard(
                      context,
                      'Level',
                      grammarHighestLevel,
                      icon: Icons.translate,
                      iconColor: cs.tertiary,
                    ),

                    _modernStatCardWithFlag(
                      context,
                      'Native Language',
                      nativeLanguage,
                    ),

                    _modernStatCardWithMultipleFlags(
                      context,
                      'Learning Languages',
                      recentLearningLanguages,
                    ),

                    // Streak stats - yan yana
                    Row(
                      children: [
                        Expanded(
                          child: _modernStatCard(
                            context,
                            'Streak',
                            streak.toString(),
                            icon: Icons.local_fire_department,
                            iconColor: Colors.deepOrange,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _modernStatCard(
                            context,
                            'Highest Streak',
                            highestStreak.toString(),
                            icon: Icons.whatshot,
                            iconColor: Colors.amber,
                          ),
                        ),
                      ],
                    ),

                    _modernStatCard(
                      context,
                      'Member since',
                      createdAtStr,
                      icon: Icons.calendar_today,
                      iconColor: cs.secondary,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _compactIconBadge(BuildContext context, IconData icon, String text, Color color) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          if (text.isNotEmpty) ...[
            const SizedBox(width: 6),
            Text(
              text,
              style: TextStyle(
                color: cs.onSurface,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ]
        ],
      ),
    );
  }
}
