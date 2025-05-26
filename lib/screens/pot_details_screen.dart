import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/savings_provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/category_provider.dart';
import '../models/savings_pot.dart';
import '../models/transaction.dart';
import '../models/transaction_category.dart';
import '../utils/formatter.dart';
import '../utils/chart_utils.dart';
import 'package:intl/date_symbol_data_local.dart';

class PotDetailsScreen extends StatefulWidget {
  final String potId;
  
  const PotDetailsScreen({super.key, required this.potId});

  @override
  State<PotDetailsScreen> createState() => _PotDetailsScreenState();
}

class _PotDetailsScreenState extends State<PotDetailsScreen> {
  bool _isLoading = true;
  Future<double?>? _dailySavingsNeededFuture;
  Future<int?>? _daysRemainingFuture;
  
  @override
  void initState() {
    super.initState();
    // Initialize locale for Indonesian date formatting
    initializeDateFormatting('id_ID', null);
    // Use Future.microtask to ensure we're not in the build phase
    Future.microtask(() => _loadData());
  }
  
  Future<void> _loadData() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });
    
    // Get providers
    final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
    final savingsProvider = Provider.of<SavingsProvider>(context, listen: false);
    
    // Set the current pot ID without notification
    await Future.microtask(() async {
      // We're setting this in a microtask to avoid triggering notifyListeners during build
      transactionProvider.setCurrentPotId(widget.potId, notify: false);
      
      // Load transactions (this will set up the real-time stream)
      await transactionProvider.loadTransactions();
      
      // Pre-load futures to avoid calling during build
      _dailySavingsNeededFuture = savingsProvider.calculateDailySavingsNeeded(widget.potId);
      _daysRemainingFuture = savingsProvider.calculateDaysRemaining(widget.potId);
    });
    
    if (!mounted) return;
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<SavingsProvider, TransactionProvider>(
      builder: (context, savingsProvider, transactionProvider, _) {
        // Get the pot details
        final pot = savingsProvider.getSavingsPotById(widget.potId);
        
        // If pot isn't found, show loading or error
        if (pot == null) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Loading...'),
              elevation: 0,
            ),
            body: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        // Filter transactions for this pot (now handled by the provider)
        final transactions = transactionProvider.currentPotTransactions;
        
        return Scaffold(
          appBar: AppBar(
            title: Text(pot.name),
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  _showEditPotDialog(pot, context);
                },
                tooltip: 'Edit',
              ),
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () {
                  _showDeleteConfirmation(pot, context);
                },
                tooltip: 'Delete',
              ),
            ],
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Pot details card
                        _buildPotDetailsCard(pot),
                        
                        const SizedBox(height: 20),
                        
                        // Progress chart - only show if target is set
                        if (pot.targetAmount != null && pot.targetAmount! > 0)
                          _buildProgressChart(pot, transactions),
                        
                        // Display calculated daily savings needed and days remaining after chart
                        if (pot.targetAmount != null && pot.targetAmount! > 0 && pot.targetDate != null)
                          _buildSavingsRequirementInfo(pot),
                        
                        const SizedBox(height: 20),
                        
                        // Transactions list
                        _buildTransactionsList(transactions),
                      ],
                    ),
                  ),
                ),
          floatingActionButton: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Deposit button (Add money)
              FloatingActionButton(
                onPressed: () => _showAddTransactionDialog(context, pot, TransactionType.income),
                heroTag: 'deposit',
                backgroundColor: Colors.green,
                child: const Icon(Icons.arrow_downward),
              ),
              const SizedBox(height: 16),
              // Withdraw button (Take money)
              FloatingActionButton(
                onPressed: () => _showAddTransactionDialog(context, pot, TransactionType.expense),
                heroTag: 'withdraw',
                backgroundColor: Colors.red,
                child: const Icon(Icons.arrow_upward),
              ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildPotDetailsCard(SavingsPot pot) {
    final currencyFormat = NumberFormat.currency(locale: 'id', symbol: 'Rp', decimalDigits: 0);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Pot name and icon
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pot.name,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (pot.description.isNotEmpty)
                        Text(
                          pot.description,
                          style: TextStyle(
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Balance
            const Text(
              'Saldo Saat Ini',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              currencyFormat.format(pot.currentBalance),
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            

            
            // Target information
            if (pot.targetAmount != null) ...[
              const SizedBox(height: 24),
              
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Jumlah Target',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          currencyFormat.format(pot.targetAmount!),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (pot.targetDate != null)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Tanggal Target',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('d MMM yyyy', 'id_ID').format(pot.targetDate!),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Progress
              const Text(
                'Progres',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              
              // Progress bar
              LinearProgressIndicator(
                value: pot.progressPercentage / 100,
                minHeight: 12,
                borderRadius: BorderRadius.circular(6),
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(
                  pot.progressPercentage >= 100 
                      ? Colors.green 
                      : Theme.of(context).colorScheme.primary,
                ),
              ),
              
              const SizedBox(height: 8),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${pot.progressPercentage.toStringAsFixed(1)}%',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  FutureBuilder<double?>(
                    future: _dailySavingsNeededFuture,
                    builder: (context, snapshot) {
                      if (snapshot.hasData && snapshot.data != null && snapshot.data! > 0) {
                        return Text(
                          'Butuh ${currencyFormat.format(snapshot.data!)} / hari',
                          style: TextStyle(
                            color: Colors.orange[700],
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Days remaining
              if (pot.targetDate != null)
                FutureBuilder<int?>(
                  future: _daysRemainingFuture,
                  builder: (context, snapshot) {
                    if (snapshot.hasData && snapshot.data != null) {
                      final days = snapshot.data!;
                      if (days <= 0) {
                        return Text(
                          'Tanggal target telah berlalu!',
                          style: TextStyle(
                            color: Colors.red[700],
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      }
                      return Text(
                        '$days hari tersisa',
                        style: TextStyle(
                          color: days < 7 ? Colors.red[700] : Colors.grey[600],
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildProgressChart(SavingsPot pot, List<Transaction> transactions) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Progres Tabungan',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 250,
            child: LineChart(
              ChartUtils.generateGoalLineChart(
                pot: pot,
                transactions: transactions,
                primaryColor: Theme.of(context).primaryColor,
              ),
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
            ),
          ),
        ],
      ),
    );
  }
  
  // Add a compact method to display savings requirements without duplicating the card
  Widget _buildSavingsRequirementInfo(SavingsPot pot) {
    final currencyFormat = NumberFormat.currency(locale: 'id', symbol: 'Rp', decimalDigits: 0);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                FutureBuilder<double?>(
                  future: _dailySavingsNeededFuture,
                  builder: (context, snapshot) {
                    if (snapshot.hasData && snapshot.data != null && snapshot.data! > 0) {
                      return Text(
                        'Butuh ${currencyFormat.format(snapshot.data!)} / hari',
                        style: TextStyle(
                          color: Colors.orange[700],
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
                
                FutureBuilder<int?>(
                  future: _daysRemainingFuture,
                  builder: (context, snapshot) {
                    if (snapshot.hasData && snapshot.data != null) {
                      final days = snapshot.data!;
                      if (days <= 0) {
                        return Text(
                          'Tanggal target telah berlalu!',
                          style: TextStyle(
                            color: Colors.red[700],
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        );
                      }
                      return Text(
                        '$days hari tersisa',
                        style: TextStyle(
                          color: days < 7 ? Colors.red[700] : Colors.grey[700],
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Target date
            Text(
              'Target: ${pot.targetDate != null ? DateFormat('d MMM yyyy', 'id_ID').format(pot.targetDate!) : 'Tanggal tidak ditentukan'}',
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTransactionsList(List<Transaction> transactions) {
    final currencyFormat = NumberFormat.currency(locale: 'id', symbol: 'Rp', decimalDigits: 0);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Transaksi',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        if (transactions.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Belum ada transaksi',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tambahkan dana untuk mulai melacak progres Anda',
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ListView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: transactions.length,
            itemBuilder: (context, index) {
              final transaction = transactions[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
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
                    transaction.notes ?? (transaction.type == TransactionType.income ? 'Pemasukan' : 'Pengeluaran'),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    DateFormat('d MMM yyyy', 'id_ID').format(transaction.date),
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
                ),
              );
            },
          ),
      ],
    );
  }
  
  // Add transaction dialog
  void _showAddTransactionDialog(BuildContext context, SavingsPot pot, TransactionType transactionType) {
    final TextEditingController amountController = TextEditingController();
    final TextEditingController notesController = TextEditingController();
    
    bool isSubmitting = false;
    String? errorMessage;
    String? selectedCategoryId;
    
    // Get current date as default
    DateTime transactionDate = DateTime.now();
    
    final currencyFormat = NumberFormat.currency(locale: 'id', symbol: 'Rp', decimalDigits: 0);

    // Get the transaction provider
    final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
    // Get the category provider for expense categories
    final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);

    // Filter categories to only show expense categories if this is a withdrawal
    final categories = transactionType == TransactionType.expense
        ? categoryProvider.allCategories.where((cat) => cat.type == TransactionType.expense).toList()
        : [];
    
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(
            transactionType == TransactionType.income 
                ? 'Tambah ke ${pot.name}'
                : 'Tarik dari ${pot.name}',
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Error message if any
                if (errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      errorMessage!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontSize: 14,
                      ),
                    ),
                  ),
                
                // Current balance
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Saldo Saat Ini:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      currencyFormat.format(pot.currentBalance),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Amount field
                TextField(
                  controller: amountController,
                  decoration: InputDecoration(
                    labelText: 'Jumlah *',
                    hintText: 'contoh: 500000',
                    prefixText: 'Rp ',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  autofocus: true,
                ),
                
                const SizedBox(height: 16),
                
                // Notes field
                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(
                    labelText: 'Catatan (Opsional)',
                    hintText: 'contoh: Gaji, Hadiah, Belanja',
                  ),
                  maxLength: 100,
                ),
                
                // Category dropdown (only for withdrawals)
                if (transactionType == TransactionType.expense) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Kategori',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: selectedCategoryId,
                    decoration: const InputDecoration(
                      labelText: 'Pilih kategori',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('Tanpa kategori'),
                      ),
                      ...categories.map((category) {
                        return DropdownMenuItem<String>(
                          value: category.id,
                          child: Row(
                            children: [
                              Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: category.color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(category.name),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                    onChanged: (value) {
                      setState(() {
                        selectedCategoryId = value;
                      });
                    },
                  ),
                ],
                
                const SizedBox(height: 16),
                
                // Date field
                const Text(
                  'Tanggal Transaksi',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                OutlinedButton.icon(
                  onPressed: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: transactionDate,
                      firstDate: DateTime.now().subtract(const Duration(days: 365)),
                      lastDate: DateTime.now(),
                    );
                    
                    if (picked != null) {
                      setState(() {
                        transactionDate = picked;
                      });
                    }
                  },
                  icon: const Icon(Icons.calendar_today),
                  label: Text(
                    DateFormat('d MMM yyyy', 'id_ID').format(transactionDate),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('BATAL'),
            ),
            ElevatedButton(
              onPressed: isSubmitting 
                  ? null 
                  : () async {
                      // Validate inputs
                      if (amountController.text.trim().isEmpty) {
                        setState(() {
                          errorMessage = 'Silakan masukkan jumlah';
                        });
                        return;
                      }
                      
                      double amount;
                      try {
                        amount = double.parse(
                          amountController.text.replaceAll(RegExp(r'[^0-9.]'), '')
                        );
                        if (amount <= 0) {
                          setState(() {
                            errorMessage = 'Jumlah harus lebih besar dari nol';
                          });
                          return;
                        }
                      } catch (e) {
                        setState(() {
                          errorMessage = 'Silakan masukkan jumlah yang valid';
                        });
                        return;
                      }
                      
                      // For withdrawals, check if there's enough balance
                      if (transactionType == TransactionType.expense && amount > pot.currentBalance) {
                        setState(() {
                          errorMessage = 'Saldo tidak cukup untuk penarikan';
                        });
                        return;
                      }
                      
                      // Start submission
                      setState(() {
                        isSubmitting = true;
                        errorMessage = null;
                      });
                      
                      try {
                        print('Attempting to create transaction: Amount=$amount, Type=${transactionType.toString()}, PotID=${pot.id}');
                        
                        // Get category name if selected
                        String? categoryName;
                        if (selectedCategoryId != null) {
                          try {
                            final category = categoryProvider.getCategoryById(selectedCategoryId);
                            if (category != null) {
                              categoryName = category.name;
                            }
                          } catch (e) {
                            // Ignore error if category not found
                          }
                        }
                        
                        final success = await transactionProvider.createTransaction(
                          savingsPotId: pot.id,
                          amount: amount,
                          type: transactionType,
                          date: transactionDate,
                          notes: notesController.text.isNotEmpty 
                              ? notesController.text.trim() 
                              : null,
                          categoryId: selectedCategoryId,
                          category: categoryName,
                        );
                        
                        if (success) {
                          if (!mounted) return;
                          Navigator.of(context).pop();
                          
                          // Reload data to show updated transactions
                          _loadData();
                          
                          print('Transaction created successfully');
                          
                          final actionText = transactionType == TransactionType.income
                              ? 'ditambahkan ke'
                              : 'ditarik dari';
                              
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Berhasil $actionText ${pot.name}',
                              ),
                              backgroundColor: transactionType == TransactionType.income
                                  ? Colors.green
                                  : Colors.red,
                            ),
                          );
                        } else {
                          if (!mounted) return;
                          setState(() {
                            isSubmitting = false;
                            errorMessage = transactionProvider.errorMessage ?? 
                                'Gagal memproses transaksi';
                          });
                          print('Failed to create transaction: ${transactionProvider.errorMessage}');
                        }
                      } catch (e) {
                        print('Exception creating transaction: $e');
                        setState(() {
                          isSubmitting = false;
                          errorMessage = 'Terjadi kesalahan: ${e.toString()}';
                        });
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: transactionType == TransactionType.income
                    ? Colors.green
                    : Colors.red,
                foregroundColor: Colors.white,
              ),
              child: isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(transactionType == TransactionType.income 
                      ? 'TAMBAH' 
                      : 'TARIK'),
            ),
          ],
        ),
      ),
    );
  }

  // Add the edit and delete methods
  void _showEditPotDialog(SavingsPot pot, BuildContext context) {
    // Controllers for text fields
    final nameController = TextEditingController(text: pot.name);
    final descriptionController = TextEditingController(text: pot.description);
    final targetAmountController = TextEditingController(
      text: pot.targetAmount?.toString() ?? ''
    );
    
    // Variables for state
    DateTime? selectedDate = pot.targetDate;
    bool isSubmitting = false;
    String? errorMessage;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Edit Celengan'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Error message
                  if (errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        errorMessage!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  
                  // Name field
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nama *',
                      hintText: 'contoh: Dana Liburan',
                    ),
                    textCapitalization: TextCapitalization.words,
                    maxLength: 50,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Description field
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Deskripsi',
                      hintText: 'contoh: Tabungan untuk liburan musim panas',
                    ),
                    maxLength: 200,
                    maxLines: 2,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Target amount field
                  TextField(
                    controller: targetAmountController,
                    decoration: const InputDecoration(
                      labelText: 'Jumlah Target (Opsional)',
                      hintText: 'contoh: 5000000',
                      prefixText: 'Rp ',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Target date field
                  const Text(
                    'Tanggal Target (Opsional)',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  OutlinedButton.icon(
                    onPressed: () async {
                      try {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate ?? DateTime.now().add(const Duration(days: 30)),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
                        );
                        
                        if (picked != null) {
                          setDialogState(() {
                            selectedDate = picked;
                          });
                        }
                      } catch (e) {
                        print("Error selecting date: $e");
                      }
                    },
                    icon: const Icon(Icons.calendar_today),
                    label: Text(
                      selectedDate != null
                          ? DateFormat('d MMM yyyy', 'id_ID').format(selectedDate!)
                          : 'Pilih Tanggal Target',
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
                child: const Text('BATAL'),
              ),
              ElevatedButton(
                onPressed: isSubmitting
                    ? null
                    : () async {
                        // Validate inputs
                        if (nameController.text.trim().isEmpty) {
                          setDialogState(() {
                            errorMessage = 'Silakan masukkan nama untuk celengan Anda';
                          });
                          return;
                        }
                        
                        double? targetAmount;
                        if (targetAmountController.text.isNotEmpty) {
                          try {
                            targetAmount = double.parse(
                              targetAmountController.text.replaceAll(RegExp(r'[^0-9.]'), '')
                            );
                            if (targetAmount <= 0) {
                              setDialogState(() {
                                errorMessage = 'Jumlah target harus lebih besar dari nol';
                              });
                              return;
                            }
                          } catch (e) {
                            setDialogState(() {
                              errorMessage = 'Silakan masukkan jumlah target yang valid';
                            });
                            return;
                          }
                        }
                        
                        // Start submission
                        setDialogState(() {
                          isSubmitting = true;
                          errorMessage = null;
                        });
                        
                        try {
                          final savingsProvider = Provider.of<SavingsProvider>(
                            context,
                            listen: false
                          );
                          
                          final success = await savingsProvider.updateSavingsPot(
                            id: pot.id,
                            name: nameController.text.trim(),
                            description: descriptionController.text.trim(),
                            targetAmount: targetAmount,
                            targetDate: selectedDate,
                          );
                          
                          if (success) {
                            if (dialogContext.mounted) {
                              Navigator.pop(dialogContext);
                            }
                            
                            // Refresh the data
                            _loadData();
                            
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Celengan berhasil diperbarui!'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          } else {
                            setDialogState(() {
                              isSubmitting = false;
                              errorMessage = savingsProvider.errorMessage ??
                                  'Gagal memperbarui celengan';
                            });
                          }
                        } catch (e) {
                          setDialogState(() {
                            isSubmitting = false;
                            errorMessage = 'Terjadi kesalahan: ${e.toString()}';
                          });
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
                child: isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('PERBARUI'),
              ),
            ],
          );
        },
      ),
    );
  }
  
  void _showDeleteConfirmation(SavingsPot pot, BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus Celengan'),
        content: RichText(
          text: TextSpan(
            style: TextStyle(color: Colors.grey[800], fontSize: 16),
            children: [
              const TextSpan(text: 'Apakah Anda yakin ingin menghapus '),
              TextSpan(
                text: pot.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const TextSpan(text: '? Tindakan ini tidak dapat dibatalkan.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
            },
            child: const Text('BATAL'),
          ),
          TextButton(
            onPressed: () async {
              final savingsProvider = Provider.of<SavingsProvider>(context, listen: false);
              
              Navigator.of(dialogContext).pop();
              
              // Show loading
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (loadingContext) => const AlertDialog(
                  content: Row(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(width: 16),
                      Text('Menghapus...'),
                    ],
                  ),
                ),
              );
              
              // Delete the pot
              bool success = await savingsProvider.deleteSavingsPot(pot.id);
              
              if (!context.mounted) return;
              Navigator.of(context).pop(); // Pop loading dialog
              
              if (success) {
                // Navigate back to home screen
                Navigator.of(context).pop(); // Pop details screen
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Celengan berhasil dihapus'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(savingsProvider.errorMessage ?? 'Gagal menghapus celengan'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('HAPUS'),
          ),
        ],
      ),
    );
  }
} 