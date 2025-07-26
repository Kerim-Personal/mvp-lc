import 'package:flutter/material.dart';

class RolePlayingScreen extends StatelessWidget {
  const RolePlayingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rol Yapma Zamanı!'),
        backgroundColor: Colors.red.shade400,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.theater_comedy_outlined, size: 80, color: Colors.red),
              SizedBox(height: 20),
              Text(
                "Senaryo: Bir Restoranda",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text(
                "Rolünüz: Aç bir müşteri.\nPartnerinizin Rolü: Sabırlı bir garson.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
              SizedBox(height: 20),
              Text(
                'Göreviniz: Menüden bir başlangıç, bir ana yemek ve bir içecek sipariş etmek. Partnerinize yemeğin içeriği hakkında bir soru sorun.',
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