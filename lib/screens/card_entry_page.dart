// lib/screens/card_entry_page.dart
import 'package:flutter/material.dart';

class CardEntryPage extends StatefulWidget {
  final String planName;
  final int amount;

  const CardEntryPage({Key? key, required this.planName, required this.amount}) : super(key: key);

  @override
  State<CardEntryPage> createState() => _CardEntryPageState();
}

class _CardEntryPageState extends State<CardEntryPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _expiryController = TextEditingController(); // MM/YY
  final TextEditingController _cvvController = TextEditingController();
  final TextEditingController _postcodeController = TextEditingController();
  bool _submitting = false;

  void _onSubmit() {
    if (!_formKey.currentState!.validate()) return;
    // Parse expiry
    final expiry = _expiryController.text.trim();
    String expMonth = '';
    String expYear = '';
    if (expiry.contains('/')) {
      final parts = expiry.split('/');
      expMonth = parts[0].padLeft(2, '0');
      expYear = parts[1];
      if (expYear.length == 2) expYear = '20' + expYear;
    }

    final cardData = {
      'card_number': _cardNumberController.text.trim().replaceAll(' ', ''),
      'cvv': _cvvController.text.trim(),
      'expiry_month': expMonth,
      'expiry_year': expYear,
      'postal_code': _postcodeController.text.trim(),
      'card_holder_name': _nameController.text.trim(),
    };

    // Return the collected card data to the caller
    Navigator.of(context).pop(cardData);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Enter Card Details - ${widget.planName}'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Name on card'),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Enter name' : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _cardNumberController,
                  decoration: const InputDecoration(labelText: 'Card number', hintText: '4242 4242 4242 4242'),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Enter card number';
                    final digits = v.replaceAll(' ', '');
                    if (digits.length < 12) return 'Invalid card number';
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _expiryController,
                        decoration: const InputDecoration(labelText: 'Expiry (MM/YY)'),
                        keyboardType: TextInputType.datetime,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Enter expiry';
                          if (!v.contains('/')) return 'Use MM/YY';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _cvvController,
                        decoration: const InputDecoration(labelText: 'CVV'),
                        keyboardType: TextInputType.number,
                        obscureText: true,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Enter CVV';
                          if (v.trim().length < 3) return 'Invalid CVV';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _postcodeController,
                  decoration: const InputDecoration(labelText: 'Postal code'),
                  keyboardType: TextInputType.text,
                  validator: (v) => v == null || v.trim().isEmpty ? 'Enter postal code' : null,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _submitting ? null : _onSubmit,
                  child: const Text('Continue'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

