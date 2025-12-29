import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:connect_well_nepal/providers/app_provider.dart';
import 'package:connect_well_nepal/screens/auth_screen.dart';
import 'package:connect_well_nepal/utils/colors.dart';

/// SettingsScreen - App settings and preferences
///
/// Features:
/// - Dark mode toggle
/// - Notifications toggle
/// - Language selection
/// - Account settings
/// - Logout option
/// - About section
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<AppProvider>(
        builder: (context, appProvider, child) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Appearance Section
              _buildSectionHeader(context, 'Appearance'),
              _buildSettingsCard(
                context,
                children: [
                  _buildSwitchTile(
                    context,
                    icon: Icons.dark_mode,
                    iconColor: Colors.indigo,
                    title: 'Dark Mode',
                    subtitle: 'Switch between light and dark theme',
                    value: appProvider.isDarkMode,
                    onChanged: (value) {
                      appProvider.toggleTheme();
                    },
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Notifications Section
              _buildSectionHeader(context, 'Notifications'),
              _buildSettingsCard(
                context,
                children: [
                  _buildSwitchTile(
                    context,
                    icon: Icons.notifications_active,
                    iconColor: Colors.orange,
                    title: 'Push Notifications',
                    subtitle: 'Receive appointment reminders',
                    value: appProvider.notificationsEnabled,
                    onChanged: (value) {
                      appProvider.toggleNotifications();
                    },
                  ),
                  const Divider(height: 1),
                  _buildListTile(
                    context,
                    icon: Icons.schedule,
                    iconColor: Colors.teal,
                    title: 'Reminder Time',
                    subtitle: '30 minutes before',
                    onTap: () {
                      _showReminderTimePicker(context);
                    },
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Language & Region
              _buildSectionHeader(context, 'Language & Region'),
              _buildSettingsCard(
                context,
                children: [
                  _buildListTile(
                    context,
                    icon: Icons.language,
                    iconColor: Colors.blue,
                    title: 'Language',
                    subtitle: appProvider.language,
                    onTap: () {
                      _showLanguagePicker(context, appProvider);
                    },
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Privacy & Security
              _buildSectionHeader(context, 'Privacy & Security'),
              _buildSettingsCard(
                context,
                children: [
                  _buildListTile(
                    context,
                    icon: Icons.lock,
                    iconColor: Colors.purple,
                    title: 'Change Password',
                    onTap: () {
                      _showChangePasswordDialog(context);
                    },
                  ),
                  const Divider(height: 1),
                  _buildListTile(
                    context,
                    icon: Icons.privacy_tip,
                    iconColor: Colors.green,
                    title: 'Privacy Policy',
                    onTap: () {
                      _showPrivacyPolicy(context);
                    },
                  ),
                  const Divider(height: 1),
                  _buildListTile(
                    context,
                    icon: Icons.description,
                    iconColor: Colors.amber,
                    title: 'Terms of Service',
                    onTap: () {
                      _showTermsOfService(context);
                    },
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // About Section
              _buildSectionHeader(context, 'About'),
              _buildSettingsCard(
                context,
                children: [
                  _buildListTile(
                    context,
                    icon: Icons.info,
                    iconColor: AppColors.primaryNavyBlue,
                    title: 'About Connect Well Nepal',
                    onTap: () {
                      _showAboutDialog(context);
                    },
                  ),
                  const Divider(height: 1),
                  _buildListTile(
                    context,
                    icon: Icons.star,
                    iconColor: Colors.amber,
                    title: 'Rate Us',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Opening app store...'),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  _buildListTile(
                    context,
                    icon: Icons.help,
                    iconColor: Colors.cyan,
                    title: 'Help & Support',
                    onTap: () {
                      _showHelpSupport(context);
                    },
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Account Actions
              _buildSectionHeader(context, 'Account'),
              _buildSettingsCard(
                context,
                children: [
                  _buildListTile(
                    context,
                    icon: Icons.logout,
                    iconColor: AppColors.secondaryCrimsonRed,
                    title: 'Logout',
                    titleColor: AppColors.secondaryCrimsonRed,
                    onTap: () {
                      _showLogoutConfirmation(context, appProvider);
                    },
                  ),
                  if (appProvider.currentUser?.id != 'guest') ...[
                    const Divider(height: 1),
                    _buildListTile(
                      context,
                      icon: Icons.delete_forever,
                      iconColor: Colors.red,
                      title: 'Delete Account',
                      titleColor: Colors.red,
                      onTap: () {
                        _showDeleteAccountConfirmation(context);
                      },
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 32),

              // Version info
              Center(
                child: Text(
                  'Version 1.0.0',
                  style: TextStyle(
                    color: isDark ? Colors.white54 : AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  '© 2025 Connect Well Nepal',
                  style: TextStyle(
                    color: isDark ? Colors.white38 : AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white70 : AppColors.textSecondary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(BuildContext context,
      {required List<Widget> children}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2A3A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildListTile(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    Color? titleColor,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: titleColor ?? (isDark ? Colors.white : AppColors.textPrimary),
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white54 : AppColors.textSecondary,
              ),
            )
          : null,
      trailing: Icon(
        Icons.chevron_right,
        color: isDark ? Colors.white38 : AppColors.textSecondary,
      ),
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SwitchListTile(
      secondary: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: isDark ? Colors.white : AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: isDark ? Colors.white54 : AppColors.textSecondary,
        ),
      ),
      value: value,
      onChanged: onChanged,
      activeThumbColor: AppColors.secondaryCrimsonRed,
    );
  }

  void _showReminderTimePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Reminder Time',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ...['15 minutes before', '30 minutes before', '1 hour before', '1 day before']
                  .map((time) => ListTile(
                        title: Text(time),
                        onTap: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Reminder set to $time')),
                          );
                        },
                      )),
            ],
          ),
        );
      },
    );
  }

  void _showLanguagePicker(BuildContext context, AppProvider appProvider) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select Language',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ...['English', 'नेपाली (Nepali)'].map((lang) => ListTile(
                    title: Text(lang),
                    trailing: appProvider.language == lang.split(' ').first
                        ? const Icon(Icons.check,
                            color: AppColors.secondaryCrimsonRed)
                        : null,
                    onTap: () {
                      appProvider.setLanguage(lang.split(' ').first);
                      Navigator.pop(context);
                    },
                  )),
            ],
          ),
        );
      },
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Change Password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Current Password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'New Password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Confirm New Password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Password updated successfully!'),
                    backgroundColor: AppColors.successGreen,
                  ),
                );
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }

  void _showPrivacyPolicy(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: const Text('Privacy Policy')),
          body: const SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Text(
              'Privacy Policy\n\n'
              'Connect Well Nepal respects your privacy and is committed to protecting your personal data.\n\n'
              '1. Data Collection\nWe collect information you provide directly to us, including name, email, and health-related information.\n\n'
              '2. Data Usage\nYour data is used solely for providing healthcare services and improving your experience.\n\n'
              '3. Data Protection\nWe implement industry-standard security measures to protect your information.\n\n'
              '4. Data Sharing\nWe do not sell or share your personal information with third parties except as required for healthcare services.\n\n'
              '5. Your Rights\nYou have the right to access, correct, or delete your personal data at any time.\n\n'
              'For questions, contact: privacy@connectwellnepal.com',
              style: TextStyle(fontSize: 14, height: 1.6),
            ),
          ),
        ),
      ),
    );
  }

  void _showTermsOfService(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: const Text('Terms of Service')),
          body: const SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Text(
              'Terms of Service\n\n'
              'Welcome to Connect Well Nepal. By using our app, you agree to these terms.\n\n'
              '1. Services\nConnect Well Nepal provides healthcare appointment booking and health resources.\n\n'
              '2. User Responsibilities\nYou are responsible for maintaining the confidentiality of your account.\n\n'
              '3. Medical Disclaimer\nOur app provides general health information and is not a substitute for professional medical advice.\n\n'
              '4. Limitation of Liability\nConnect Well Nepal is not liable for any damages arising from the use of our services.\n\n'
              '5. Changes to Terms\nWe reserve the right to modify these terms at any time.\n\n'
              'Last updated: January 2025',
              style: TextStyle(fontSize: 14, height: 1.6),
            ),
          ),
        ),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  'assets/logos/logo_icon.png',
                  height: 80,
                  width: 80,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Connect Well Nepal',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Version 1.0.0',
                style: TextStyle(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Connecting Nepalis to quality healthcare services. Our mission is to make healthcare accessible to everyone in Nepal.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showHelpSupport(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Help & Support',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              ListTile(
                leading: const Icon(Icons.email, color: AppColors.primaryNavyBlue),
                title: const Text('Email Support'),
                subtitle: const Text('support@connectwellnepal.com'),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.phone, color: AppColors.successGreen),
                title: const Text('Phone Support'),
                subtitle: const Text('+977-1-XXXXXXX'),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.chat, color: Colors.orange),
                title: const Text('Live Chat'),
                subtitle: const Text('Available 9 AM - 6 PM'),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showLogoutConfirmation(BuildContext context, AppProvider appProvider) {
    // Capture navigator before showing dialog
    final navigator = Navigator.of(context);
    
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                await appProvider.logout();
                navigator.pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const AuthScreen()),
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondaryCrimsonRed,
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteAccountConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Account'),
          content: const Text(
            'Are you sure you want to delete your account? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Account deletion request submitted.'),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}

