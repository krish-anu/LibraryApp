import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:libraryapp/core/providers/theme_provider.dart';

class Profile extends ConsumerWidget {
  const Profile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(isDarkProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0D1F0D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1F0D),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Profile",
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () {},
            child: const Text(
              "Edit",
              style: TextStyle(color: Color(0xFF4CAF50)),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Profile Avatar
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF4CAF50), width: 3),
              ),
              child: const CircleAvatar(
                radius: 50,
                backgroundImage: NetworkImage(
                  "https://imgs.search.brave.com/3B_SYXXUKA9Ou_fT79_C_16EtIRigAAFd0itd7KO3oM/rs:fit:500:0:1:0/g:ce/aHR0cHM6Ly9zdGF0/aWMudmVjdGVlenku/Y29tL3N5c3RlbS9y/ZXNvdXJjZXMvdGh1/bWJuYWlscy8wMjIv/OTU1LzI5Ni9zbWFs/bC9wb3J0cmFpdC1v/Zi1idXNpbmVzc3Bl/cnNvbi1hbmQtdGhl/LWdlbmVyYXRpb24t/cGVyc29uYWxpdGll/cy1vZi1uZXctZXhl/Y3V0aXZlcy13aXRo/LWdvb2QtaWRlYXMt/cGVyc29uYWxpdHkt/YW5kLXZpc2lvbi1w/aG90by5qcGc",
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Name
            const Text(
              "Jane Doe",
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            // Member ID
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.badge_outlined, color: Colors.grey[400], size: 16),
                const SizedBox(width: 4),
                Text(
                  "Member ID: #8392102",
                  style: TextStyle(color: Colors.grey[400], fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Active Member Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF1B3D1B),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 16),
                  SizedBox(width: 4),
                  Text(
                    "ACTIVE MEMBER",
                    style: TextStyle(
                      color: Color(0xFF4CAF50),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Stats Row
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: const Color(0xFF142814),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatItem(
                    Icons.menu_book,
                    "3",
                    "BORROWS",
                    const Color(0xFF4CAF50),
                  ),
                  _buildStatItem(
                    Icons.history,
                    "42",
                    "READ",
                    Colors.grey[400]!,
                  ),
                  _buildStatItem(
                    Icons.attach_money,
                    "\$0.00",
                    "FINES",
                    const Color(0xFF4CAF50),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Account Section
            _buildSectionTitle("ACCOUNT"),
            _buildMenuItem(Icons.person_outline, "Personal Information"),
            _buildMenuItem(Icons.lock_outline, "Change Password"),
            _buildMenuItem(Icons.credit_card, "My Digital Card"),
            const SizedBox(height: 16),
            // App Preferences Section
            _buildSectionTitle("APP PREFERENCES"),
            _buildToggleItem(
              Icons.notifications_outlined,
              "Push Notifications",
              true,
              (value) {},
            ),
            _buildToggleItem(Icons.dark_mode_outlined, "Dark Mode", isDark, (
              value,
            ) {
              ref.read(isDarkProvider.notifier).state = value;
            }),
            const SizedBox(height: 16),
            // Support Section
            _buildSectionTitle("SUPPORT"),
            _buildMenuItem(Icons.help_outline, "Help & Support"),
            const SizedBox(height: 24),
            // Sign Out Button
            TextButton(
              onPressed: () {},
              child: const Text(
                "← Sign Out",
                style: TextStyle(color: Color(0xFFE57373), fontSize: 16),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "App Version 1.0.2",
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    IconData icon,
    String value,
    String label,
    Color iconColor,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF1B3D1B),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 10)),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: TextStyle(
            color: Colors.grey[500],
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF142814),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.grey[400]),
        title: Text(
          title,
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        trailing: Icon(Icons.chevron_right, color: Colors.grey[600]),
        onTap: () {},
      ),
    );
  }

  Widget _buildToggleItem(
    IconData icon,
    String title,
    bool value,
    Function(bool) onChanged,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF142814),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.grey[400]),
        title: Text(
          title,
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: const Color(0xFF4CAF50),
          activeTrackColor: const Color(0xFF1B5E20),
        ),
      ),
    );
  }
}
