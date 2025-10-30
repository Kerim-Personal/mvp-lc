// lib/screens/writing_analysis_screen.dart
import 'package:flutter/material.dart';
import 'package:vocachat/models/writing_models.dart';
import 'package:flutter/services.dart';

class WritingAnalysisScreen extends StatelessWidget {
  final WritingAnalysis analysis;
  final WritingTask task;
  final String userText;
  final VoidCallback onEditAgain;

  const WritingAnalysisScreen({
    super.key,
    required this.analysis,
    required this.task,
    required this.userText,
    required this.onEditAgain,
  });

  Color _scoreColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }

  String _scoreLabel(int score) {
    if (score >= 90) return 'Mükemmel';
    if (score >= 80) return 'Çok İyi';
    if (score >= 70) return 'İyi';
    if (score >= 60) return 'Orta';
    return 'Geliştirilmeli';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final scoreColor = _scoreColor(analysis.overallScore);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Yazı Analizi'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Tekrar Düzenle',
            onPressed: () {
              Navigator.of(context).pop();
              onEditAgain();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Skor kartı - Kompakt
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    scoreColor.withValues(alpha: 0.7),
                    scoreColor.withValues(alpha: 0.5),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: scoreColor.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Genel Skor:',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${analysis.overallScore}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      height: 1,
                    ),
                  ),
                  const Text(
                    '/100',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _scoreLabel(analysis.overallScore),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Görev bilgisi
            _buildCompactInfoCard(
              context,
              icon: task.emoji,
              title: 'Görev',
              content: task.task,
              color: Colors.blue,
            ),

            const SizedBox(height: 16),

            // Görev tamamlama durumu
            if (analysis.taskCompletion.isNotEmpty)
              _buildCompactInfoCard(
                context,
                icon: '✅',
                title: 'Görev Tamamlama',
                content: analysis.taskCompletion,
                color: Colors.green,
              ),

            if (analysis.taskCompletion.isNotEmpty) const SizedBox(height: 16),

            // Güçlü yönler
            if (analysis.strengths.isNotEmpty)
              _buildListCard(
                context,
                icon: '💪',
                title: 'Güçlü Yönler',
                items: analysis.strengths,
                color: Colors.green,
              ),

            if (analysis.strengths.isNotEmpty) const SizedBox(height: 16),

            // Geliştirilecek alanlar
            if (analysis.improvements.isNotEmpty)
              _buildListCard(
                context,
                icon: '📈',
                title: 'Gelişim Alanları',
                items: analysis.improvements,
                color: Colors.orange,
              ),

            if (analysis.improvements.isNotEmpty) const SizedBox(height: 16),

            // Gramer hataları
            if (analysis.grammarIssues.isNotEmpty) ...[
              _buildGrammarIssuesCard(context),
              const SizedBox(height: 16),
            ],

            // Kelime dağarcığı geri bildirimi
            if (analysis.vocabularyFeedback.isNotEmpty)
              _buildCompactInfoCard(
                context,
                icon: '📚',
                title: 'Kelime Dağarcığı',
                content: analysis.vocabularyFeedback,
                color: Colors.purple,
              ),

            if (analysis.vocabularyFeedback.isNotEmpty) const SizedBox(height: 16),

            // Yapı geri bildirimi
            if (analysis.structureFeedback.isNotEmpty)
              _buildCompactInfoCard(
                context,
                icon: '🏗️',
                title: 'Metin Yapısı',
                content: analysis.structureFeedback,
                color: Colors.indigo,
              ),

            if (analysis.structureFeedback.isNotEmpty) const SizedBox(height: 16),

            // Sonraki adımlar
            if (analysis.nextSteps.isNotEmpty)
              _buildCompactInfoCard(
                context,
                icon: '🎯',
                title: 'Sonraki Adımlar',
                content: analysis.nextSteps,
                color: Colors.teal,
              ),

            const SizedBox(height: 24),

            // Kullanıcının yazdığı metin
            _buildUserTextCard(context),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryChips(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final items = <_ChipInfo>[
      _ChipInfo(
        label: 'Güçlü: ${analysis.strengths.length}',
        color: Colors.green,
        icon: Icons.thumb_up_alt_outlined,
      ),
      _ChipInfo(
        label: 'Gelişim: ${analysis.improvements.length}',
        color: Colors.orange,
        icon: Icons.trending_up,
      ),
      _ChipInfo(
        label: 'Hata: ${analysis.grammarIssues.length}',
        color: Colors.red,
        icon: Icons.rule_folder_outlined,
      ),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map((e) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: e.color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: e.color.withValues(alpha: 0.25)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(e.icon, size: 16, color: e.color),
              const SizedBox(width: 6),
              Text(
                e.label,
                style: TextStyle(
                  color: cs.onSurface,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCompactInfoCard(
    BuildContext context, {
    required String icon,
    required String title,
    required String content,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
            ),
            child: Row(
              children: [
                Text(
                  icon,
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              content,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListCard(
    BuildContext context, {
    required String icon,
    required String title,
    required List<String> items,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
            ),
            child: Row(
              children: [
                Text(
                  icon,
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: items.map((item) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 6),
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          item,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrammarIssuesCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.red.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
            ),
            child: Row(
              children: [
                const Text(
                  '🔍',
                  style: TextStyle(fontSize: 24),
                ),
                const SizedBox(width: 12),
                Text(
                  'Gramer İncelemeleri (${analysis.grammarIssues.length})',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: analysis.grammarIssues.map((issue) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.red.withOpacity(0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              issue.text,
                              style: const TextStyle(
                                fontSize: 14,
                                decoration: TextDecoration.lineThrough,
                                color: Colors.red,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          // Kopyalama butonu (düzeltmeyi kopyala)
                          IconButton(
                            tooltip: 'Düzeltmeyi kopyala',
                            icon: const Icon(Icons.copy_rounded, size: 16, color: Colors.green),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () async {
                              await Clipboard.setData(ClipboardData(text: issue.correction));
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Düzeltme panoya kopyalandı'),
                                    duration: Duration(seconds: 1),
                                  ),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.check_circle_outline, color: Colors.green, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              issue.correction,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.green,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (issue.explanation.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.info_outline, color: Colors.blue, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  issue.explanation,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserTextCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
            ),
            child: Row(
              children: [
                const Text(
                  '📝',
                  style: TextStyle(fontSize: 24),
                ),
                const SizedBox(width: 12),
                Text(
                  'Yazdığınız Metin',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700,
                  ),
                ),
                const Spacer(),
                Text(
                  '${userText.length} karakter',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              userText,
              style: TextStyle(
                fontSize: 14,
                height: 1.6,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChipInfo {
  final String label;
  final Color color;
  final IconData icon;
  const _ChipInfo({required this.label, required this.color, required this.icon});
}
