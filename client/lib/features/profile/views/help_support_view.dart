import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:libraryapp/core/theme/app_pallete.dart';
import 'package:libraryapp/core/widgets/common/common_app_bar.dart';
import 'package:url_launcher/url_launcher.dart';

/// Help and Support page with FAQs, contact info, and support options.
class HelpSupportView extends StatelessWidget {
  const HelpSupportView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Pallete.scaffoldBackground,
      appBar: const CommonAppBar(title: 'Help & Support', centerTitle: true),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildSearchBar(),
            const SizedBox(height: 24),
            _buildQuickActions(context),
            const SizedBox(height: 24),
            _buildFAQSection(context),
            const SizedBox(height: 24),
            _buildContactSection(context),
            const SizedBox(height: 24),
            _buildAppInfoSection(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Pallete.primaryLight, Color(0xFF1A5F7A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.support_agent, color: Colors.white, size: 48),
          SizedBox(height: 16),
          Text(
            'How can we help you?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Find answers to frequently asked questions or get in touch with our support team.',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: TextField(
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Search for help...',
          hintStyle: TextStyle(color: Pallete.textSecondary),
          prefixIcon: Icon(Icons.search, color: Pallete.textSecondary),
          filled: true,
          fillColor: Pallete.cardBackground,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Actions',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildQuickActionCard(
                  context,
                  Icons.chat_bubble_outline,
                  'Live Chat',
                  'Chat with support',
                  () => _showComingSoon(context),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionCard(
                  context,
                  Icons.email_outlined,
                  'Email Us',
                  'Get help via email',
                  () => _launchEmail(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildQuickActionCard(
                  context,
                  Icons.phone_outlined,
                  'Call Us',
                  'Speak with support',
                  () => _launchPhone(context),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionCard(
                  context,
                  Icons.bug_report_outlined,
                  'Report Issue',
                  'Report a problem',
                  () => _showReportIssueDialog(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Pallete.cardBackground,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Pallete.primaryLight, size: 28),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(color: Pallete.textSecondary, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQSection(BuildContext context) {
    final faqs = [
      {
        'question': 'How do I borrow a book?',
        'answer':
            'Navigate to the book you want to borrow and tap the "Borrow" button. The book will be added to your borrowed items.',
      },
      {
        'question': 'How do I return a book?',
        'answer':
            'Self-return is currently not available in the app. Please return books at the library desk.',
      },
      {
        'question': 'How do I reserve a book?',
        'answer':
            'If a book is currently unavailable, you can tap the "Reserve" button to add it to your reservation list.',
      },
      {
        'question': 'What are the fines for late returns?',
        'answer':
            'Late returns incur a fine of \$0.50 per day. You can view your total fines in your profile.',
      },
      {
        'question': 'How do I renew a borrowed book?',
        'answer':
            'Loan renewal is currently not available in the app. Please contact the library desk for assistance.',
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Frequently Asked Questions',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...faqs.map(
            (faq) => _buildFAQItem(context, faq['question']!, faq['answer']!),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQItem(BuildContext context, String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Pallete.cardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
          title: Text(
            question,
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
          iconColor: Pallete.primaryLight,
          collapsedIconColor: Pallete.textSecondary,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                answer,
                style: TextStyle(color: Pallete.textSecondary, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Contact Information',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildContactItem(
            context,
            Icons.location_on_outlined,
            'Address',
            '123 Library Street, Book City, BC 12345',
            () => _copyToClipboard(
              context,
              '123 Library Street, Book City, BC 12345',
            ),
          ),
          _buildContactItem(
            context,
            Icons.phone_outlined,
            'Phone',
            '+1 (555) 123-4567',
            () => _launchPhone(context),
          ),
          _buildContactItem(
            context,
            Icons.email_outlined,
            'Email',
            'support@libraryapp.com',
            () => _launchEmail(context),
          ),
          _buildContactItem(
            context,
            Icons.access_time,
            'Hours',
            'Mon-Fri: 9AM-9PM, Sat-Sun: 10AM-6PM',
            null,
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem(
    BuildContext context,
    IconData icon,
    String label,
    String value,
    VoidCallback? onTap,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Pallete.cardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            Icon(icon, color: Pallete.primaryLight, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: Pallete.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(Icons.content_copy, color: Pallete.textSecondary, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildAppInfoSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'App Information',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Pallete.cardBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _buildInfoRow('Version', '1.0.2'),
                Divider(color: Pallete.border),
                _buildInfoRow('Build', '2024.01.15'),
                Divider(color: Pallete.border),
                _buildInfoRow('Platform', 'Flutter'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: Pallete.textSecondary, fontSize: 14),
          ),
          Text(
            value,
            style: const TextStyle(color: Pallete.textPrimary, fontSize: 14),
          ),
        ],
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('This feature is coming soon!'),
        backgroundColor: Pallete.primaryLight,
      ),
    );
  }

  Future<void> _launchEmail(BuildContext context) async {
    final uri = Uri(
      scheme: 'mailto',
      path: 'support@libraryapp.com',
      query: 'subject=Support Request',
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (context.mounted) {
        _copyToClipboard(context, 'support@libraryapp.com');
      }
    }
  }

  Future<void> _launchPhone(BuildContext context) async {
    final uri = Uri(scheme: 'tel', path: '+15551234567');

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (context.mounted) {
        _copyToClipboard(context, '+1 (555) 123-4567');
      }
    }
  }

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied to clipboard'),
        backgroundColor: Pallete.primaryLight,
      ),
    );
  }

  void _showReportIssueDialog(BuildContext context) {
    final TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Pallete.cardBackground,
        title: const Text(
          'Report an Issue',
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: controller,
          maxLines: 4,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Describe the issue...',
            hintStyle: TextStyle(color: Pallete.textSecondary),
            filled: true,
            fillColor: Pallete.scaffoldBackground,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: Pallete.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Thank you! Your report has been submitted.'),
                  backgroundColor: Pallete.primaryLight,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Pallete.primaryLight,
            ),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }
}
