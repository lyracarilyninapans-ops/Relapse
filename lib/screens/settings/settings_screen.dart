import 'package:flutter/material.dart';
import 'package:relapse_flutter/theme/app_colors.dart';

/// Settings screen with cooldown dropdown and danger zone.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _cooldownMinutes = 30;
  final _cooldownOptions = [15, 30, 45, 60, 90, 120, 180, 240];
  bool _hasUnsavedChanges = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Reminder Cooldown',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              const Text(
                'Set the minimum time between memory reminder triggers to avoid overwhelming the patient.',
              ),
              const SizedBox(height: 16),

              // Dropdown
              InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Cooldown (minutes)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _cooldownMinutes,
                    isExpanded: true,
                    items: _cooldownOptions
                        .map(
                          (val) => DropdownMenuItem(
                            value: val,
                            child: Text('$val minutes'),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _cooldownMinutes = val;
                          _hasUnsavedChanges = true;
                        });
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),

              if (_hasUnsavedChanges)
                const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Text(
                    'You have unsaved changes',
                    style: TextStyle(color: Colors.orangeAccent),
                  ),
                ),

              FilledButton.icon(
                onPressed: () {
                  setState(() => _hasUnsavedChanges = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Settings saved')),
                  );
                },
                icon: const Icon(Icons.save_alt),
                label: const Text('Save Changes'),
              ),

              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 16),

              const Text(
                'Danger Zone',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              const Text(
                'Unpairing will disconnect the patient device. All safe zone monitoring will stop.',
              ),
              const SizedBox(height: 16),

              OutlinedButton.icon(
                onPressed: () {
                  _showUnpairDialog(context);
                },
                icon: const Icon(Icons.link_off, color: Colors.redAccent),
                label: const Text(
                  'Unpair Device',
                  style: TextStyle(color: Colors.redAccent),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.redAccent),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showUnpairDialog(BuildContext context) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirm Unpairing'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Type the patient name to confirm unpairing:'),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'Patient name',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Confirm',
              style: TextStyle(color: AppColors.errorColor),
            ),
          ),
        ],
      ),
    );
  }
}
