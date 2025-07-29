// lib/widgets/community_screen/group_chat_card.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lingua_chat/screens/community_screen.dart';
import 'package:lingua_chat/screens/group_chat_screen.dart';

class GroupChatCard extends StatefulWidget {
  final GroupChatRoom room;
  const GroupChatCard({super.key, required this.room});

  @override
  State<GroupChatCard> createState() => _GroupChatCardState();
}

class _GroupChatCardState extends State<GroupChatCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _animationController.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _animationController.reverse();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GroupChatScreen(
          roomName: widget.room.name,
          roomIcon: widget.room.icon,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: () => _animationController.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              colors: [widget.room.color1, widget.room.color2],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.room.color2.withAlpha(128),
                blurRadius: 15,
                spreadRadius: -5,
                offset: const Offset(0, 10),
              )
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  color: Colors.white.withAlpha(26),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 12),
                    // *** KALICI ÇÖZÜM: Expanded ve Spacer yerine daha basit bir yapı ***
                    Text(
                      widget.room.description,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withAlpha(230),
                        fontSize: 15,
                        height: 1.4,
                      ),
                    ),
                    const Expanded(child: SizedBox()), // Kalan boşluğu doldurur
                    _buildFooter(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(51),
            shape: BoxShape.circle,
          ),
          child: Icon(widget.room.icon, color: Colors.white, size: 28),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            widget.room.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              shadows: [Shadow(color: Colors.black26, blurRadius: 4)],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.redAccent,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.redAccent.withAlpha(179),
                blurRadius: 8,
              )
            ],
          ),
          child: const Text(
            'CANLI',
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    final avatars = [
      'https://api.dicebear.com/8.x/micah/svg?seed=Leo',
      'https://api.dicebear.com/8.x/micah/svg?seed=Felix',
      'https://api.dicebear.com/8.x/micah/svg?seed=Milo',
    ];

    return Row(
      children: [
        SizedBox(
          width: 70,
          height: 30,
          child: Stack(
            children: List.generate(
              avatars.length,
                  (index) => Positioned(
                left: (index * 20).toDouble(),
                child: CircleAvatar(
                  radius: 15,
                  backgroundColor: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(1.5),
                    child: ClipOval(
                      child: SvgPicture.network(
                        avatars[index],
                        width: 28,
                        height: 28,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: Text(
            '${widget.room.members} üye burada',
            style: TextStyle(color: Colors.white.withAlpha(204)),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const Icon(Icons.arrow_forward, color: Colors.white, size: 20),
      ],
    );
  }
}