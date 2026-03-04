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
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: const Color(0xFFE53935),
                      backgroundImage:
                          _avatarUrl != null ? NetworkImage(_avatarUrl!) : null,
                      child: _avatarUrl == null
                          ? Text(
                              (user?.email ?? 'U')[0].toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    ),
                    IconButton(
                      onPressed: _saving ? null : _pickAndUploadAvatar,
                      icon: const Icon(Icons.camera_alt, size: 18),
                      color: Theme.of(context).colorScheme.onSurface,
                      style: IconButton.styleFrom(
                        backgroundColor:
                            Theme.of(context).colorScheme.surfaceContainerHighest,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user?.email ?? '',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 4),
                      Text(user?.id ?? '',
                          style:
                              const TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text('Full Name',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 8),
            TextField(
              controller: _nameCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                filled: true,
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _saveProfile,
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save'),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Change Password',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 8),
            TextField(
              controller: _passwordCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                filled: true,
                prefixIcon: Icon(Icons.lock),
                hintText: 'New password',
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _changePassword,
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Update Password'),
              ),
            ),
            const SizedBox(height: 12),
            if (_msg != null)
              Text(_msg!,
                  style: TextStyle(
                      color: _msg!.contains('Failed') ? Colors.red : Colors.green)),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  await Supabase.instance.client.auth.signOut();
                  if (!mounted) return;
                  Navigator.of(context)
                      .pushNamedAndRemoveUntil('/', (route) => false);
                },
                icon: const Icon(Icons.logout),
                label: const Text('Sign Out'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
