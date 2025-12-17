import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../models/booking_model.dart';
import '../dashboard/client_colors.dart';

/// Professional Mock Payment Screen
/// Uses industry-standard test cards (Stripe test mode)
/// This provides a realistic payment flow for development/testing
class MockPaymentScreen extends StatefulWidget {
  final BookingModel booking;
  final double amount;

  const MockPaymentScreen({
    Key? key,
    required this.booking,
    required this.amount,
  }) : super(key: key);

  @override
  State<MockPaymentScreen> createState() => _MockPaymentScreenState();
}

class _MockPaymentScreenState extends State<MockPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Payment method selection
  PaymentMethod _selectedMethod = PaymentMethod.card;
  
  // Card form fields
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _cardHolderController = TextEditingController();
  
  // PayPal mock
  final _paypalEmailController = TextEditingController();
  
  bool _isProcessing = false;
  bool _saveCard = false;

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _cardHolderController.dispose();
    _paypalEmailController.dispose();
    super.dispose();
  }

  // Industry-standard Stripe test cards
  final List<TestCard> _testCards = [
    TestCard(
      name: 'Visa - Success',
      number: '4242 4242 4242 4242',
      expiry: '12/28',
      cvv: '123',
      result: PaymentResult.success,
    ),
    TestCard(
      name: 'Visa - Declined',
      number: '4000 0000 0000 0002',
      expiry: '12/28',
      cvv: '123',
      result: PaymentResult.declined,
    ),
    TestCard(
      name: 'Mastercard - Success',
      number: '5555 5555 5555 4444',
      expiry: '12/28',
      cvv: '123',
      result: PaymentResult.success,
    ),
    TestCard(
      name: 'Visa - Insufficient Funds',
      number: '4000 0000 0000 9995',
      expiry: '12/28',
      cvv: '123',
      result: PaymentResult.insufficientFunds,
    ),
    TestCard(
      name: 'AmEx - Success',
      number: '3782 822463 10005',
      expiry: '12/28',
      cvv: '1234',
      result: PaymentResult.success,
    ),
  ];

  void _autofillTestCard(TestCard card) {
    setState(() {
      _cardNumberController.text = card.number;
      _expiryController.text = card.expiry;
      _cvvController.text = card.cvv;
      _cardHolderController.text = 'Test User';
    });
  }

  Future<void> _processPayment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isProcessing = true);

    // Simulate payment processing (2-3 seconds)
    await Future.delayed(const Duration(seconds: 2));

    if (_selectedMethod == PaymentMethod.card) {
      await _processCardPayment();
    } else {
      await _processPayPalPayment();
    }
  }

  Future<void> _processCardPayment() async {
    // Check if using test card
    final cardNumber = _cardNumberController.text.replaceAll(' ', '');
    final testCard = _testCards.firstWhere(
      (card) => card.number.replaceAll(' ', '') == cardNumber,
      orElse: () => TestCard(
        name: 'Unknown',
        number: cardNumber,
        expiry: '',
        cvv: '',
        result: PaymentResult.success, // Default to success for unknown cards
      ),
    );

    setState(() => _isProcessing = false);

    if (testCard.result == PaymentResult.success) {
      await _showSuccessDialog();
    } else if (testCard.result == PaymentResult.declined) {
      _showErrorDialog('Payment Declined', 'Your card was declined. Please try another payment method.');
    } else if (testCard.result == PaymentResult.insufficientFunds) {
      _showErrorDialog('Insufficient Funds', 'Your card has insufficient funds. Please use another card.');
    }
  }

  Future<void> _processPayPalPayment() async {
    setState(() => _isProcessing = false);
    
    // PayPal mock always succeeds
    await _showSuccessDialog();
  }

  Future<void> _showSuccessDialog() async {
    // Update booking status in Firestore
    try {
      final firestore = FirebaseFirestore.instance;
      
      // Find the booking document by bookingRequestId
      final bookingsQuery = await firestore
          .collection('bookings')
          .where('bookingRequestId', isEqualTo: widget.booking.bookingRequestId)
          .limit(1)
          .get();
      
      if (bookingsQuery.docs.isNotEmpty) {
        final bookingDoc = bookingsQuery.docs.first;
        
        // Update booking status to confirmed and paid
        await bookingDoc.reference.update({
          'status': 'confirmed',
          'paymentStatus': 'paid',
          'paymentDate': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        
        print('✅ Booking ${widget.booking.bookingRequestId} updated to confirmed');
      }
    } catch (e) {
      print('❌ Error updating booking status: $e');
    }
    
    if (!mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle,
                color: Colors.green.shade600,
                size: 64,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Payment Successful!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Amount: \$${widget.amount.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Booking ID: ${widget.booking.bookingRequestId}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'A confirmation email has been sent.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context, true); // Return to bookings with success
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ClientColors.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade600),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Complete Payment'),
        backgroundColor: ClientColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Payment summary header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: ClientColors.primary,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  const Text(
                    'Amount to Pay',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '\$${widget.amount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Booking: ${widget.booking.bookingRequestId}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Payment method selection
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select Payment Method',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  Row(
                    children: [
                      Expanded(
                        child: _PaymentMethodCard(
                          icon: Icons.credit_card,
                          label: 'Card',
                          isSelected: _selectedMethod == PaymentMethod.card,
                          onTap: () => setState(() => _selectedMethod = PaymentMethod.card),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _PaymentMethodCard(
                          icon: Icons.account_balance_wallet,
                          label: 'PayPal',
                          isSelected: _selectedMethod == PaymentMethod.paypal,
                          onTap: () => setState(() => _selectedMethod = PaymentMethod.paypal),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Payment form
                  Form(
                    key: _formKey,
                    child: _selectedMethod == PaymentMethod.card
                        ? _buildCardForm()
                        : _buildPayPalForm(),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Pay button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isProcessing ? null : _processPayment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ClientColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isProcessing
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              'Pay \$${widget.amount.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Security notice
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.lock, size: 16, color: Colors.grey.shade600),
                      const SizedBox(width: 8),
                      Text(
                        'Secure payment powered by Stripe',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Test cards helper
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.blue.shade700),
                  const SizedBox(width: 8),
                  Text(
                    'Test Cards (Development Mode)',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _testCards.map((card) {
                  return InkWell(
                    onTap: () => _autofillTestCard(card),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.blue.shade300),
                      ),
                      child: Text(
                        card.name,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 20),
        
        // Card number
        TextFormField(
          controller: _cardNumberController,
          decoration: InputDecoration(
            labelText: 'Card Number',
            hintText: '4242 4242 4242 4242',
            prefixIcon: const Icon(Icons.credit_card),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            _CardNumberFormatter(),
          ],
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter card number';
            }
            if (value.replaceAll(' ', '').length < 13) {
              return 'Invalid card number';
            }
            return null;
          },
        ),
        
        const SizedBox(height: 16),
        
        Row(
          children: [
            // Expiry date
            Expanded(
              child: TextFormField(
                controller: _expiryController,
                decoration: InputDecoration(
                  labelText: 'Expiry',
                  hintText: 'MM/YY',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  _ExpiryDateFormatter(),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Required';
                  }
                  if (value.length < 5) {
                    return 'Invalid';
                  }
                  return null;
                },
              ),
            ),
            
            const SizedBox(width: 16),
            
            // CVV
            Expanded(
              child: TextFormField(
                controller: _cvvController,
                decoration: InputDecoration(
                  labelText: 'CVV',
                  hintText: '123',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Required';
                  }
                  if (value.length < 3) {
                    return 'Invalid';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Card holder name
        TextFormField(
          controller: _cardHolderController,
          decoration: InputDecoration(
            labelText: 'Cardholder Name',
            hintText: 'John Doe',
            prefixIcon: const Icon(Icons.person),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          textCapitalization: TextCapitalization.words,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter cardholder name';
            }
            return null;
          },
        ),
        
        const SizedBox(height: 16),
        
        // Save card checkbox
        CheckboxListTile(
          value: _saveCard,
          onChanged: (value) => setState(() => _saveCard = value ?? false),
          title: const Text('Save card for future payments'),
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
        ),
      ],
    );
  }

  Widget _buildPayPalForm() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue.shade700),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'You will be redirected to PayPal to complete your payment.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.blue.shade700,
                  ),
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 20),
        
        TextFormField(
          controller: _paypalEmailController,
          decoration: InputDecoration(
            labelText: 'PayPal Email',
            hintText: 'your.email@example.com',
            prefixIcon: const Icon(Icons.email),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your PayPal email';
            }
            if (!value.contains('@')) {
              return 'Invalid email address';
            }
            return null;
          },
        ),
      ],
    );
  }
}

class _PaymentMethodCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _PaymentMethodCard({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? ClientColors.primary.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? ClientColors.primary : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? ClientColors.primary : Colors.grey.shade600,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? ClientColors.primary : Colors.grey.shade700,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Card number formatter (adds spaces every 4 digits)
class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(' ', '');
    final buffer = StringBuffer();
    
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      if ((i + 1) % 4 == 0 && i + 1 != text.length) {
        buffer.write(' ');
      }
    }
    
    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.length),
    );
  }
}

// Expiry date formatter (MM/YY)
class _ExpiryDateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll('/', '');
    
    if (text.length > 4) {
      return oldValue;
    }
    
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      if (i == 1 && text.length > 2) {
        buffer.write('/');
      }
    }
    
    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.length),
    );
  }
}

enum PaymentMethod { card, paypal }

enum PaymentResult { success, declined, insufficientFunds }

class TestCard {
  final String name;
  final String number;
  final String expiry;
  final String cvv;
  final PaymentResult result;

  TestCard({
    required this.name,
    required this.number,
    required this.expiry,
    required this.cvv,
    required this.result,
  });
}
