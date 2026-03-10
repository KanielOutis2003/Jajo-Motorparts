import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _saving = false;
  String? _msg;
  String? _avatarUrl;

  @override
  void initState() {
    super.initState();
    final user = Supabase.instance.client.auth.currentUser;
    final name = user?.userMetadata?['full_name'] as String?;
    _nameCtrl.text = name ?? '';
    final avatar = user?.userMetadata?['avatar_url'] as String?;
    _avatarUrl = avatar;
  }

  Future<void> _saveProfile() async {
    setState(() {
      _saving = true;
      _msg = null;
    });
    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(data: {
          'full_name': _nameCtrl.text.trim(),
          if (_avatarUrl != null) 'avatar_url': _avatarUrl,
        }),
      );
      setState(() => _msg = 'Profile updated');
    } catch (_) {
      setState(() => _msg = 'Failed to update profile');
    } finally {
      setState(() => _saving = false);
    }
  }

  Future<void> _pickAndUploadAvatar() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    try {
      final picker = ImagePicker();
      final picked =
          await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (picked == null) return;
      setState(() {
        _saving = true;
        _msg = null;
      });
      final file = File(picked.path);
      final storage = Supabase.instance.client.storage;
      final objectPath = 'avatars/${user.id}.jpg';
      await storage
          .from('avatars')
          .upload(objectPath, file, fileOptions: const FileOptions(upsert: true));
      final publicUrl =
          storage.from('avatars').getPublicUrl(objectPath);
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(data: {'avatar_url': publicUrl}),
      );
      setState(() {
        _avatarUrl = publicUrl;
        _msg = 'Profile photo updated';
      });
    } catch (_) {
      setState(() => _msg = 'Failed to update profile photo');
    } finally {
      setState(() => _saving = false);
    }
  }

  Future<void> _changePassword() async {
    if (_passwordCtrl.text.trim().length < 6) {
      setState(() => _msg = 'Password too short');
      return;
    }
    setState(() {
      _saving = true;
      _msg = null;
    });
    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: _passwordCtrl.text.trim()),
      );
      setState(() => _msg = 'Password updated');
      _passwordCtrl.clear();
    } catch (_) {
      setState(() => _msg = 'Failed to update password');
    } finally {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Account Profile'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Header Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.primary.withValues(alpha: 0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                        child: CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          backgroundImage: _avatarUrl != null
                              ? NetworkImage(_avatarUrl!)
                              : null,
                          child: _avatarUrl == null
                              ? Text(
                                  (user?.email ?? 'U')[0].toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : null,
                        ),
                      ),
                      Container(
                        height: 32,
                        width: 32,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 4)
                          ],
                        ),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          onPressed: _saving ? null : _pickAndUploadAvatar,
                          icon: Icon(Icons.camera_alt,
                              size: 16, color: theme.colorScheme.primary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _nameCtrl.text.isEmpty
                              ? 'User Name'
                              : _nameCtrl.text,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user?.email ?? '',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Settings Section
            _sectionHeader('PERSONAL INFORMATION'),
            const SizedBox(height: 12),
            _infoTile(
              label: 'Full Name',
              controller: _nameCtrl,
              icon: Icons.person_outline,
              onSave: _saveProfile,
              saving: _saving,
            ),
            const SizedBox(height: 24),

            _sectionHeader('SECURITY'),
            const SizedBox(height: 12),
            _infoTile(
              label: 'Change Password',
              controller: _passwordCtrl,
              icon: Icons.lock_outline,
              hint: 'Enter new password',
              isPassword: true,
              onSave: _changePassword,
              saving: _saving,
            ),

            const SizedBox(height: 40),
            const Divider(),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: () async {
                  await Supabase.instance.client.auth.signOut();
                  if (!mounted) return;
                  Navigator.of(context)
                      .pushNamedAndRemoveUntil('/', (route) => false);
                },
                icon: const Icon(Icons.logout, color: Colors.red),
                label: const Text(
                  'Sign Out',
                  style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 16),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: Colors.red, width: 1.5),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'App Version 1.0.0',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: TextStyle(
          color: Colors.grey.shade600,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _infoTile({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required VoidCallback onSave,
    required bool saving,
    String? hint,
    bool isPassword = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: Colors.grey),
              const SizedBox(width: 8),
              Text(label,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  obscureText: isPassword,
                  decoration: InputDecoration(
                    hintText: hint,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                ),
              ),
              IconButton(
                onPressed: saving ? null : onSave,
                icon: saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.check_circle, color: Colors.green),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
