// withdrawal_screen.dart
import 'package:flutter/material.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String _selectedWithdrawalMethod = 'paypal';
  double _balance = 0.0;

  // Controllers for PayPal form
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _paypalEmailController = TextEditingController();

  // Controllers for Bank form
  final TextEditingController _bankAmountController = TextEditingController();
  final TextEditingController _accountNumberController =
      TextEditingController();
  final TextEditingController _accountNameController = TextEditingController();
  final TextEditingController _swiftCodeController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  String _selectedCountry = 'United States';

  // List of countries for dropdown
  final List<String> _countries = [
    'United States',
    'United Kingdom',
    'Canada',
    'Australia',
    'Germany',
    'France',
    'India',
    'Pakistan',
    'UAE',
    'Saudi Arabia',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    // You can fetch actual balance from API here
    _loadBalance();
  }

  Future<void> _loadBalance() async {
    // Simulate API call to get balance
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() {
      _balance = 0.0; // This would come from your API
    });
  }

  void _processWithdrawal() {
    final amount =
        _selectedWithdrawalMethod == 'paypal'
            ? double.tryParse(_amountController.text) ?? 0
            : double.tryParse(_bankAmountController.text) ?? 0;

    if (amount <= 0) {
      _showSnackBar("Please enter a valid amount", Colors.red);
      return;
    }

    if (amount > _balance) {
      _showSnackBar("Insufficient balance", Colors.red);
      return;
    }

    if (_selectedWithdrawalMethod == 'paypal') {
      if (_paypalEmailController.text.isEmpty ||
          !_paypalEmailController.text.contains('@')) {
        _showSnackBar("Please enter a valid PayPal email", Colors.red);
        return;
      }

      // Process PayPal withdrawal
      _showSnackBar(
        "PayPal withdrawal request for \$$amount submitted!",
        Colors.green,
      );
    } else {
      // Validate bank form
      if (_accountNumberController.text.isEmpty ||
          _accountNameController.text.isEmpty ||
          _swiftCodeController.text.isEmpty ||
          _addressController.text.isEmpty) {
        _showSnackBar("Please fill all bank details", Colors.red);
        return;
      }

      // Process bank withdrawal
      _showSnackBar(
        "Bank withdrawal request for \$$amount submitted!",
        Colors.green,
      );
    }

    // Clear forms after successful submission
    _clearForms();
  }

  void _clearForms() {
    _amountController.clear();
    _paypalEmailController.clear();
    _bankAmountController.clear();
    _accountNumberController.clear();
    _accountNameController.clear();
    _swiftCodeController.clear();
    _addressController.clear();
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Withdraw Funds"),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Balance Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.purple.shade600, Colors.purple.shade800],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const Text(
                      "My Balance",
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "\$$_balance",
                      style: const TextStyle(
                        fontSize: 36,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Available for withdrawal",
                      style: TextStyle(fontSize: 14, color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Withdrawal Method Selection
            const Text(
              "Withdrawal Method",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),

            // Payment Method Cards
            Row(
              children: [
                Expanded(
                  child: _buildPaymentMethodCard(
                    'PayPal',
                    Icons.payment,
                    'paypal',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildPaymentMethodCard(
                    'Bank Transfer',
                    Icons.account_balance,
                    'bank',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Dynamic Form based on selection
            _selectedWithdrawalMethod == 'paypal'
                ? _buildPayPalForm()
                : _buildBankForm(),

            const SizedBox(height: 30),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                onPressed: _processWithdrawal,
                child: const Text(
                  "Request Withdrawal",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Info Text
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Withdrawal requests are processed within 3-5 business days. Minimum withdrawal amount is \$10.",
                      style: TextStyle(fontSize: 12, color: Colors.blue),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodCard(String title, IconData icon, String method) {
    final isSelected = _selectedWithdrawalMethod == method;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedWithdrawalMethod = method;
        });
      },
      child: Card(
        elevation: isSelected ? 4 : 1,
        color: isSelected ? Colors.purple.shade50 : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isSelected ? Colors.purple : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(
                icon,
                size: 32,
                color: isSelected ? Colors.purple : Colors.grey,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.purple : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPayPalForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "PayPal Withdrawal",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),

        // Amount Input
        TextFormField(
          controller: _amountController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: "Amount",
            hintText: "Enter withdrawal amount",
            prefixText: "\$",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.purple),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // PayPal Email
        TextFormField(
          controller: _paypalEmailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: "PayPal Email",
            hintText: "Enter your PayPal email address",
            prefixIcon: const Icon(Icons.email, color: Colors.purple),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.purple),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // PayPal Info
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.orange.shade100),
          ),
          child: const Row(
            children: [
              Icon(Icons.payment, color: Colors.orange, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Make sure your PayPal email is correct and verified. Funds will be sent to this email.",
                  style: TextStyle(fontSize: 12, color: Colors.orange),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBankForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Bank Transfer Withdrawal",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),

        // Amount Input
        TextFormField(
          controller: _bankAmountController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: "Amount",
            hintText: "Enter withdrawal amount",
            prefixText: "\$",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.purple),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Account Number/IBAN
        TextFormField(
          controller: _accountNumberController,
          decoration: InputDecoration(
            labelText: "Account Number / IBAN",
            hintText: "Enter your account number or IBAN",
            prefixIcon: const Icon(Icons.credit_card, color: Colors.purple),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.purple),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Country Dropdown
        DropdownButtonFormField<String>(
          value: _selectedCountry,
          decoration: InputDecoration(
            labelText: "Country",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.purple),
            ),
          ),
          items:
              _countries.map((String country) {
                return DropdownMenuItem<String>(
                  value: country,
                  child: Text(country),
                );
              }).toList(),
          onChanged: (String? newValue) {
            setState(() {
              _selectedCountry = newValue!;
            });
          },
        ),

        const SizedBox(height: 16),

        // Account Name
        TextFormField(
          controller: _accountNameController,
          decoration: InputDecoration(
            labelText: "Account Holder Name",
            hintText: "Enter account holder's full name",
            prefixIcon: const Icon(Icons.person, color: Colors.purple),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.purple),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Swift Code
        TextFormField(
          controller: _swiftCodeController,
          decoration: InputDecoration(
            labelText: "SWIFT/BIC Code",
            hintText: "Enter your bank's SWIFT or BIC code",
            prefixIcon: const Icon(Icons.code, color: Colors.purple),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.purple),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Address
        TextFormField(
          controller: _addressController,
          maxLines: 2,
          decoration: InputDecoration(
            labelText: "Bank Address",
            hintText: "Enter your bank's full address",
            prefixIcon: const Icon(Icons.location_on, color: Colors.purple),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.purple),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Bank Transfer Info
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green.shade100),
          ),
          child: const Row(
            children: [
              Icon(Icons.account_balance, color: Colors.green, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Please ensure all bank details are accurate. Incorrect information may delay or prevent your withdrawal.",
                  style: TextStyle(fontSize: 12, color: Colors.green),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _paypalEmailController.dispose();
    _bankAmountController.dispose();
    _accountNumberController.dispose();
    _accountNameController.dispose();
    _swiftCodeController.dispose();
    _addressController.dispose();
    super.dispose();
  }
}
