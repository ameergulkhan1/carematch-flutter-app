import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../shared/utils/responsive_utils.dart';
import '../caregiver_colors.dart';

class EarningsPage extends StatefulWidget {
  const EarningsPage({super.key});

  @override
  State<EarningsPage> createState() => _EarningsPageState();
}

class _EarningsPageState extends State<EarningsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _selectedPeriod = 'all'; // all, week, month, year
  double _totalEarnings = 0.0;
  double _pendingEarnings = 0.0;
  double _availableBalance = 0.0;

  @override
  void initState() {
    super.initState();
    _loadEarnings();
  }

  Future<void> _loadEarnings() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      // Get wallet
      final walletSnapshot = await _firestore
          .collection('wallets')
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      if (walletSnapshot.docs.isNotEmpty) {
        final wallet = walletSnapshot.docs.first.data();
        setState(() {
          _availableBalance = (wallet['balance'] ?? 0.0).toDouble();
        });
      }

      // Get transactions
      var query = _firestore
          .collection('wallet_transactions')
          .where('userId', isEqualTo: userId)
          .where('type', isEqualTo: 'credit');

      // Apply period filter
      if (_selectedPeriod != 'all') {
        DateTime startDate;
        final now = DateTime.now();
        
        switch (_selectedPeriod) {
          case 'week':
            startDate = now.subtract(const Duration(days: 7));
            break;
          case 'month':
            startDate = DateTime(now.year, now.month, 1);
            break;
          case 'year':
            startDate = DateTime(now.year, 1, 1);
            break;
          default:
            startDate = DateTime(2020, 1, 1);
        }

        query = query.where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }

      final transactionsSnapshot = await query.get();

      double total = 0.0;
      for (var doc in transactionsSnapshot.docs) {
        final data = doc.data();
        total += (data['amount'] ?? 0.0).toDouble();
      }

      // Get pending earnings from pending bills
      final pendingBillsSnapshot = await _firestore
          .collection('bills')
          .where('caregiverId', isEqualTo: userId)
          .where('status', whereIn: ['pending', 'approved']).get();

      double pending = 0.0;
      for (var doc in pendingBillsSnapshot.docs) {
        final data = doc.data();
        // Calculate net amount (after platform fee)
        final total = (data['totalAmount'] ?? 0.0).toDouble();
        final platformFee = (data['platformFee'] ?? 0.0).toDouble();
        pending += (total - platformFee);
      }

      setState(() {
        _totalEarnings = total;
        _pendingEarnings = pending;
      });
    } catch (e) {
      print('Error loading earnings: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveUtils.isMobile(context);
    final userId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(ResponsiveUtils.getContentPadding(context)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'Earnings & Payments',
              style: TextStyle(
                fontSize: ResponsiveUtils.getFontSize(context,
                    mobile: 24, tablet: 28, desktop: 32),
                fontWeight: FontWeight.bold,
                color: CaregiverColors.dark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Track your income and manage payouts',
              style: TextStyle(
                fontSize: ResponsiveUtils.getFontSize(context,
                    mobile: 14, tablet: 15, desktop: 16),
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),

            // Earnings Summary Cards
            _buildEarningsSummary(isMobile),
            const SizedBox(height: 24),

            // Period Filter
            _buildPeriodFilter(),
            const SizedBox(height: 20),

            // Transactions List
            _buildTransactionsList(userId),
          ],
        ),
      ),
      floatingActionButton: _availableBalance > 0
          ? FloatingActionButton.extended(
              onPressed: () => _requestPayout(context),
              backgroundColor: CaregiverColors.primary,
              icon: const Icon(Icons.account_balance_wallet),
              label: const Text('Request Payout'),
            )
          : null,
    );
  }

  Widget _buildEarningsSummary(bool isMobile) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: isMobile ? 1 : 3,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: isMobile ? 3 : 1.5,
      children: [
        _buildEarningCard(
          'Available Balance',
          '\$${_availableBalance.toStringAsFixed(2)}',
          Icons.account_balance_wallet,
          CaregiverColors.primary,
        ),
        _buildEarningCard(
          'Total Earnings',
          '\$${_totalEarnings.toStringAsFixed(2)}',
          Icons.trending_up,
          Colors.green,
        ),
        _buildEarningCard(
          'Pending',
          '\$${_pendingEarnings.toStringAsFixed(2)}',
          Icons.hourglass_empty,
          Colors.orange,
        ),
      ],
    );
  }

  Widget _buildEarningCard(
      String title, String amount, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            amount,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: CaregiverColors.dark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodFilter() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChip('All Time', 'all'),
          const SizedBox(width: 8),
          _buildFilterChip('This Week', 'week'),
          const SizedBox(width: 8),
          _buildFilterChip('This Month', 'month'),
          const SizedBox(width: 8),
          _buildFilterChip('This Year', 'year'),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String period) {
    final isSelected = _selectedPeriod == period;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _selectedPeriod = period);
        _loadEarnings();
      },
      selectedColor: CaregiverColors.primary.withOpacity(0.2),
      checkmarkColor: CaregiverColors.primary,
      labelStyle: TextStyle(
        color: isSelected ? CaregiverColors.primary : AppColors.textSecondary,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
      ),
    );
  }

  Widget _buildTransactionsList(String? userId) {
    if (userId == null) {
      return const Center(child: Text('Please log in to view transactions'));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('wallet_transactions')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final transactions = snapshot.data?.docs ?? [];

        if (transactions.isEmpty) {
          return Center(
            child: Column(
              children: [
                Icon(Icons.receipt_long, size: 64, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                Text(
                  'No transactions yet',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Transaction History',
              style: TextStyle(
                fontSize: ResponsiveUtils.getFontSize(context,
                    mobile: 18, tablet: 20, desktop: 22),
                fontWeight: FontWeight.bold,
                color: CaregiverColors.dark,
              ),
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: transactions.length,
              itemBuilder: (context, index) {
                final transaction = transactions[index].data() as Map<String, dynamic>;
                return _buildTransactionTile(transaction);
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildTransactionTile(Map<String, dynamic> transaction) {
    final type = transaction['type'] ?? 'unknown';
    final amount = (transaction['amount'] ?? 0.0).toDouble();
    final description = transaction['description'] ?? 'Transaction';
    final createdAt = (transaction['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
    final status = transaction['status'] ?? 'completed';

    final isCredit = type == 'credit';
    final color = isCredit ? Colors.green : Colors.red;
    final icon = isCredit ? Icons.add_circle : Icons.remove_circle;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: CaregiverColors.dark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('MMM dd, yyyy • hh:mm a').format(createdAt),
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isCredit ? '+' : '-'}\$${amount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _getStatusColor(status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: _getStatusColor(status),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'failed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Future<void> _requestPayout(BuildContext context) async {
    // Implement payout request dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Request Payout'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Available balance: \$${_availableBalance.toStringAsFixed(2)}'),
            const SizedBox(height: 16),
            const Text('Payout will be processed within 3-5 business days.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final userId = FirebaseAuth.instance.currentUser?.uid;
              if (userId == null) return;

              try {
                await _firestore.collection('payouts').add({
                  'caregiverId': userId,
                  'amount': _availableBalance,
                  'status': 'pending',
                  'requestedAt': FieldValue.serverTimestamp(),
                  'createdAt': FieldValue.serverTimestamp(),
                });

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Payout request submitted successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Request Payout'),
          ),
        ],
      ),
    );
  }
}
