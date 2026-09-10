import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/spotlight.dart';
import '../provider/spotlights_provider.dart';
import 'admin_spotlight_editor_screen.dart';
import 'admin_spotlight_overview_screen.dart';
import 'admin_spotlight_past_screen.dart';

enum _SpotlightView { overview, past, editor }

class AdminSpotlightScreen extends StatefulWidget {
  const AdminSpotlightScreen({super.key});

  @override
  State<AdminSpotlightScreen> createState() => _AdminSpotlightScreenState();
}

class _AdminSpotlightScreenState extends State<AdminSpotlightScreen> {
  _SpotlightView _view = _SpotlightView.overview;
  Spotlight? _editTarget; // null while creating

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<SpotlightsProvider>().loadInitial();
      }
    });
  }

  void _openEditor({Spotlight? target}) {
    setState(() {
      _editTarget = target;
      _view = _SpotlightView.editor;
    });
  }

  void _go(_SpotlightView view) => setState(() => _view = view);

  @override
  Widget build(BuildContext context) {
    switch (_view) {
      case _SpotlightView.overview:
        return AdminSpotlightOverviewScreen(
          onOpenPast: () => _go(_SpotlightView.past),
          onNew: () => _openEditor(),
          onEditLive: (Spotlight s) => _openEditor(target: s),
        );
      case _SpotlightView.past:
        return AdminSpotlightPastScreen(
          onNew: () => _openEditor(),
          onEdit: (Spotlight s) => _openEditor(target: s),
        );
      case _SpotlightView.editor:
        return AdminSpotlightEditorScreen(
          target: _editTarget,
          onDone: () => _go(_SpotlightView.past),
          onCancel: () => _go(_SpotlightView.overview),
        );
    }
  }
}
