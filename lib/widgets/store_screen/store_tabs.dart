import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'diamond_pack_tile.dart';
import '../../services/purchase_service.dart';

/// Diamonds tab with keepAlive to prevent rebuild jank.
class StoreDiamondsTab extends StatefulWidget {
  final Set<String> purchasing;
  final Future<void> Function(String) onBuy;
  final Map<String, String> priceMap; // productId -> price
  const StoreDiamondsTab({super.key, required this.purchasing, required this.onBuy, required this.priceMap});

  @override
  State<StoreDiamondsTab> createState() => _StoreDiamondsTabState();
}

class _StoreDiamondsTabState extends State<StoreDiamondsTab> with AutomaticKeepAliveClientMixin {
  final _scrollController = ScrollController();
  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final packs = PurchaseService.diamondProductIds;
    return ScrollConfiguration(
      behavior: const _NoGlowBehavior(),
      child: ListView.separated(
        key: const PageStorageKey('diamonds_list'),
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(18, 20, 18, 32),
        itemBuilder: (c, i) {
          final id = packs[i];
          final amount = PurchaseService.diamondAmountFor(id) ?? 0;
          final price = widget.priceMap[id] ?? '...';
          String? badge; Color? badgeColor;
          if (id == 'diamonds_large') { badge = 'EN İYİ DEĞER'; badgeColor = Colors.greenAccent; }
          else if (id == 'diamonds_medium') { badge = 'POPÜLER'; badgeColor = Colors.amber; }
          return DiamondPackTile(
            key: ValueKey(id),
            productId: id,
            title: '$amount Elmas',
            price: price,
            badge: badge,
            badgeColor: badgeColor,
            loading: widget.purchasing.contains(id),
            onTap: widget.priceMap[id] == null ? null : () => widget.onBuy(id),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(height: 14),
        itemCount: packs.length,
      ),
    );
  }
}

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

/// Simple shimmer placeholders for potential future loading states
class DiamondSkeletonList extends StatelessWidget {
  const DiamondSkeletonList({super.key});
  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 32),
      itemBuilder: (_, i) => Shimmer.fromColors(
        baseColor: Colors.white.withOpacity(0.12),
        highlightColor: Colors.white.withOpacity(0.28),
        child: Container(
          height: 74,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.white,
          ),
        ),
      ),
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemCount: 3,
    );
  }
}

class _NoGlowBehavior extends ScrollBehavior {
  const _NoGlowBehavior();
  @override
  Widget buildViewportChrome(BuildContext context, Widget child, AxisDirection axisDirection) => child;
}
