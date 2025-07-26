import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ProfileSliverAppBar extends StatelessWidget {
  final String displayName;
  final String email;
  final String? avatarUrl;

  const ProfileSliverAppBar({
    super.key,
    required this.displayName,
    required this.email,
    this.avatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 250.0,
      floating: false,
      pinned: true,
      backgroundColor: Colors.teal,
      elevation: 0,
      flexibleSpace: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          var top = constraints.biggest.height;
          return FlexibleSpaceBar(
            centerTitle: true,
            title: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: top <= kToolbarHeight + 40 ? 1.0 : 0.0,
              child: Text(
                displayName,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0),
              ),
            ),
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.teal.shade400, Colors.cyan.shade600],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: const Color.fromARGB(230, 255, 255, 255),
                    child: avatarUrl != null
                        ? ClipOval(
                      child: SvgPicture.network(
                        avatarUrl!,
                        placeholderBuilder: (context) => const CircularProgressIndicator(),
                        width: 90,
                        height: 90,
                      ),
                    )
                        : Text(
                      displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                      style: const TextStyle(
                        fontSize: 48,
                        color: Colors.teal,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    email,
                    style: const TextStyle(
                      color: Color.fromARGB(204, 255, 255, 255),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}