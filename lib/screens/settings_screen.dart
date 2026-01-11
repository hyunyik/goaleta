import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:goaleta/providers/goal_provider.dart';
import 'package:goaleta/services/notification_service.dart';
import 'package:goaleta/services/onboarding_service.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import 'dart:io';

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
          _buildBackupTile(context, ref),
          _buildRestoreTile(context, ref),
          _buildResetTile(context, ref),
          const Divider(height: 1),
          
          const SizedBox(height: 16),
          
          // Help section
          _buildSectionHeader(context, '도움말'),
          _buildRestartTourTile(context, ref),
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
          final snackBar = ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('알림 시간이 ${picked.format(context)}로 설정되었습니다'),
              duration: const Duration(seconds: 4),
              behavior: SnackBarBehavior.floating,
              action: SnackBarAction(
                label: '테스트',
                onPressed: () async {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  await NotificationService().showTestNotification();
                },
              ),
            ),
          );
          
          // Force auto-dismiss after duration
          Future.delayed(const Duration(seconds: 4), () {
            snackBar.close();
          });
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

  Widget _buildBackupTile(BuildContext context, WidgetRef ref) {
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

  Widget _buildRestoreTile(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: Icon(
        Icons.restore_outlined,
        color: Theme.of(context).colorScheme.primary,
      ),
      title: const Text('복원'),
      subtitle: const Text('백업 파일에서 데이터 복원'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        _showRestoreDialog(context, ref);
      },
    );
  }

  Widget _buildResetTile(BuildContext context, WidgetRef ref) {
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
        _showResetDialog(context, ref);
      },
    );
  }

  Widget _buildRestartTourTile(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: Icon(
        Icons.help_outline,
        color: Theme.of(context).colorScheme.primary,
      ),
      title: const Text('홈 화면 가이드 다시 보기'),
      subtitle: const Text('버튼 설명을 다시 확인하세요'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () async {
        await OnboardingService.resetHomeTour();
        if (context.mounted) {
          Navigator.pop(context, true); // Return true to indicate tour should restart
        }
      },
    );
  }

  void _showBackupDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('백업'),
        content: const Text('모든 목표와 기록을 파일로 백업하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              await _performBackup(context);
            },
            child: const Text('백업'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _performBackup(BuildContext context) async {
    try {
      // Export data first
      final data = await LocalStorage.exportAllData();
      final jsonString = jsonEncode(data);
      
      // Generate filename with timestamp
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.')[0];
      final fileName = 'goaleta_backup_$timestamp.json';
      
      // Let user choose directory
      final selectedDirectory = await FilePicker.platform.getDirectoryPath(
        dialogTitle: '백업 파일을 저장할 폴더 선택',
      );
      
      if (selectedDirectory == null) {
        // User cancelled
        return;
      }
      
      // Show loading indicator
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 16),
                Text('백업 중...'),
              ],
            ),
            duration: Duration(seconds: 30),
          ),
        );
      }
      
      // Create full file path
      final filePath = '$selectedDirectory/$fileName';
      
      // Write file to chosen location as bytes
      final file = File(filePath);
      await file.writeAsBytes(utf8.encode(jsonString));
      
      // Dismiss loading indicator
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        
        // Show success message with file path
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('백업 완료!\n파일명: $fileName\n저장 위치: $selectedDirectory'),
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: '확인',
              onPressed: () {},
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('백업 실패: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _showRestoreDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('복원'),
        content: const Text('백업 파일을 선택하여 데이터를 복원하시겠습니까?\n\n⚠️ 현재 데이터는 모두 삭제됩니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              await _performRestore(context, ref);
            },
            child: const Text('복원'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _performRestore(BuildContext context, WidgetRef ref) async {
    try {
      // Pick file
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      
      if (result == null || result.files.isEmpty) {
        return; // User canceled
      }
      
      final filePath = result.files.single.path;
      if (filePath == null) {
        throw Exception('파일 경로를 가져올 수 없습니다');
      }
      
      // Show loading indicator
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 16),
                Text('복원 중...'),
              ],
            ),
            duration: Duration(seconds: 30),
          ),
        );
      }
      
      // Read and parse file
      final file = File(filePath);
      final jsonString = await file.readAsString();
      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      
      // Validate data
      if (!data.containsKey('goals') || !data.containsKey('logs')) {
        throw Exception('올바르지 않은 백업 파일 형식입니다');
      }
      
      // Import data
      await LocalStorage.importAllData(data);
      
      // Reload goals provider
      ref.invalidate(goalsProvider);
      
      // Dismiss loading indicator
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('복원 완료! 앱을 다시 시작해주세요.'),
            duration: Duration(seconds: 3),
            backgroundColor: Colors.green,
          ),
        );
        
        // Reload the app after a delay
        await Future.delayed(const Duration(seconds: 2));
        if (context.mounted) {
          // Navigate to home and clear all routes
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('복원 실패: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _showResetDialog(BuildContext context, WidgetRef ref) {
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
            onPressed: () async {
              Navigator.pop(context);
              await _performReset(context, ref);
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
  
  Future<void> _performReset(BuildContext context, WidgetRef ref) async {
    try {
      // Show loading indicator
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 16),
                Text('초기화 중...'),
              ],
            ),
            duration: Duration(seconds: 30),
          ),
        );
      }
      
      // Reset all data
      await LocalStorage.resetAllData();
      
      // Reload goals provider
      ref.invalidate(goalsProvider);
      
      // Dismiss loading indicator
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('초기화 완료! 앱을 다시 시작해주세요.'),
            duration: Duration(seconds: 3),
            backgroundColor: Colors.orange,
          ),
        );
        
        // Navigate to home and clear all routes after a delay
        await Future.delayed(const Duration(seconds: 2));
        if (context.mounted) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('초기화 실패: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}

