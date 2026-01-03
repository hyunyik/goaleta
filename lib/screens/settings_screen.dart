import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:goaleta/providers/goal_provider.dart';
import 'package:goaleta/services/notification_service.dart';

// Provider for alarm time (loaded from storage)
final alarmTimeProvider = StateProvider<TimeOfDay?>((ref) {
  final savedTime = LocalStorage.getAlarmTime();
  if (savedTime != null) {
    return TimeOfDay(hour: savedTime.$1, minute: savedTime.$2);
  }
  return null;
});

// Provider for alarm enabled (loaded from storage)
final alarmEnabledProvider = StateProvider<bool>((ref) {
  return LocalStorage.getAlarmEnabled();
});

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alarmEnabled = ref.watch(alarmEnabledProvider);
    final alarmTime = ref.watch(alarmTimeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('설정'),
        elevation: 0,
      ),
      body: ListView(
        children: [
          // Alarm section
          _buildSectionHeader(context, '알림'),
          _buildAlarmTile(context, ref, alarmEnabled, alarmTime),
          const Divider(height: 1),
          
          const SizedBox(height: 16),
          
          // Data management section
          _buildSectionHeader(context, '데이터 관리'),
          _buildBackupTile(context),
          _buildRestoreTile(context),
          _buildResetTile(context),
          const Divider(height: 1),
          
          const SizedBox(height: 24),
          
          // App info
          Center(
            child: Text(
              'Goaleta v1.0.0',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Widget _buildAlarmTile(
    BuildContext context,
    WidgetRef ref,
    bool alarmEnabled,
    TimeOfDay? alarmTime,
  ) {
    return ListTile(
      leading: Icon(
        alarmEnabled ? Icons.notifications_active : Icons.notifications_off,
        color: Theme.of(context).colorScheme.primary,
      ),
      title: const Text('일일 알림'),
      subtitle: Text(
        alarmTime != null
            ? '${alarmTime.format(context)}${alarmEnabled ? " (켜짐)" : " (꺼짐)"}'
            : '알림 시간을 설정하세요',
      ),
      trailing: Switch(
        value: alarmEnabled,
        onChanged: alarmTime != null
            ? (value) async {
                ref.read(alarmEnabledProvider.notifier).state = value;
                await LocalStorage.saveAlarmEnabled(value);
                
                if (value) {
                  // Enable notifications
                  try {
                    await NotificationService().scheduleDailyNotification(
                      time: alarmTime,
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('알림이 켜졌습니다'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('알림 설정 실패: $e'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                    // Revert the state
                    ref.read(alarmEnabledProvider.notifier).state = false;
                    await LocalStorage.saveAlarmEnabled(false);
                  }
                } else {
                  // Disable notifications
                  await NotificationService().cancelAllNotifications();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('알림이 꺼졌습니다'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  }
                }
              }
            : null,
      ),
      onTap: () => _showAlarmTimePickerDialog(context, ref, alarmTime),
    );
  }

  Future<void> _showAlarmTimePickerDialog(
    BuildContext context,
    WidgetRef ref,
    TimeOfDay? currentTime,
  ) async {
    final initialTime = currentTime ?? const TimeOfDay(hour: 21, minute: 0);
    
    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
          child: child!,
        );
      },
    );

    if (picked != null) {
      // Save the time
      ref.read(alarmTimeProvider.notifier).state = picked;
      await LocalStorage.saveAlarmTime(picked.hour, picked.minute);
      
      // Enable alarm if it wasn't already
      final wasEnabled = ref.read(alarmEnabledProvider);
      if (!wasEnabled) {
        ref.read(alarmEnabledProvider.notifier).state = true;
        await LocalStorage.saveAlarmEnabled(true);
      }
      
      // Schedule the notification
      try {
        await NotificationService().scheduleDailyNotification(
          time: picked,
        );
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('알림 시간이 ${picked.format(context)}로 설정되었습니다'),
              duration: const Duration(seconds: 2),
              action: SnackBarAction(
                label: '테스트',
                onPressed: () async {
                  await NotificationService().showTestNotification();
                },
              ),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('알림 설정 실패: $e'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    }
  }

  Widget _buildBackupTile(BuildContext context) {
    return ListTile(
      leading: Icon(
        Icons.backup_outlined,
        color: Theme.of(context).colorScheme.primary,
      ),
      title: const Text('백업'),
      subtitle: const Text('데이터를 파일로 저장'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        _showBackupDialog(context);
      },
    );
  }

  Widget _buildRestoreTile(BuildContext context) {
    return ListTile(
      leading: Icon(
        Icons.restore_outlined,
        color: Theme.of(context).colorScheme.primary,
      ),
      title: const Text('복원'),
      subtitle: const Text('백업 파일에서 데이터 복원'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        _showRestoreDialog(context);
      },
    );
  }

  Widget _buildResetTile(BuildContext context) {
    return ListTile(
      leading: const Icon(
        Icons.delete_forever_outlined,
        color: Colors.red,
      ),
      title: const Text(
        '초기화',
        style: TextStyle(color: Colors.red),
      ),
      subtitle: const Text('모든 데이터 삭제'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        _showResetDialog(context);
      },
    );
  }

  void _showBackupDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('백업'),
        content: const Text('백업 기능은 준비 중입니다.\n향후 업데이트에서 제공될 예정입니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  void _showRestoreDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('복원'),
        content: const Text('복원 기능은 준비 중입니다.\n향후 업데이트에서 제공될 예정입니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  void _showResetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ 초기화 경고'),
        content: const Text(
          '모든 목표와 기록이 영구적으로 삭제됩니다.\n이 작업은 되돌릴 수 없습니다.\n\n정말로 초기화하시겠습니까?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              // TODO: Implement reset functionality
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('초기화 기능은 준비 중입니다'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('초기화'),
          ),
        ],
      ),
    );
  }
}

