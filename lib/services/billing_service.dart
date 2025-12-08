import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import '../models/invoice_model.dart';
import '../models/bill_model.dart';
import '../models/transaction_model.dart' as txn;
import '../models/booking_model.dart' show ServiceType;
import '../models/notification_model.dart';
import 'payment_service.dart';
import 'notification_service.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:typed_data';

class BillingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final PaymentService _paymentService = PaymentService();
  final NotificationService _notificationService = NotificationService();

  /// Auto-generate bill after session completion
  Future<String?> autoGenerateBill({
    required String bookingId,
    required String caregiverId,
    required String caregiverName,
    required String clientId,
    required String clientName,
    required double hourlyRate,
    required int durationHours,
    required ServiceType serviceType,
    Map<String, dynamic>? additionalCharges,
  }) async {
    try {
      // Calculate costs
      final baseCost = hourlyRate * durationHours;
      double extraCharges = 0.0;

      if (additionalCharges != null) {
        extraCharges = additionalCharges.values
            .fold(0.0, (sum, value) => sum + (value as num).toDouble());
      }

      final subtotal = baseCost + extraCharges;
      final platformFee = subtotal * 0.15; // 15% platform fee
      final finalCost = subtotal + platformFee;

      // Create bill
      final bill = Bill(
        id: '',
        bookingId: bookingId,
        caregiverId: caregiverId,
        caregiverName: caregiverName,
        clientId: clientId,
        clientName: clientName,
        hourlyRate: hourlyRate,
        durationHours: durationHours.toDouble(),
        baseCost: baseCost,
        additionalCharges: extraCharges,
        subtotal: subtotal,
        platformFee: platformFee,
        totalAmount: finalCost,
        status: BillStatus.pending,
        createdAt: DateTime.now(),
      );

      final docRef = await _firestore.collection('bills').add(bill.toMap());

      // Send notification to client
      await _notificationService.createNotification(
        NotificationModel(
          id: '',
          userId: clientId,
          type: NotificationType.general,
          title: 'Bill Generated',
          message: 'Your bill for ${serviceType.name} session is ready for approval.',
          data: {'billId': docRef.id},
          createdAt: DateTime.now(),
        ),
      );

      return docRef.id;
    } catch (e) {
      print('Error auto-generating bill: $e');
      return null;
    }
  }

  /// Client approves bill
  Future<bool> approveBill({
    required String billId,
    required String clientId,
    String? notes,
  }) async {
    try {
      await _firestore.collection('bills').doc(billId).update({
        'status': BillStatus.approved.name,
        'clientApprovedAt': FieldValue.serverTimestamp(),
        'approvalNotes': notes,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Get bill details
      final billDoc = await _firestore.collection('bills').doc(billId).get();
      final bill = Bill.fromMap(billDoc.data()!, billDoc.id);

      // Trigger auto-payment capture
      await _autoCapturPayment(bill);

      return true;
    } catch (e) {
      print('Error approving bill: $e');
      return false;
    }
  }

  /// Auto-capture payment after client approval
  Future<bool> _autoCapturPayment(Bill bill) async {
    try {
      // Get pending transaction for this bill
      final transactionSnapshot = await _firestore
          .collection('transactions')
          .where('billId', isEqualTo: bill.id)
          .where('status', isEqualTo: txn.TransactionStatus.pending.name)
          .limit(1)
          .get();

      if (transactionSnapshot.docs.isEmpty) {
        print('No pending transaction found for bill ${bill.id}');
        return false;
      }

      final transaction = txn.Transaction.fromMap(
        transactionSnapshot.docs.first.data(),
        transactionSnapshot.docs.first.id,
      );

      // Capture the payment
      final captured = await _paymentService.capturePaymentAfterApproval(
        transactionId: transaction.id,
        paymentIntentId: transaction.gatewayPaymentIntentId!,
      );

      if (captured) {
        // Update bill status
        await _firestore.collection('bills').doc(bill.id).update({
          'status': BillStatus.paid.name,
          'paidAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Credit caregiver wallet
        final wallet = await _paymentService.getOrCreateWallet(
          userId: bill.caregiverId,
          userName: bill.caregiverName,
          userRole: 'caregiver',
        );

        if (wallet != null) {
          await _paymentService.creditWallet(
            walletId: wallet.id,
            amount: transaction.netAmount,
            transactionId: transaction.id,
            description: 'Payment for booking ${bill.bookingId}',
          );
        }

        // Send notifications
        await _notificationService.createNotification(
          NotificationModel(
            id: '',
            userId: bill.clientId,
            type: NotificationType.paymentReceived,
            title: 'Payment Successful',
            message: 'Your payment of \$${bill.totalAmount.toStringAsFixed(2)} has been processed.',
            data: {'billId': bill.id},
            createdAt: DateTime.now(),
          ),
        );

        await _notificationService.createNotification(
          NotificationModel(
            id: '',
            userId: bill.caregiverId,
            type: NotificationType.paymentReceived,
            title: 'Payment Received',
            message: 'You have received \$${transaction.netAmount.toStringAsFixed(2)} for your service.',
            data: {'billId': bill.id},
            createdAt: DateTime.now(),
          ),
        );

        return true;
      }

      return false;
    } catch (e) {
      print('Error auto-capturing payment: $e');
      return false;
    }
  }

  /// Client disputes bill
  Future<bool> disputeBill({
    required String billId,
    required String clientId,
    required String reason,
    String? details,
  }) async {
    try {
      await _firestore.collection('bills').doc(billId).update({
        'status': BillStatus.disputed.name,
        'disputeReason': reason,
        'disputeDetails': details,
        'disputedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Get bill details
      final billDoc = await _firestore.collection('bills').doc(billId).get();
      final bill = Bill.fromMap(billDoc.data()!, billDoc.id);

      // Notify admin
      await _notificationService.createNotification(
        NotificationModel(
          id: '',
          userId: 'admin',
          type: NotificationType.general,
          title: 'Bill Disputed',
          message: 'Bill ${billId.substring(0, 8)} has been disputed by ${bill.clientName}',
          data: {'billId': billId, 'reason': reason},
          createdAt: DateTime.now(),
        ),
      );

      // Notify caregiver
      await _notificationService.createNotification(
        NotificationModel(
          id: '',
          userId: bill.caregiverId,
          type: NotificationType.general,
          title: 'Bill Disputed',
          message: 'Your bill has been disputed. Admin will review.',
          data: {'billId': billId},
          createdAt: DateTime.now(),
        ),
      );

      return true;
    } catch (e) {
      print('Error disputing bill: $e');
      return false;
    }
  }

  /// Generate invoice from bill
  Future<String?> generateInvoice({
    required String billId,
  }) async {
    try {
      final billDoc = await _firestore.collection('bills').doc(billId).get();
      final bill = Bill.fromMap(billDoc.data()!, billDoc.id);

      // Generate invoice number
      final invoiceNumber = await _generateInvoiceNumber();

      // Get client details
      final clientDoc = await _firestore.collection('users').doc(bill.clientId).get();
      final clientEmail = clientDoc.data()?['email'] ?? '';
      final clientPhone = clientDoc.data()?['phoneNumber'];

      // Create line items
      final lineItems = <InvoiceLineItem>[
        InvoiceLineItem(
          description: 'Booking ${bill.bookingId} - ${bill.durationHours} hours',
          quantity: bill.durationHours,
          unitPrice: bill.hourlyRate,
          amount: bill.baseCost,
        ),
        if (bill.additionalCharges > 0)
          InvoiceLineItem(
            description: 'Additional charges',
            quantity: 1,
            unitPrice: bill.additionalCharges,
            amount: bill.additionalCharges,
          ),
        InvoiceLineItem(
          description: 'Platform fee (15%)',
          quantity: 1,
          unitPrice: bill.platformFee,
          amount: bill.platformFee,
        ),
      ];

      final invoice = Invoice(
        id: '',
        invoiceNumber: invoiceNumber,
        status: bill.status == BillStatus.paid
            ? InvoiceStatus.paid
            : InvoiceStatus.sent,
        bookingId: bill.bookingId,
        billId: bill.id,
        clientId: bill.clientId,
        clientName: bill.clientName,
        clientEmail: clientEmail,
        clientPhone: clientPhone,
        caregiverId: bill.caregiverId,
        caregiverName: bill.caregiverName,
        subtotal: bill.subtotal,
        platformFee: bill.platformFee,
        processingFee: 0.0,
        totalAmount: bill.totalAmount,
        paidAmount: bill.status == BillStatus.paid ? bill.totalAmount : 0.0,
        balanceDue: bill.status == BillStatus.paid ? 0.0 : bill.totalAmount,
        lineItems: lineItems,
        issueDate: DateTime.now(),
        dueDate: DateTime.now().add(const Duration(days: 7)),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final docRef = await _firestore.collection('invoices').add(invoice.toMap());

      // Generate PDF
      await _generateInvoicePDF(invoice.copyWith(id: docRef.id));

      // Send email (implement with your email service)
      // await _sendInvoiceEmail(invoice);

      return docRef.id;
    } catch (e) {
      print('Error generating invoice: $e');
      return null;
    }
  }

  /// Generate invoice number
  Future<String> _generateInvoiceNumber() async {
    final year = DateTime.now().year;
    final month = DateTime.now().month.toString().padLeft(2, '0');

    final snapshot = await _firestore
        .collection('invoices')
        .orderBy('createdAt', descending: true)
        .limit(1)
        .get();

    int sequence = 1;
    if (snapshot.docs.isNotEmpty) {
      final lastInvoice = Invoice.fromMap(snapshot.docs.first.data(), snapshot.docs.first.id);
      final lastSequence = int.tryParse(lastInvoice.invoiceNumber.split('-').last) ?? 0;
      sequence = lastSequence + 1;
    }

    return 'INV-$year$month-${sequence.toString().padLeft(6, '0')}';
  }

  /// Generate invoice PDF
  Future<bool> _generateInvoicePDF(Invoice invoice) async {
    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                pw.Text(
                  'INVOICE',
                  style: pw.TextStyle(
                    fontSize: 32,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 20),

                // Invoice details
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Invoice Number: ${invoice.invoiceNumber}'),
                        pw.Text('Issue Date: ${invoice.issueDate.toString().split(' ')[0]}'),
                        pw.Text('Due Date: ${invoice.dueDate.toString().split(' ')[0]}'),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('CareMatch Platform'),
                        pw.Text('contact@carematch.com'),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 30),

                // Bill to
                pw.Text('Bill To:',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Text(invoice.clientName),
                pw.Text(invoice.clientEmail),
                if (invoice.clientPhone != null) pw.Text(invoice.clientPhone!),
                pw.SizedBox(height: 30),

                // Line items table
                pw.Table.fromTextArray(
                  headers: ['Description', 'Quantity', 'Unit Price', 'Amount'],
                  data: invoice.lineItems.map((item) {
                    return [
                      item.description,
                      item.quantity.toStringAsFixed(1),
                      '\$${item.unitPrice.toStringAsFixed(2)}',
                      '\$${item.amount.toStringAsFixed(2)}',
                    ];
                  }).toList(),
                ),
                pw.SizedBox(height: 20),

                // Totals
                pw.Align(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Container(
                    width: 200,
                    child: pw.Column(
                      children: [
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('Subtotal:'),
                            pw.Text('\$${invoice.subtotal.toStringAsFixed(2)}'),
                          ],
                        ),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('Total:',
                                style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                            pw.Text('\$${invoice.totalAmount.toStringAsFixed(2)}',
                                style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                          ],
                        ),
                        if (invoice.paidAmount > 0)
                          pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text('Paid:'),
                              pw.Text('\$${invoice.paidAmount.toStringAsFixed(2)}'),
                            ],
                          ),
                        if (invoice.balanceDue > 0)
                          pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text('Balance Due:',
                                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                              pw.Text('\$${invoice.balanceDue.toStringAsFixed(2)}',
                                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      );

      // Save to Firebase Storage
      final bytes = await pdf.save();
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('invoices/${invoice.invoiceNumber}.pdf');

      await storageRef.putData(
        Uint8List.fromList(bytes),
        SettableMetadata(contentType: 'application/pdf'),
      );

      final downloadUrl = await storageRef.getDownloadURL();

      // Update invoice with PDF URL
      await _firestore.collection('invoices').doc(invoice.id).update({
        'pdfUrl': downloadUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      print('Error generating invoice PDF: $e');
      return false;
    }
  }

  /// Get bills for client
  Stream<List<Bill>> getClientBills(String clientId) {
    return _firestore
        .collection('bills')
        .where('clientId', isEqualTo: clientId)
        .orderBy('generatedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Bill.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Get bills for caregiver
  Stream<List<Bill>> getCaregiverBills(String caregiverId) {
    return _firestore
        .collection('bills')
        .where('caregiverId', isEqualTo: caregiverId)
        .orderBy('generatedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Bill.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Get invoices for client
  Stream<List<Invoice>> getClientInvoices(String clientId) {
    return _firestore
        .collection('invoices')
        .where('clientId', isEqualTo: clientId)
        .orderBy('issueDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Invoice.fromMap(doc.data(), doc.id))
            .toList());
  }
}

// Extension to add copyWith method to Invoice
extension InvoiceCopyWith on Invoice {
  Invoice copyWith({String? id}) {
    return Invoice(
      id: id ?? this.id,
      invoiceNumber: invoiceNumber,
      status: status,
      bookingId: bookingId,
      billId: billId,
      clientId: clientId,
      clientName: clientName,
      clientEmail: clientEmail,
      clientPhone: clientPhone,
      caregiverId: caregiverId,
      caregiverName: caregiverName,
      subtotal: subtotal,
      platformFee: platformFee,
      processingFee: processingFee,
      discount: discount,
      tax: tax,
      totalAmount: totalAmount,
      paidAmount: paidAmount,
      balanceDue: balanceDue,
      currency: currency,
      lineItems: lineItems,
      transactionIds: transactionIds,
      paidAt: paidAt,
      paymentMethod: paymentMethod,
      pdfUrl: pdfUrl,
      emailSent: emailSent,
      emailSentAt: emailSentAt,
      emailRecipient: emailRecipient,
      issueDate: issueDate,
      dueDate: dueDate,
      createdAt: createdAt,
      updatedAt: updatedAt,
      notes: notes,
      metadata: metadata,
    );
  }
}
