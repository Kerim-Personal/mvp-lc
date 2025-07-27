// lib/widgets/community_screen/leaderboard_table.dart

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lingua_chat/screens/community_screen.dart'; // LeaderboardUser modelini import etmek için

class LeaderboardTable extends StatelessWidget {
  // GÜNCELLEME: Sadece kullanıcı listesini alıyor
  final List<LeaderboardUser> users;

  const LeaderboardTable({super.key, required this.users});

  @override
  Widget build(BuildContext context) {
    // Filtreleme butonları ve state yönetimi artık bu widget'ta değil.
    // Bu widget sadece gelen listeyi göstermekle sorumlu.
    return Column(
      children: [
        // TODO: Zaman periyodu filtreleme butonları (ToggleButtons) buraya eklenebilir.
        // Şimdilik sadece genel sıralamayı gösteriyoruz.
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
                rows: users.map((user) {
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
                            Expanded(child: Text(user.name, style: const TextStyle(fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
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