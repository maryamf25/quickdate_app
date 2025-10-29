import 'package:flutter/material.dart';
import 'social_login_service.dart';
import 'package:intl/intl.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  List<Map<String, dynamic>> _transactions = [];
  bool _isLoading = true;
  String? _errorMessage;
  final int _limit = 20;
  int _offset = 0;
  bool _hasMore = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchTransactions();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      if (_hasMore && !_isLoading) {
        _offset += _limit;
        _fetchTransactions(isLoadMore: true);
      }
    }
  }

  Future<void> _fetchTransactions({bool isLoadMore = false}) async {
    if (!isLoadMore) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      debugPrint('📱 Fetching transactions... Offset: $_offset, Limit: $_limit');

      // Check for access token first
      final token = await SocialLoginService.getAccessToken();
      if (token == null) {
        setState(() {
          _errorMessage = "Access token not found. Please login again.";
          _isLoading = false;
        });
        return;
      }

      // Check for user data
      final userData = await SocialLoginService.getUserData();
      if (userData == null || userData['id'] == null) {
        setState(() {
          _errorMessage = "User data not found. Please login again.";
          _isLoading = false;
        });
        return;
      }

      debugPrint('🔑 Token Status: Found (${token.length} chars)');
      debugPrint('👤 User Data: ${userData['id']} - ${userData['username']}');

      final response = await SocialLoginService.getTransactions(
        limit: _limit,
        offset: _offset,
      );

      debugPrint('📋 Full response: $response');

      if (response != null) {
        debugPrint('✅ Response received with keys: ${response.keys.toList()}');

        if (response['code'] == 200) {
          // Handle the data
          List<Map<String, dynamic>> newTransactions = [];

          if (response['data'] != null) {
            if (response['data'] is List) {
              final List<dynamic> responseData = response['data'] as List<dynamic>;
              newTransactions = responseData
                  .map((item) => Map<String, dynamic>.from(item as Map))
                  .toList();
              debugPrint('📊 Parsed ${newTransactions.length} transactions from API');

              // Log first transaction for debugging
              if (newTransactions.isNotEmpty) {
                debugPrint('📄 Sample transaction: ${newTransactions.first}');
              }
            } else {
              debugPrint('⚠️ Data is not a list: ${response['data'].runtimeType}');
            }
          } else {
            debugPrint('ℹ️ No data field in response');
          }

          setState(() {
            if (isLoadMore) {
              _transactions.addAll(newTransactions);
            } else {
              _transactions = newTransactions;
            }
            _hasMore = newTransactions.length >= _limit;
            _isLoading = false;
            _errorMessage = null;
          });

          debugPrint('💰 Total transactions: ${_transactions.length}');
        } else {
          // Handle error response
          setState(() {
            if (!isLoadMore) _transactions = [];
            _hasMore = false;
            _isLoading = false;
            _errorMessage = response['message'] ?? 'API returned error code: ${response['code']}';
          });
          debugPrint('❌ API error: ${response['code']} - ${response['message']}');
        }
      } else {
        setState(() {
          if (!isLoadMore) _transactions = [];
          _errorMessage = 'Failed to fetch transactions - no response';
          _isLoading = false;
        });
        debugPrint('❌ No response received from API');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error fetching transactions: $e');
      debugPrint('Stack trace: $stackTrace');
      setState(() {
        if (!isLoadMore) _transactions = [];
        _errorMessage = 'Error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return 'N/A';
    try {
      final DateTime date = DateTime.parse(dateString);
      return DateFormat('MMM dd, yyyy - hh:mm a').format(date);
    } catch (e) {
      return dateString;
    }
  }

  String _formatAmount(dynamic amount) {
    if (amount == null) return '\$0.00';
    try {
      final double value = double.parse(amount.toString());
      return '\$${value.toStringAsFixed(2)}';
    } catch (e) {
      return '\$${amount.toString()}';
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case '1':
      case 'approved':
      case 'completed':
        return Colors.green;
      case '2':
      case 'rejected':
      case 'failed':
        return Colors.red;
      case '0':
      case 'pending':
      default:
        return Colors.orange;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case '1':
      case 'approved':
      case 'completed':
        return 'Approved';
      case '2':
      case 'rejected':
      case 'failed':
        return 'Rejected';
      case '0':
      case 'pending':
      default:
        return 'Pending';
    }
  }

  Widget _buildTransactionCard(Map<String, dynamic> transaction) {
    final String type = transaction['type']?.toString() ?? 'Unknown';
    final dynamic amount = transaction['amount'];
    final String date = transaction['date']?.toString() ?? '';
    final String via = transaction['via']?.toString() ?? 'Unknown';
    final String proPlan = transaction['pro_plan']?.toString() ?? '0';
    final String creditAmount = transaction['credit_amount']?.toString() ?? '0';

    String displayTitle = type;
    String displayAmount = _formatAmount(amount);
    Color cardColor = Colors.purple;

    // Customize display based on transaction type
    if (type.toUpperCase() == 'CREDITS') {
      displayTitle = 'Credits Purchase';
      displayAmount = '+$creditAmount Credits (\$${amount})';
      cardColor = Colors.green;
    } else if (type.toUpperCase() == 'PRO') {
      displayTitle = 'Pro Membership';
      String planType = '';
      switch (proPlan) {
        case '1':
          planType = 'Weekly';
          break;
        case '2':
          planType = 'Monthly';
          break;
        case '3':
          planType = 'Yearly';
          break;
        case '4':
          planType = 'Lifetime';
          break;
      }
      if (planType.isNotEmpty) {
        displayTitle = '$planType Pro Plan';
      }
      displayAmount = '-\$${amount}';
      cardColor = Colors.purple;
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Icon
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: cardColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Icon(
                  Icons.account_balance_wallet,
                  color: cardColor,
                  size: 28,
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Transaction Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayTitle,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Via: $via • ${_formatDate(date)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  if (type.toUpperCase() == 'CREDITS' && creditAmount != '0')
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '$creditAmount Credits Added',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.green,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Amount
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  displayAmount,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: cardColor,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Completed',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.green,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction History'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _offset = 0;
          _hasMore = true;
          await _fetchTransactions();
        },
        child: _isLoading && _transactions.isEmpty
            ? const Center(
                child: CircularProgressIndicator(
                  color: Colors.purple,
                ),
              )
            : _errorMessage != null && _transactions.isEmpty
                ? _buildErrorState()
                : _transactions.isEmpty
                    ? _buildEmptyState()
                    : _buildTransactionsList(),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 20),
            Text(
              'Error Loading Transactions',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _errorMessage ?? 'Unknown error occurred',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                _offset = 0;
                _hasMore = true;
                _fetchTransactions();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long,
              size: 80,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 20),
            Text(
              'No Transactions Yet',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Your transaction history will appear here once you make purchases or payments.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionsList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      itemCount: _transactions.length + (_hasMore && _isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _transactions.length) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(
              child: CircularProgressIndicator(
                color: Colors.purple,
              ),
            ),
          );
        }

        return _buildTransactionCard(_transactions[index]);
      },
    );
  }
}
