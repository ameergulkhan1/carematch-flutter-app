import 'package:flutter/material.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/app_footer.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_colors.dart';

class FaqPage extends StatefulWidget {
  const FaqPage({super.key});

  @override
  State<FaqPage> createState() => _FaqPageState();
}

class _FaqPageState extends State<FaqPage> {
  int? _expandedIndex;

  final List<Map<String, String>> _faqs = [
    {
      'question': 'How do I find a caregiver?',
      'answer': 'Simply create an account, complete your profile with care requirements, and use our search filters to find caregivers by location, skills, availability, and ratings. You can review detailed profiles and contact caregivers directly through our platform.',
    },
    {
      'question': 'Are all caregivers verified?',
      'answer': 'Yes, all caregivers undergo thorough background checks, identity verification, and skill assessments before being approved on our platform. We verify credentials, work history, and conduct interviews to ensure quality and safety.',
    },
    {
      'question': 'How much does it cost?',
      'answer': 'CareMatch is free for families to join and search for caregivers. We charge a 15% platform fee on each completed booking, which covers payment processing, insurance, and platform services. Caregivers set their own hourly rates based on their experience and services offered.',
    },
    {
      'question': 'What payment methods do you accept?',
      'answer': 'We accept all major credit cards, debit cards, and bank transfers. All payments are processed securely through our encrypted platform. Funds are held in escrow and released to caregivers after service completion.',
    },
    {
      'question': 'Can I cancel or reschedule a booking?',
      'answer': 'Yes, you can cancel or reschedule bookings through your dashboard. Our cancellation policy requires 24 hours notice for full refunds. Cancellations within 24 hours may incur a fee. Emergency cancellations are reviewed on a case-by-case basis.',
    },
    {
      'question': 'What if I\'m not satisfied with a caregiver?',
      'answer': 'Your satisfaction is our priority. If you\'re not happy with a caregiver, contact our support team immediately. We offer dispute resolution, alternative caregiver recommendations, and refunds when appropriate. You can also leave honest reviews to help other families.',
    },
    {
      'question': 'How do I become a caregiver on CareMatch?',
      'answer': 'Register on our platform, complete your profile with experience and certifications, and submit required documents for verification. Our admin team will review your application within 48-72 hours. Once approved, you can start receiving booking requests.',
    },
    {
      'question': 'What documents do caregivers need to provide?',
      'answer': 'Caregivers must provide a valid ID, proof of certifications/training, background check consent, professional references, and any relevant licenses (for medical care). Additional documents may be required based on service type.',
    },
    {
      'question': 'Is there insurance coverage?',
      'answer': 'Yes, all bookings through CareMatch include liability insurance coverage for both families and caregivers. This protects against accidents and injuries during care services. Additional insurance options are available for specialized care.',
    },
    {
      'question': 'How do I contact customer support?',
      'answer': 'Our support team is available 24/7 via live chat, email (support@carematch.com), or phone. You can also access our help center with guides and tutorials. Emergency support is prioritized for urgent safety concerns.',
    },
    {
      'question': 'Can I hire the same caregiver regularly?',
      'answer': 'Absolutely! You can save favorite caregivers and book recurring appointments directly with them. Many families build long-term relationships with caregivers through our platform. Regular bookings often receive discounted rates.',
    },
    {
      'question': 'What happens in case of emergency?',
      'answer': 'All caregivers are trained in emergency protocols and have access to 24/7 support. In case of emergency, caregivers should call 911 first, then notify the family and our support team. We maintain emergency contact information for all users.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppHeader(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Hero Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.primary.withOpacity(0.1), AppColors.secondary.withOpacity(0.1)],
                ),
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: Column(
                    children: [
                      Text('Frequently Asked Questions', style: AppTextStyles.displayLarge),
                      const SizedBox(height: 16),
                      Text(
                        'Find answers to common questions about CareMatch',
                        style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // FAQ List
            Container(
              padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: Column(
                    children: List.generate(
                      _faqs.length,
                      (index) => _buildFaqItem(index, _faqs[index]['question']!, _faqs[index]['answer']!),
                    ),
                  ),
                ),
              ),
            ),

            // Contact Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
              color: AppColors.backgroundLight,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: Column(
                    children: [
                      Text('Still have questions?', style: AppTextStyles.headlineLarge),
                      const SizedBox(height: 16),
                      Text(
                        'Our support team is here to help you 24/7',
                        style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        alignment: WrapAlignment.center,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.email),
                            label: const Text('Email Support'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.chat),
                            label: const Text('Live Chat'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const AppFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildFaqItem(int index, String question, String answer) {
    final isExpanded = _expandedIndex == index;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _expandedIndex = isExpanded ? null : index;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      question,
                      style: AppTextStyles.titleMedium.copyWith(
                        color: isExpanded ? AppColors.primary : AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.remove_circle_outline : Icons.add_circle_outline,
                    color: AppColors.primary,
                  ),
                ],
              ),
              if (isExpanded) ...[
                const SizedBox(height: 16),
                Text(
                  answer,
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
