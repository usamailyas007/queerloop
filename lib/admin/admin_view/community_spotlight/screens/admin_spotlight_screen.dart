import 'package:flutter/material.dart';

import '../../../../core/theme/app_images.dart';
import 'admin_spotlight_overview_screen.dart';
import 'admin_spotlight_past_screen.dart';

class SpotlightPick {
  SpotlightPick({
    required this.headline,
    required this.description,
    required this.coverImage,
    required this.weekLabel,
    required this.views,
    required this.isLive,
    this.taps,
  });

  final String headline;
  final String description;
  final ImageProvider coverImage;
  final String weekLabel;
  final String views;
  final String? taps;
  bool isLive;
}

enum _SpotlightView { overview, past }

class AdminSpotlightScreen extends StatefulWidget {
  const AdminSpotlightScreen({super.key});

  @override
  State<AdminSpotlightScreen> createState() => _AdminSpotlightScreenState();
}

class _AdminSpotlightScreenState extends State<AdminSpotlightScreen> {
  _SpotlightView _view = _SpotlightView.overview;

  final List<SpotlightPick> _picks = <SpotlightPick>[
    SpotlightPick(
      headline: 'Drag & Nightlife',
      description:
          "Admin-curated every week. Chosen this week for its Pride showcase thread and genuinely welcoming new-performer nights.",
      coverImage: const AssetImage(AppImages.searchResult1),
      weekLabel: 'Wk of 3 Aug',
      views: '12K',
      isLive: true,
    ),
    SpotlightPick(
      headline: 'Book club & Queer lit',
      description: 'A weekly circle reading queer authors, new and classic.',
      coverImage: const AssetImage(AppImages.searchResult2),
      weekLabel: 'Wk of 27 Jul',
      views: '41K',
      taps: '3.2K',
      isLive: false,
    ),
    SpotlightPick(
      headline: 'New in Town: local meetups',
      description: 'Fresh-to-the-city members find their people faster.',
      coverImage: const AssetImage(AppImages.searchResult3),
      weekLabel: 'Wk of 20 Jul',
      views: '33K',
      taps: '2.6K',
      isLive: false,
    ),
    SpotlightPick(
      headline: 'Trans healthcare Q&A thread',
      description: 'Community members answering each other on care access.',
      coverImage: const AssetImage(AppImages.searchResult4),
      weekLabel: 'Wk of 13 Jul',
      views: '58K',
      taps: '5.1K',
      isLive: false,
    ),
    SpotlightPick(
      headline: 'Pride month kickoff',
      description: 'Celebrating the start of Pride across every community.',
      coverImage: const AssetImage(AppImages.searchResult5),
      weekLabel: 'Wk of 1 Jun',
      views: '81K',
      taps: '9.4K',
      isLive: false,
    ),
    SpotlightPick(
      headline: 'Chosen family stories',
      description: 'Members share who shows up for them, and how.',
      coverImage: const AssetImage(AppImages.searchResult6),
      weekLabel: 'Wk of 25 May',
      views: '46K',
      taps: '4.0K',
      isLive: false,
    ),
  ];

  void _openPast() {
    setState(() => _view = _SpotlightView.past);
  }

  void _openOverview() {
    setState(() => _view = _SpotlightView.overview);
  }

  void _publishSpotlight({
    required String headline,
    required String description,
    ImageProvider? coverImage,
  }) {
    final String trimmedHeadline = headline.trim();
    if (trimmedHeadline.isEmpty) {
      return;
    }
    setState(() {
      final ImageProvider image = coverImage ?? _picks.first.coverImage;
      for (final SpotlightPick p in _picks) {
        p.isLive = false;
      }
      _picks.insert(
        0,
        SpotlightPick(
          headline: trimmedHeadline,
          description: description.trim(),
          coverImage: image,
          weekLabel: 'This week',
          views: '0',
          isLive: true,
        ),
      );
      _view = _SpotlightView.past;
    });
  }

  @override
  Widget build(BuildContext context) {
    switch (_view) {
      case _SpotlightView.overview:
        return AdminSpotlightOverviewScreen(
          picks: _picks,
          onOpenPast: _openPast,
          onPublish: _publishSpotlight,
        );
      case _SpotlightView.past:
        return AdminSpotlightPastScreen(
          picks: _picks,
          onOpenOverview: _openOverview,
        );
    }
  }
}
