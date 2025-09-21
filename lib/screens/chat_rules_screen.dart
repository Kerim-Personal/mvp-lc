import 'package:flutter/material.dart';

class ChatRulesScreen extends StatelessWidget {
  const ChatRulesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fgColor = isDark ? Colors.teal.shade200 : Colors.teal.shade800;

    final rules = <String>[
      'Be respectful; insults, hate speech, and any form of bullying are prohibited.',
      'Discussing sensitive topics like politics and religion is prohibited; our goal is language learning.',
      'Spam, flooding, troll content, and persistent off-topic sharing are prohibited.',
      'Do not share your personal information; respect others\' privacy and security.',
      'Sharing copyrighted content is prohibited.',
      'Content that encourages or praises illegal activities is prohibited.',
      'Inappropriate/18+ content, obscene language, and violent posts are strictly prohibited.',
      'Focus on language learning; keep off-topic conversations and personal arguments to a minimum.',
      'English should be the primary language in the app; you may use your native language only limitedly for support when something is unclear. Abuse is prohibited.',
      'Communicate clearly; avoid using ALL CAPS, excessive emojis, and slang.',
      'Advertisements, referral/affiliate codes, sales posts, or personal profit-oriented shares are prohibited.',
      'Revealing others\' personal information (doxxing), threats, or harassment are strictly prohibited.',
      'Ensure that the links you share are reliable and relevant to the topic; avoid suspicious links.',
      'Using multiple accounts or impersonating another user (identity fraud) is prohibited.',
      'Be open to constructive criticism; error corrections should be made politely and not taken personally.',
      'Unauthorized users acting like moderators or admins is prohibited.',
      'Comply with moderators\' warnings and decisions; do not discuss moderation decisions publicly.',
      'Report when you see a rule violation; leave it to moderation without engaging in arguments with the user.'
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat Rules'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: fgColor,
      ),
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [Colors.black, Colors.grey.shade900]
                : [Colors.teal.shade50, Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              elevation: 2,
              color: isDark ? Colors.grey.shade900 : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: rules.length + 1,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.rule, color: fgColor),
                            const SizedBox(width: 8),
                            Text(
                              'Community Guidelines',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: fgColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Please follow the rules below to keep group chat safe and beneficial.',
                          style: TextStyle(
                            color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    );
                  }

                  final rule = rules[index - 1];
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 6.0),
                        child: Icon(Icons.check_circle_outline, size: 20, color: Colors.teal),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          rule,
                          style: TextStyle(
                            fontSize: 15,
                            height: 1.4,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
