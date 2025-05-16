import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/savings_provider.dart';
import '../providers/transaction_provider.dart';
import '../models/savings_pot.dart';
import '../models/transaction.dart';
import '../utils/formatter.dart';
import '../utils/chart_utils.dart';

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
    _loadData();
  }
  
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });
    
    final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
    transactionProvider.setCurrentPotId(widget.potId);
    await transactionProvider.loadTransactions();
    
    // Pre-load futures to avoid calling during build
    final savingsProvider = Provider.of<SavingsProvider>(context, listen: false);
    _dailySavingsNeededFuture = savingsProvider.calculateDailySavingsNeeded(widget.potId);
    _daysRemainingFuture = savingsProvider.calculateDaysRemaining(widget.potId);
    
    if (!mounted) return;
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final savingsProvider = Provider.of<SavingsProvider>(context);
    final transactionProvider = Provider.of<TransactionProvider>(context);
    
    final pot = savingsProvider.getSavingsPotById(widget.potId);
    
    if (pot == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Pot Details'),
        ),
        body: const Center(
          child: Text('Savings pot not found'),
        ),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Text(pot.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Summary card
                  _buildSummaryCard(pot),
                  
                  const SizedBox(height: 24),
                  
                  // Progress chart
                  if (pot.targetAmount != null && pot.targetAmount! > 0)
                    _buildProgressChart(pot, transactionProvider),
                  
                  const SizedBox(height: 24),
                  
                  // Transactions list
                  _buildTransactionsList(transactionProvider),
                ],
              ),
            ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Withdraw/expense button
          FloatingActionButton.small(
            onPressed: () {
              _showAddTransactionDialog(pot, TransactionType.expense);
            },
            heroTag: 'withdrawFAB',
            backgroundColor: Colors.red,
            child: const Icon(Icons.remove),
          ),
          const SizedBox(height: 16),
          // Add/income button
          FloatingActionButton(
            onPressed: () {
              _showAddTransactionDialog(pot, TransactionType.income);
            },
            heroTag: 'addTransactionFAB',
            backgroundColor: Colors.green,
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSummaryCard(SavingsPot pot) {
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
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  child: Icon(
                    pot.icon,
                    color: Theme.of(context).colorScheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
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
              'Current Balance',
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
                          'Target Amount',
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
                            'Target Date',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('MMM dd, yyyy').format(pot.targetDate!),
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
                'Progress',
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
                          'Need ${currencyFormat.format(snapshot.data!)} / day',
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
                          'Target date has passed!',
                          style: TextStyle(
                            color: Colors.red[700],
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      }
                      return Text(
                        '$days days remaining',
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
  
  Widget _buildProgressChart(SavingsPot pot, TransactionProvider transactionProvider) {
    final transactions = transactionProvider.currentPotTransactions;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Goal Progress',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Target: ${Formatter.formatCurrency(pot.targetAmount!)} by ${pot.targetDate != null ? DateFormat('MMM dd, yyyy').format(pot.targetDate!) : 'No date set'}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 250,
              child: transactions.isEmpty
                  ? const Center(
                      child: Text(
                        'No transaction data available',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : LineChart(
                      ChartUtils.generateGoalLineChart(
                        pot: pot,
                        transactions: transactions,
                      ),
                    ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildLegendItem(
                  color: Theme.of(context).colorScheme.primary,
                  label: 'Actual progress',
                ),
                const SizedBox(width: 24),
                _buildLegendItem(
                  color: Colors.grey.shade500,
                  label: 'Target line',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildLegendItem({required Color color, required String label}) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 3,
          color: color,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ],
    );
  }
  
  Widget _buildTransactionsList(TransactionProvider transactionProvider) {
    final transactions = transactionProvider.currentPotTransactions;
    final currencyFormat = NumberFormat.currency(locale: 'id', symbol: 'Rp', decimalDigits: 0);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Transactions',
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
                    'No transactions yet',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Add funds to start tracking your progress',
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
                ),
              );
            },
          ),
      ],
    );
  }
  
  // Add transaction dialog
  void _showAddTransactionDialog(SavingsPot pot, TransactionType type) {
    final TextEditingController amountController = TextEditingController();
    final TextEditingController notesController = TextEditingController();
    
    bool isSubmitting = false;
    String? errorMessage;
    
    // Get current date as default
    DateTime transactionDate = DateTime.now();
    
    final currencyFormat = NumberFormat.currency(locale: 'id', symbol: 'Rp', decimalDigits: 0);
    
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(
            type == TransactionType.income 
                ? 'Add to ${pot.name}'
                : 'Withdraw from ${pot.name}',
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
                      'Current Balance:',
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
                    labelText: '${type == TransactionType.income ? 'Add' : 'Withdraw'} Amount *',
                    hintText: 'e.g., 500000',
                    prefixText: 'Rp ',
                    prefixIcon: Icon(
                      type == TransactionType.income ? Icons.add : Icons.remove,
                      color: type == TransactionType.income ? Colors.green : Colors.red,
                    ),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  autofocus: true,
                ),
                
                const SizedBox(height: 16),
                
                // Notes field
                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notes (Optional)',
                    hintText: 'e.g., Salary, Gift, Groceries',
                  ),
                  maxLength: 100,
                ),
                
                const SizedBox(height: 16),
                
                // Date field
                const Text(
                  'Transaction Date',
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
                    DateFormat('MMM dd, yyyy').format(transactionDate),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              onPressed: isSubmitting 
                  ? null 
                  : () async {
                      // Validate inputs
                      if (amountController.text.trim().isEmpty) {
                        setState(() {
                          errorMessage = 'Please enter an amount';
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
                            errorMessage = 'Amount must be greater than zero';
                          });
                          return;
                        }
                      } catch (e) {
                        setState(() {
                          errorMessage = 'Please enter a valid amount';
                        });
                        return;
                      }
                      
                      // For withdrawals, check if there's enough balance
                      if (type == TransactionType.expense && amount > pot.currentBalance) {
                        setState(() {
                          errorMessage = 'Insufficient balance for withdrawal';
                        });
                        return;
                      }
                      
                      // Start submission
                      setState(() {
                        isSubmitting = true;
                        errorMessage = null;
                      });
                      
                      try {
                        print('Attempting to create transaction: Amount=$amount, Type=$type, PotID=${pot.id}');
                        
                        // Using Provider.of with listen: false for callbacks
                        final transactionProvider = Provider.of<TransactionProvider>(
                          context, 
                          listen: false
                        );
                        
                        final success = await transactionProvider.createTransaction(
                          savingsPotId: pot.id,
                          amount: amount,
                          type: type,
                          date: transactionDate,
                          notes: notesController.text.isNotEmpty 
                              ? notesController.text.trim() 
                              : null,
                        );
                        
                        if (success) {
                          if (!mounted) return;
                          Navigator.of(context).pop();
                          
                          // Reload data to show updated transactions
                          _loadData();
                          
                          print('Transaction created successfully');
                          
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                type == TransactionType.income
                                    ? 'Successfully added to ${pot.name}'
                                    : 'Successfully withdrawn from ${pot.name}',
                              ),
                              backgroundColor: Colors.green,
                            ),
                          );
                        } else {
                          if (!mounted) return;
                          setState(() {
                            isSubmitting = false;
                            errorMessage = transactionProvider.errorMessage ?? 
                                'Failed to process transaction';
                          });
                          print('Failed to create transaction: ${transactionProvider.errorMessage}');
                        }
                      } catch (e) {
                        print('Exception creating transaction: $e');
                        setState(() {
                          isSubmitting = false;
                          errorMessage = 'An error occurred: ${e.toString()}';
                        });
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: type == TransactionType.income ? Colors.green : Colors.red,
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
                  : Text(
                      type == TransactionType.income ? 'ADD' : 'WITHDRAW'
                    ),
            ),
          ],
        ),
      ),
    );
  }
} 