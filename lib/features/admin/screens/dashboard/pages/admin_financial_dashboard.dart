import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../models/transaction_model.dart' as txn;
import '../../../../../models/invoice_model.dart';
import '../../../../../services/payment_service.dart';
import '../../../../../services/billing_service.dart';
import '../../../../../services/refund_service.dart';

class AdminFinancialDashboard extends StatefulWidget {
  const AdminFinancialDashboard({super.key});

  @override
  State<AdminFinancialDashboard> createState() => _AdminFinancialDashboardState();
}

class _AdminFinancialDashboardState extends State<AdminFinancialDashboard> {
  final PaymentService _paymentService = PaymentService();
  final BillingService _billingService = BillingService();
  final RefundService _refundService = RefundService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Financial Dashboard'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildFinancialOverview(),
          const SizedBox(height: 24),
          _buildRevenueChart(),
          const SizedBox(height: 24),
          _buildPendingPayouts(),
          const SizedBox(height: 24),
          _buildPendingRefunds(),
          const SizedBox(height: 24),
          _buildRecentTransactions(),
        ],
      ),
    );
  }

  Widget _buildFinancialOverview() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Financial Overview',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            FutureBuilder<Map<String, double>>(
              future: _calculateFinancialStats(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final stats = snapshot.data ?? {};
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Total Revenue',
                            '\$${stats['totalRevenue']?.toStringAsFixed(2) ?? '0.00'}',
                            Icons.attach_money,
                            Colors.green,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            'Platform Fees',
                            '\$${stats['platformFees']?.toStringAsFixed(2) ?? '0.00'}',
                            Icons.account_balance,
                            Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Pending Payouts',
                            '\$${stats['pendingPayouts']?.toStringAsFixed(2) ?? '0.00'}',
                            Icons.pending_actions,
                            Colors.orange,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            'Refunded',
                            '\$${stats['totalRefunded']?.toStringAsFixed(2) ?? '0.00'}',
                            Icons.money_off,
                            Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueChart() {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Revenue Trend (Last 7 Days)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: Center(
                child: Text('Chart implementation requires fl_chart package'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingPayouts() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Pending Payouts',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () {
                    // Navigate to payouts page
                  },
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            StreamBuilder<List<txn.Payout>>(
              stream: _paymentService.getPendingPayouts(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'No pending payouts',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ),
                  );
                }

                final payouts = snapshot.data!.take(5).toList();
                return Column(
                  children: payouts.map((payout) {
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: Colors.orange[100],
                        child: const Icon(Icons.account_balance_wallet, color: Colors.orange),
                      ),
                      title: Text(payout.caregiverName),
                      subtitle: Text(
                        'Requested ${DateFormat('MMM d, yyyy').format(payout.requestedAt)}',
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '\$${payout.amount.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            'Net: \$${payout.netAmount.toStringAsFixed(2)}',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                      onTap: () => _showPayoutDetails(payout),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingRefunds() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Pending Refunds',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () {
                    // Navigate to refunds page
                  },
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            StreamBuilder<List<Refund>>(
              stream: _refundService.getPendingRefunds(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'No pending refunds',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ),
                  );
                }

                final refunds = snapshot.data!.take(5).toList();
                return Column(
                  children: refunds.map((refund) {
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: Colors.red[100],
                        child: const Icon(Icons.undo, color: Colors.red),
                      ),
                      title: Text(refund.clientName),
                      subtitle: Text(
                        '${refund.reason.name} - ${refund.reasonDescription.substring(0, refund.reasonDescription.length > 30 ? 30 : refund.reasonDescription.length)}...',
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '\$${refund.refundAmount.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          if (refund.isPartialRefund)
                            const Text(
                              'Partial',
                              style: TextStyle(fontSize: 12, color: Colors.orange),
                            ),
                        ],
                      ),
                      onTap: () => _showRefundDetails(refund),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentTransactions() {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Transactions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Center(
              child: Text('Transaction list implementation'),
            ),
          ],
        ),
      ),
    );
  }

  Future<Map<String, double>> _calculateFinancialStats() async {
    // This is a simplified version - implement with proper Firestore aggregation
    return {
      'totalRevenue': 125430.50,
      'platformFees': 18814.58,
      'pendingPayouts': 8500.00,
      'totalRefunded': 2340.00,
    };
  }

  void _showPayoutDetails(txn.Payout payout) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Payout Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Caregiver: ${payout.caregiverName}'),
            Text('Amount: \$${payout.amount.toStringAsFixed(2)}'),
            Text('Fee: \$${payout.fee.toStringAsFixed(2)}'),
            Text('Net Amount: \$${payout.netAmount.toStringAsFixed(2)}'),
            const SizedBox(height: 8),
            Text('Bank: ${payout.bankName}'),
            Text('Account: ${payout.accountNumber}'),
            Text('Account Holder: ${payout.accountHolderName}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Process payout
              Navigator.pop(context);
            },
            child: const Text('Approve'),
          ),
        ],
      ),
    );
  }

  void _showRefundDetails(Refund refund) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Refund Request'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Client: ${refund.clientName}'),
            Text('Caregiver: ${refund.caregiverName}'),
            Text('Reason: ${refund.reason.name}'),
            const SizedBox(height: 8),
            Text('Description: ${refund.reasonDescription}'),
            const SizedBox(height: 8),
            Text('Original Amount: \$${refund.originalAmount.toStringAsFixed(2)}'),
            Text('Refund Amount: \$${refund.refundAmount.toStringAsFixed(2)}'),
            Text('Refund Fee: \$${refund.refundFee.toStringAsFixed(2)}'),
            Text('Net Refund: \$${refund.netRefund.toStringAsFixed(2)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _refundService.rejectRefund(
                refundId: refund.id,
                rejectedBy: 'admin',
                rejectionReason: 'Rejected by admin',
              );
              Navigator.pop(context);
            },
            child: const Text('Reject'),
          ),
          ElevatedButton(
            onPressed: () {
              _refundService.approveRefund(
                refundId: refund.id,
                approvedBy: 'admin',
              );
              Navigator.pop(context);
            },
            child: const Text('Approve'),
          ),
        ],
      ),
    );
  }
}
