import 'package:flutter/material.dart';

class TopicOfTheWeekScreen extends StatelessWidget {
  const TopicOfTheWeekScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Haftanın Konusu'),
        backgroundColor: Colors.blue.shade400,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lightbulb_outline, size: 80, color: Colors.blue),
              SizedBox(height: 20),
              Text(
                'Bu hafta "Seyahat" hakkında konuşun!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text(
                'Partnerinize en son gittiği yeri, gitmek istediği bir sonraki rotayı veya unutamadığı bir seyahat anısını sorun.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
            ],
          ),
        ),
      ),
    );
  }
}