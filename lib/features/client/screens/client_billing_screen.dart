import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/billing_service.dart';
import '../../../services/payment_service.dart';
import '../../../models/bill_model.dart';
import '../../../models/transaction_model.dart' as txn;
import '../../../models/invoice_model.dart';
import 'dashboard/client_colors.dart';

class ClientBillingScreen extends StatefulWidget {
  const ClientBillingScreen({super.key});

  @override
  State<ClientBillingScreen> createState() => _ClientBillingScreenState();
}

class _ClientBillingScreenState extends State<ClientBillingScreen>
    with SingleTickerProviderStateMixin {
  final BillingService _billingService = BillingService();
  final PaymentService _paymentService = PaymentService();

  late TabController _tabController;
  List<Bill> _bills = [];
  List<txn.Transaction> _transactions = [];
  List<Invoice> _invoices = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadBillingData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadBillingData() async {
    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.currentUser?.uid;

      print('💰 Loading billing data for user: $userId');

      if (userId != null) {
        // Load bills, transactions, and invoices
        _billingService.getClientBills(userId).listen((bills) {
          print('💰 Received ${bills.length} bills');
          if (mounted) {
            setState(() {
              _bills = bills;
            });
          }
        }, onError: (error) {
          print('❌ Error loading bills: $error');
        });

        _paymentService.getUserTransactions(userId: userId, userRole: 'client').listen((transactions) {
          print('💰 Received ${transactions.length} transactions');
          if (mounted) {
            setState(() {
              _transactions = transactions;
            });
          }
        }, onError: (error) {
          print('❌ Error loading transactions: $error');
        });

        _billingService.getClientInvoices(userId).listen((invoices) {
          print('💰 Received ${invoices.length} invoices');
          if (mounted) {
            setState(() {
              _invoices = invoices;
            });
          }
        }, onError: (error) {
          print('❌ Error loading invoices: $error');
        });
      }

      setState(() => _isLoading = false);
    } catch (e) {
      print('❌ Error loading billing data: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ClientColors.background,
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Billing & Payments',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: ClientColors.dark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Manage your bills, payments, and invoices',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 16),
                TabBar(
                  controller: _tabController,
                  labelColor: ClientColors.primary,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: ClientColors.primary,
                  tabs: const [
                    Tab(text: 'Bills'),
                    Tab(text: 'Transactions'),
                    Tab(text: 'Invoices'),
                  ],
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildBillsTab(),
                      _buildTransactionsTab(),
                      _buildInvoicesTab(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildBillsTab() {
    if (_bills.isEmpty) {
      return _buildEmptyState(
        icon: Icons.receipt_long,
        title: 'No Bills Yet',
        message: 'Your bills will appear here after service completion',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadBillingData,
      child: ListView.builder(
        padding: const EdgeInsets.all(24),
        itemCount: _bills.length,
        itemBuilder: (context, index) {
          return _buildBillCard(_bills[index]);
        },
      ),
    );
  }

  Widget _buildBillCard(Bill bill) {
    final statusColor = _getBillStatusColor(bill.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showBillDetails(bill),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          bill.caregiverName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: ClientColors.dark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Booking #${bill.bookingId.substring(0, 8)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      bill.status.name.toUpperCase(),
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildBillDetail('Base Cost', '\$${bill.baseCost.toStringAsFixed(2)}'),
                  _buildBillDetail('Platform Fee', '\$${bill.platformFee.toStringAsFixed(2)}'),
                  _buildBillDetail('Total', '\$${bill.totalAmount.toStringAsFixed(2)}',
                      isHighlight: true),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Created: ${DateFormat('MMM dd, yyyy').format(bill.createdAt)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              if (bill.status == BillStatus.pending) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _disputeBill(bill),
                        icon: const Icon(Icons.report_problem, size: 18),
                        label: const Text('Dispute'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: ClientColors.warning,
                          side: const BorderSide(color: ClientColors.warning),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: () => _approveBill(bill),
                        icon: const Icon(Icons.check_circle, size: 18),
                        label: const Text('Approve & Pay'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ClientColors.success,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBillDetail(String label, String value, {bool isHighlight = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: isHighlight ? 16 : 14,
            fontWeight: isHighlight ? FontWeight.bold : FontWeight.w600,
            color: isHighlight ? ClientColors.primary : ClientColors.dark,
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionsTab() {
    if (_transactions.isEmpty) {
      return _buildEmptyState(
        icon: Icons.payments,
        title: 'No Transactions Yet',
        message: 'Your payment transactions will appear here',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadBillingData,
      child: ListView.builder(
        padding: const EdgeInsets.all(24),
        itemCount: _transactions.length,
        itemBuilder: (context, index) {
          return _buildTransactionCard(_transactions[index]);
        },
      ),
    );
  }

  Widget _buildTransactionCard(txn.Transaction transaction) {
    final statusColor = _getTransactionStatusColor(transaction.status);
    final isDebit = transaction.type == txn.TransactionType.charge;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isDebit ? Icons.arrow_upward : Icons.arrow_downward,
                color: statusColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.description,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: ClientColors.dark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${transaction.type.name} • ${DateFormat('MMM dd, yyyy').format(transaction.createdAt)}',
                    style: TextStyle(
                      fontSize: 12,
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
                  '${isDebit ? '-' : '+'}\$${transaction.amount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDebit ? ClientColors.danger : ClientColors.success,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    transaction.status.name,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvoicesTab() {
    if (_invoices.isEmpty) {
      return _buildEmptyState(
        icon: Icons.description,
        title: 'No Invoices Yet',
        message: 'Your invoices will appear here after payment',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadBillingData,
      child: ListView.builder(
        padding: const EdgeInsets.all(24),
        itemCount: _invoices.length,
        itemBuilder: (context, index) {
          return _buildInvoiceCard(_invoices[index]);
        },
      ),
    );
  }

  Widget _buildInvoiceCard(Invoice invoice) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      invoice.invoiceNumber,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: ClientColors.dark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      invoice.caregiverName,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '\$${invoice.totalAmount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: ClientColors.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: ClientColors.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        invoice.status.name.toUpperCase(),
                        style: const TextStyle(
                          color: ClientColors.success,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Issue Date: ${DateFormat('MMM dd, yyyy').format(invoice.issueDate)}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: invoice.pdfUrl != null
                        ? () => _downloadInvoice(invoice)
                        : null,
                    icon: const Icon(Icons.download, size: 18),
                    label: const Text('Download PDF'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: ClientColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _viewInvoice(invoice),
                    icon: const Icon(Icons.visibility, size: 18),
                    label: const Text('View Details'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ClientColors.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: ClientColors.dark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Color _getBillStatusColor(BillStatus status) {
    switch (status) {
      case BillStatus.paid:
        return ClientColors.success;
      case BillStatus.pending:
        return ClientColors.warning;
      case BillStatus.approved:
        return ClientColors.info;
      case BillStatus.disputed:
        return ClientColors.danger;
      case BillStatus.cancelled:
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  Color _getTransactionStatusColor(txn.TransactionStatus status) {
    switch (status) {
      case txn.TransactionStatus.succeeded:
        return ClientColors.success;
      case txn.TransactionStatus.pending:
      case txn.TransactionStatus.processing:
        return ClientColors.warning;
      case txn.TransactionStatus.failed:
      case txn.TransactionStatus.cancelled:
        return ClientColors.danger;
      default:
        return Colors.grey;
    }
  }

  void _showBillDetails(Bill bill) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(24),
          child: ListView(
            controller: controller,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Bill Details',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: ClientColors.dark,
                ),
              ),
              const SizedBox(height: 24),
              _buildDetailRow('Caregiver', bill.caregiverName),
              _buildDetailRow('Booking ID', bill.bookingId.substring(0, 16)),
              _buildDetailRow('Hourly Rate', '\$${bill.hourlyRate.toStringAsFixed(2)}'),
              _buildDetailRow('Duration', '${bill.durationHours.toStringAsFixed(1)} hours'),
              _buildDetailRow('Base Cost', '\$${bill.baseCost.toStringAsFixed(2)}'),
              if (bill.additionalCharges > 0)
                _buildDetailRow('Additional Charges', '\$${bill.additionalCharges.toStringAsFixed(2)}'),
              _buildDetailRow('Subtotal', '\$${bill.subtotal.toStringAsFixed(2)}'),
              _buildDetailRow('Platform Fee (15%)', '\$${bill.platformFee.toStringAsFixed(2)}'),
              const Divider(height: 32),
              _buildDetailRow('Total Amount', '\$${bill.totalAmount.toStringAsFixed(2)}',
                  isHighlight: true),
              const SizedBox(height: 16),
              _buildDetailRow('Status', bill.status.name.toUpperCase()),
              _buildDetailRow('Created', DateFormat('MMM dd, yyyy HH:mm').format(bill.createdAt)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isHighlight ? 18 : 14,
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.w600,
              color: isHighlight ? ClientColors.primary : ClientColors.dark,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _approveBill(Bill bill) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve Bill'),
        content: Text(
          'Do you want to approve this bill for \$${bill.totalAmount.toStringAsFixed(2)}?\n\nPayment will be captured from your saved payment method.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: ClientColors.success,
            ),
            child: const Text('Approve & Pay'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final userId = authProvider.currentUser?.uid;

        if (userId != null) {
          final success = await _billingService.approveBill(
            billId: bill.id,
            clientId: userId,
          );

          if (success && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Bill approved and payment captured successfully'),
                backgroundColor: ClientColors.success,
              ),
            );
            _loadBillingData();
          } else if (mounted) {
            throw Exception('Failed to approve bill');
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.toString()}')),
          );
        }
      }
    }
  }

  Future<void> _disputeBill(Bill bill) async {
    final reasonController = TextEditingController();
    final detailsController = TextEditingController();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Dispute Bill'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please provide a reason for the dispute:'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: detailsController,
              decoration: const InputDecoration(
                labelText: 'Details',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: ClientColors.warning,
            ),
            child: const Text('Submit Dispute'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final userId = authProvider.currentUser?.uid;

        if (userId != null) {
          final success = await _billingService.disputeBill(
            billId: bill.id,
            clientId: userId,
            reason: reasonController.text,
            details: detailsController.text,
          );

          if (success && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Dispute submitted successfully'),
                backgroundColor: ClientColors.success,
              ),
            );
            _loadBillingData();
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.toString()}')),
          );
        }
      }
    }
  }

  void _downloadInvoice(Invoice invoice) {
    if (invoice.pdfUrl != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Opening invoice: ${invoice.invoiceNumber}')),
      );
      // TODO: Implement PDF download/open functionality
      // You can use url_launcher package to open the PDF URL
    }
  }

  void _viewInvoice(Invoice invoice) {
    _showBillDetails(Bill(
      id: invoice.billId,
      bookingId: invoice.bookingId,
      caregiverId: invoice.caregiverId,
      caregiverName: invoice.caregiverName,
      clientId: invoice.clientId,
      clientName: invoice.clientName,
      hourlyRate: 0,
      durationHours: 0,
      baseCost: invoice.subtotal,
      platformFee: invoice.platformFee,
      subtotal: invoice.subtotal,
      totalAmount: invoice.totalAmount,
      status: BillStatus.paid,
      createdAt: invoice.createdAt,
    ));
  }
}
