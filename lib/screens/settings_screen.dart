import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mnemonicorum/services/progress_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _soundEnabled = true;
  bool _hapticFeedbackEnabled = true;
  bool _leftHandMode = false;

  @override
  Widget build(BuildContext context) {
    final progressService = Provider.of<ProgressService>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          SwitchListTile(
            title: const Text('声音'),
            value: _soundEnabled,
            onChanged: (bool value) {
              setState(() {
                _soundEnabled = value;
              });
              // Implement sound toggle logic
            },
          ),
          SwitchListTile(
            title: const Text('触觉反馈'),
            value: _hapticFeedbackEnabled,
            onChanged: (bool value) {
              setState(() {
                _hapticFeedbackEnabled = value;
              });
              // Implement haptic feedback toggle logic
            },
          ),
          SwitchListTile(
            title: const Text('左手模式'),
            value: _leftHandMode,
            onChanged: (bool value) {
              setState(() {
                _leftHandMode = value;
              }); // Implement left-hand mode logic
            },
          ),
          ListTile(
            title: const Text('重置所有进度'),
            trailing: const Icon(Icons.delete_forever, color: Colors.red),
            onTap: () async {
              // Capture ScaffoldMessenger before any async operations
              final scaffoldMessenger = ScaffoldMessenger.of(context);

              // Show confirmation dialog
              final confirm = await showDialog<bool>(
                context: context,
                builder: (BuildContext dialogContext) {
                  return AlertDialog(
                    title: const Text('确认重置？'),
                    content: const Text('这将删除所有学习进度，无法撤消。你确定吗？'),
                    actions: <Widget>[
                      TextButton(
                        child: const Text('取消'),
                        onPressed: () {
                          Navigator.of(dialogContext).pop(false);
                        },
                      ),
                      TextButton(
                        child: const Text('重置'),
                        onPressed: () {
                          Navigator.of(dialogContext).pop(true);
                        },
                      ),
                    ],
                  );
                },
              );

              if (confirm == true) {
                await progressService.clearAllProgress();
                if (mounted) {
                  // Show success message
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(content: Text('所有进度已重置。')),
                  );
                }
              }
            },
          ),
          ListTile(
            title: const Text('报告反馈 / Bug'),
            trailing: const Icon(Icons.bug_report),
            onTap: () {
              // Implement feedback/bug report mechanism (e.g., open email client or web view)
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('报告反馈 / Bug 功能待实现。')),
              );
            },
          ),
        ],
      ),
    );
  }
}
