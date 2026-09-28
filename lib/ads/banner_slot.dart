import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'ad_units.dart';

class BannerSlot extends StatefulWidget {
  const BannerSlot({super.key});
  @override
  State<BannerSlot> createState() => _BannerSlotState();
}

class _BannerSlotState extends State<BannerSlot> {
  BannerAd? _ad;
  int _width = 0, _request = 0;
  bool _loaded = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final width = MediaQuery.sizeOf(context).width.clamp(0, 480).floor();
    if (width != _width) {
      _width = width;
      _load(width);
    }
  }

  Future<void> _load(int width) async {
    final request = ++_request;
    _ad?.dispose();
    _ad = null;
    _loaded = false;
    final size = await AdSize.getLargeAnchoredAdaptiveBannerAdSize(width);
    if (!mounted || request != _request || size == null) return;
    final ad = BannerAd(
      size: size,
      adUnitId: AdUnits.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted || request != _request) {
            ad.dispose();
            return;
          }
          setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
        },
      ),
    );
    _ad = ad;
    await ad.load();
  }

  @override
  void dispose() {
    _request++;
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => !_loaded || _ad == null
      ? const SizedBox.shrink()
      : SizedBox(
          height: _ad!.size.height.toDouble(),
          width: _ad!.size.width.toDouble(),
          child: AdWidget(ad: _ad!),
        );
}
