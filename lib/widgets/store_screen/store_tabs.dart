import 'package:flutter/material.dart';

class StorePremiumUpsellTab extends StatefulWidget {
  final Widget child;
  const StorePremiumUpsellTab({super.key, required this.child});
  @override
  State<StorePremiumUpsellTab> createState() => _StorePremiumUpsellTabState();
}

class _StorePremiumUpsellTabState extends State<StorePremiumUpsellTab> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  @override
  Widget build(BuildContext context) { super.build(context); return widget.child; }
}

class StorePremiumActiveTab extends StatefulWidget {
  final Widget child;
  const StorePremiumActiveTab({super.key, required this.child});
  @override
  State<StorePremiumActiveTab> createState() => _StorePremiumActiveTabState();
}

class _StorePremiumActiveTabState extends State<StorePremiumActiveTab> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  @override
  Widget build(BuildContext context) { super.build(context); return widget.child; }
}
