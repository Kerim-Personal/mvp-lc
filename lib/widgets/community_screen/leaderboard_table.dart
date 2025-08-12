// lib/widgets/community_screen/leaderboard_table.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lingua_chat/screens/community_screen.dart'; // LeaderboardUser modelini import etmek için

class LeaderboardTable extends StatefulWidget {
  final List<LeaderboardUser> users;

  const LeaderboardTable({super.key, required this.users});

  @override
  State<LeaderboardTable> createState() => _LeaderboardTableState();
}

class _LeaderboardTableState extends State<LeaderboardTable> with TickerProviderStateMixin {
  // YENİ: Parlama efekti için animasyon denetleyicisi.
  late final AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    // Animasyonu sürekli tekrarla, çünkü listede birden fazla premium olabilir.
    _shimmerController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Timer(const Duration(seconds: 1), () {
          if (mounted) {
            _shimmerController.forward(from: 0.0);
          }
        });
      }
    });
    _shimmerController.forward();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const premiumColor = Color(0xFFE5B53A);
    const premiumIcon = Icons.auto_awesome;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: Container(
              padding: const EdgeInsets.all(8.0),
              width: double.infinity,
              child: DataTable(
                columnSpacing: 20,
                headingRowColor: MaterialStateProperty.all(Colors.teal.withOpacity(0.1)),
                headingTextStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal),
                columns: const [
                  DataColumn(label: Text('Sıra')),
                  DataColumn(label: Text('Kullanıcı')),
                  DataColumn(label: Text('Eşleşme'), numeric: true),
                ],
                rows: widget.users.map((user) {
                  final rankColor = user.rank <= 3 ? Colors.amber.shade700 : Colors.grey.shade700;
                  return DataRow(
                    cells: [
                      DataCell(
                        Text(
                          '#${user.rank}',
                          style: TextStyle(fontWeight: FontWeight.bold, color: rankColor),
                        ),
                      ),
                      DataCell(
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: Colors.grey.shade200,
                              child: ClipOval(
                                child: SvgPicture.network(
                                  user.avatarUrl,
                                  width: 36,
                                  height: 36,
                                  placeholderBuilder: (context) => const CircularProgressIndicator(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              // GÜNCELLEME: Kullanıcı adını animasyonlu widget ile değiştirildi.
                              child: user.isPremium
                                  ? AnimatedBuilder(
                                animation: _shimmerController,
                                builder: (context, child) {
                                  final highlightColor = Colors.white;
                                  final value = _shimmerController.value;
                                  final start = value * 1.5 - 0.5;
                                  final end = value * 1.5;

                                  return ShaderMask(
                                    blendMode: BlendMode.srcIn,
                                    shaderCallback: (bounds) => LinearGradient(
                                      colors: [premiumColor, highlightColor, premiumColor],
                                      stops: [start, (start + end) / 2, end],
                                    ).createShader(
                                      Rect.fromLTWH(0, 0, bounds.width, bounds.height),
                                    ),
                                    child: child,
                                  );
                                },
                                child: Text(
                                  user.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: premiumColor,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              )
                                  : Text(
                                user.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (user.isPremium) ...[
                              const SizedBox(width: 4),
                              const Icon(premiumIcon, color: premiumColor, size: 16),
                            ]
                          ],
                        ),
                      ),
                      DataCell(
                        Container(
                          alignment: Alignment.centerRight,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.people_alt_outlined, color: Colors.blue.shade600, size: 20),
                              const SizedBox(width: 6),
                              Text(
                                user.partnerCount.toString(),
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}