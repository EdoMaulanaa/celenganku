import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/savings_provider.dart';
import '../../models/transaction.dart';

class TransactionsTab extends StatefulWidget {
  const TransactionsTab({super.key});

  @override
  State<TransactionsTab> createState() => TransactionsTabState();
}

class TransactionsTabState extends State<TransactionsTab> with TickerProviderStateMixin {
  bool _isLoading = false;
  late AnimationController _animationController;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    // Inisialisasi format tanggal Bahasa Indonesia
    initializeDateFormatting('id_ID', null);
    
    // Using Future.microtask to ensure this doesn't run during build phase
    Future.microtask(() {
      // Ensure we're loading transactions from all pots by setting currentPotId to null
      final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
      transactionProvider.setCurrentPotId(null);
      _loadTransactions();
      _animationController.forward();
    });
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  // Method to reset animation when returning to this tab
  void resetAnimation() {
    _animationController.reset();
    _animationController.forward();
    
    // Ensure we're showing all transactions when tab is reset
    Future.microtask(() {
      final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
      transactionProvider.setCurrentPotId(null);
      _loadTransactions();
    });
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
    
    // Start animation after loading
    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final savingsProvider = Provider.of<SavingsProvider>(context);
    final transactionProvider = Provider.of<TransactionProvider>(context);
    final String? currentPotId = transactionProvider.currentPotId;
    final String filterText = currentPotId != null 
        ? 'Filter: ${savingsProvider.getSavingsPotById(currentPotId)?.name ?? 'Tidak diketahui'}'
        : 'Semua Transaksi';
        
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Transaksi'),
            if (currentPotId != null)
              Text(
                filterText,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.normal,
                  color: Colors.white70,
                ),
              ),
          ],
        ),
        elevation: 0,
        actions: [
          // Filter button
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              _showFilterDialog(context);
            },
            tooltip: 'Filter berdasarkan celengan',
          ),
          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _loadTransactions();
              _animationController.reset();
            },
            tooltip: 'Perbarui transaksi',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                await _loadTransactions();
                _animationController.reset();
                _animationController.forward();
              },
              child: _buildTransactionsList(),
            ),
    );
  }
  
  Widget _buildTransactionsList() {
    final transactionProvider = Provider.of<TransactionProvider>(context);
    final savingsProvider = Provider.of<SavingsProvider>(context, listen: false);
    final transactions = transactionProvider.transactions;
    final currencyFormat = NumberFormat.currency(locale: 'id', symbol: 'Rp', decimalDigits: 0);
    
    if (transactions.isEmpty) {
      return _buildEmptyState();
    }
    
    return ListView.builder(
      itemCount: transactions.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final transaction = transactions[index];
        // Get pot name
        final pot = savingsProvider.getSavingsPotById(transaction.savingsPotId);
        final potName = pot?.name ?? 'Celengan Tidak Diketahui';
        
        // Create staggered animation for each item
        final animation = Tween<Offset>(
          begin: const Offset(0, -0.3),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Interval(
              index < 20 ? (index * 0.05).clamp(0.0, 0.9) : 0.9, // First 20 items staggered, rest together
              index < 20 ? (index * 0.05 + 0.5).clamp(0.0, 1.0) : 1.0,
              curve: Curves.easeOutCubic,
            ),
          ),
        );
        
        final fadeAnim = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Interval(
              index < 20 ? (index * 0.05).clamp(0.0, 0.9) : 0.9,
              index < 20 ? (index * 0.05 + 0.5).clamp(0.0, 1.0) : 1.0,
              curve: Curves.easeOut,
            ),
          ),
        );
        
        return SlideTransition(
          position: animation,
          child: FadeTransition(
            opacity: fadeAnim,
            child: Card(
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
                  transaction.notes ?? 'Transaksi',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('d MMM yyyy', 'id_ID').format(transaction.date),
                      style: TextStyle(
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      "Dari: $potName",
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w500,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                isThreeLine: true,
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
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildEmptyState() {
    final fadeAnim = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    
    return FadeTransition(
      opacity: fadeAnim,
      child: Center(
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
              'Belum ada transaksi',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Transaksi Anda akan muncul di sini',
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
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
                'Detail Transaksi',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Savings pot name
            Row(
              children: [
                Icon(Icons.savings_outlined, color: Colors.grey),
                const SizedBox(width: 12),
                const Text('Celengan:', style: TextStyle(color: Colors.grey)),
                const Spacer(),
                Consumer<SavingsProvider>(
                  builder: (context, savingsProvider, _) {
                    final pot = savingsProvider.getSavingsPotById(transaction.savingsPotId);
                    return Text(
                      pot?.name ?? 'Celengan Tidak Diketahui',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  },
                ),
              ],
            ),
            
            const Divider(height: 24),
            
            // Type
            Row(
              children: [
                const Icon(Icons.category_outlined, color: Colors.grey),
                const SizedBox(width: 12),
                const Text('Jenis:', style: TextStyle(color: Colors.grey)),
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
                        ? 'Pemasukan'
                        : 'Pengeluaran',
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
                const Text('Jumlah:', style: TextStyle(color: Colors.grey)),
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
                const Text('Tanggal:', style: TextStyle(color: Colors.grey)),
                const Spacer(),
                Text(
                  DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(transaction.date),
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
                const Text('Catatan:', style: TextStyle(color: Colors.grey)),
                const Spacer(),
                Flexible(
                  child: Text(
                    transaction.notes ?? 'Tidak ada catatan',
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
                label: const Text('Hapus Transaksi', style: TextStyle(color: Colors.red)),
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
        title: const Text('Hapus Transaksi'),
        content: const Text('Apakah Anda yakin ingin menghapus transaksi ini? Tindakan ini tidak dapat dibatalkan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
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
                    content: Text('Transaksi berhasil dihapus'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
  
  void _showFilterDialog(BuildContext context) {
    final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
    final savingsProvider = Provider.of<SavingsProvider>(context, listen: false);
    final savingsPots = savingsProvider.savingsPots;
    final String? currentPotId = transactionProvider.currentPotId;
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Filter Transaksi'),
          content: Container(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Option to show all transactions
                ListTile(
                  title: const Text('Semua Transaksi'),
                  leading: Radio<String?>(
                    value: null,
                    groupValue: currentPotId,
                    onChanged: (value) {
                      transactionProvider.setCurrentPotId(value);
                      Navigator.of(context).pop();
                      _loadTransactions();
                    },
                  ),
                ),
                const Divider(),
                // List of savings pots
                Container(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.4,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: savingsPots.map((pot) => 
                        ListTile(
                          title: Text(pot.name),
                          leading: Radio<String?>(
                            value: pot.id,
                            groupValue: currentPotId,
                            onChanged: (value) {
                              transactionProvider.setCurrentPotId(value);
                              Navigator.of(context).pop();
                              _loadTransactions();
                            },
                          ),
                        )
                      ).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('BATAL'),
            ),
          ],
        );
      },
    );
  }
} 