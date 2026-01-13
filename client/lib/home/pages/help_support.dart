import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:libraryapp/core/theme/app_pallete.dart';
import 'package:libraryapp/core/widgets/common/common_app_bar.dart';
import 'package:url_launcher/url_launcher.dart';

/// Help and Support page with FAQs, contact info, and support options.
class HelpSupport extends StatelessWidget {
  const HelpSupport({super.key});

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
            'To borrow a book, simply navigate to the book details page and tap the "Borrow" button. The book will be added to your borrowed list with a 14-day loan period.',
      },
      {
        'question': 'How do I return a book?',
        'answer':
            'Go to your "Borrowed" section, find the book you want to return, and tap the "Return" button. You can also visit the library in person to return physical copies.',
      },
      {
        'question': 'Can I extend my loan period?',
        'answer':
            'Yes! You can renew your loan for an additional 14 days from the borrowed section. Note that renewals may be limited depending on book demand.',
      },
      {
        'question': 'How do fines work?',
        'answer':
            'Fines are charged for overdue books at \$0.50 per day. You can view your current fines in your profile. Fines must be paid to continue borrowing.',
      },
      {
        'question': 'How do I reserve a book?',
        'answer':
            'If a book is currently unavailable, you can reserve it by tapping the "Reserve" button on the book details page. You\'ll be notified when it becomes available.',
      },
      {
        'question': 'How do I update my profile?',
        'answer':
            'Go to your Profile page and tap the "Edit" button at the top. You can update your name, email, phone number, and address.',
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
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          iconColor: Pallete.primaryLight,
          collapsedIconColor: Pallete.textSecondary,
          title: Text(
            question,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          children: [
            Text(
              answer,
              style: TextStyle(
                color: Pallete.textSecondary,
                fontSize: 14,
                height: 1.5,
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
            Icons.email_outlined,
            'Email',
            'support@libraryapp.com',
            () => _launchEmail(context),
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
            Icons.access_time_outlined,
            'Hours',
            'Mon-Fri: 9AM - 6PM EST',
            null,
          ),
          _buildContactItem(
            context,
            Icons.location_on_outlined,
            'Address',
            '123 Library Street, Book City, BC 12345',
            null,
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem(
    BuildContext context,
    IconData icon,
    String title,
    String value,
    VoidCallback? onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Pallete.cardBackground,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Pallete.scaffoldBackground,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Pallete.primaryLight, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
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
              Icon(Icons.chevron_right, color: Pallete.textSecondary),
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
                const Divider(color: Colors.white12, height: 24),
                _buildInfoRow('Last Updated', 'January 2026'),
                const Divider(color: Colors.white12, height: 24),
                _buildInfoRow('Developer', 'LibraryApp Team'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Pallete.primaryLight),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Privacy Policy',
                    style: TextStyle(color: Pallete.primaryLight),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Pallete.primaryLight),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Terms of Service',
                    style: TextStyle(color: Pallete.primaryLight),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(color: Pallete.textSecondary, fontSize: 14),
        ),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 14)),
      ],
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Live chat coming soon!'),
        backgroundColor: Pallete.primaryLight,
      ),
    );
  }

  Future<void> _launchEmail(BuildContext context) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'support@libraryapp.com',
      queryParameters: {'subject': 'LibraryApp Support Request'},
    );

    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      } else {
        if (context.mounted) {
          await Clipboard.setData(
            const ClipboardData(text: 'support@libraryapp.com'),
          );
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Email copied to clipboard'),
              backgroundColor: Pallete.primaryLight,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open email client'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _launchPhone(BuildContext context) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: '+15551234567');

    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        if (context.mounted) {
          await Clipboard.setData(
            const ClipboardData(text: '+1 (555) 123-4567'),
          );
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Phone number copied to clipboard'),
              backgroundColor: Pallete.primaryLight,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open phone dialer'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _showReportIssueDialog(BuildContext context) {
    final TextEditingController issueController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Pallete.cardBackground,
        title: const Text(
          'Report an Issue',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Describe the issue you\'re experiencing:',
              style: TextStyle(color: Pallete.textSecondary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: issueController,
              maxLines: 4,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Enter your issue here...',
                hintStyle: TextStyle(color: Pallete.textSecondary),
                filled: true,
                fillColor: Pallete.scaffoldBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
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
                  content: Text('Issue reported. Thank you for your feedback!'),
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
