import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/transaction_provider.dart';
import '../../models/transaction.dart';

class TransactionsTab extends StatefulWidget {
  const TransactionsTab({super.key});

  @override
  State<TransactionsTab> createState() => _TransactionsTabState();
}

class _TransactionsTabState extends State<TransactionsTab> {
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    // Using Future.microtask to ensure this doesn't run during build phase
    Future.microtask(() => _loadTransactions());
  }
  
  Future<void> _loadTransactions() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });
    
    final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
    await transactionProvider.loadTransactions();
    
    if (!mounted) return;
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
        elevation: 0,
        actions: [
          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTransactions,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadTransactions,
              child: _buildTransactionsList(),
            ),
    );
  }
  
  Widget _buildTransactionsList() {
    final transactionProvider = Provider.of<TransactionProvider>(context);
    final transactions = transactionProvider.transactions;
    final currencyFormat = NumberFormat.currency(locale: 'id', symbol: 'Rp', decimalDigits: 0);
    
    if (transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            const Text(
              'No transactions yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your transactions will appear here',
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      itemCount: transactions.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final transaction = transactions[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: transaction.type == TransactionType.income
                  ? Colors.green[100]
                  : Colors.red[100],
              child: Icon(
                transaction.type == TransactionType.income
                    ? Icons.arrow_downward
                    : Icons.arrow_upward,
                color: transaction.type == TransactionType.income
                    ? Colors.green
                    : Colors.red,
              ),
            ),
            title: Text(
              transaction.notes ?? 'Transaction',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              DateFormat('MMM dd, yyyy').format(transaction.date),
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
            trailing: Text(
              (transaction.type == TransactionType.income ? '+ ' : '- ') +
                  currencyFormat.format(transaction.amount),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: transaction.type == TransactionType.income
                    ? Colors.green
                    : Colors.red,
              ),
            ),
            onTap: () => _showTransactionDetails(transaction),
          ),
        );
      },
    );
  }
  
  void _showTransactionDetails(Transaction transaction) {
    final currencyFormat = NumberFormat.currency(locale: 'id', symbol: 'Rp', decimalDigits: 0);
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Center(
              child: Text(
                'Transaction Details',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Type
            Row(
              children: [
                const Icon(Icons.category_outlined, color: Colors.grey),
                const SizedBox(width: 12),
                const Text('Type:', style: TextStyle(color: Colors.grey)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: transaction.type == TransactionType.income
                        ? Colors.green[50]
                        : Colors.red[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    transaction.type == TransactionType.income
                        ? 'Income'
                        : 'Expense',
                    style: TextStyle(
                      color: transaction.type == TransactionType.income
                          ? Colors.green
                          : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            
            const Divider(height: 24),
            
            // Amount
            Row(
              children: [
                const Icon(Icons.monetization_on_outlined, color: Colors.grey),
                const SizedBox(width: 12),
                const Text('Amount:', style: TextStyle(color: Colors.grey)),
                const Spacer(),
                Text(
                  currencyFormat.format(transaction.amount),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            
            const Divider(height: 24),
            
            // Date
            Row(
              children: [
                const Icon(Icons.calendar_today_outlined, color: Colors.grey),
                const SizedBox(width: 12),
                const Text('Date:', style: TextStyle(color: Colors.grey)),
                const Spacer(),
                Text(
                  DateFormat('EEEE, MMM d, yyyy').format(transaction.date),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            const Divider(height: 24),
            
            // Notes/Description
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.description_outlined, color: Colors.grey),
                const SizedBox(width: 12),
                const Text('Notes:', style: TextStyle(color: Colors.grey)),
                const Spacer(),
                Flexible(
                  child: Text(
                    transaction.notes ?? 'No notes',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // Delete button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  _confirmDeleteTransaction(transaction);
                },
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                label: const Text('Delete Transaction', style: TextStyle(color: Colors.red)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _confirmDeleteTransaction(Transaction transaction) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Transaction'),
        content: const Text('Are you sure you want to delete this transaction? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close bottom sheet
              
              // Delete transaction
              final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
              await transactionProvider.deleteTransaction(transaction.id);
              
              // Show success message
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Transaction deleted successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
} 