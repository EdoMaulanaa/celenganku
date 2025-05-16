import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/savings_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../models/savings_pot.dart';
import '../../models/transaction.dart';
import '../pot_details_screen.dart';

class SavingsPotTab extends StatefulWidget {
  const SavingsPotTab({super.key});

  @override
  State<SavingsPotTab> createState() => SavingsPotTabState();
}

class SavingsPotTabState extends State<SavingsPotTab> {
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    // Using Future.microtask to ensure this doesn't run during build phase
    Future.microtask(() => _loadSavingsPots());
  }
  
  Future<void> _loadSavingsPots() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });
    
    final savingsProvider = Provider.of<SavingsProvider>(context, listen: false);
    await savingsProvider.loadSavingsPots();
    
    if (!mounted) return;
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Savings Pots'),
        elevation: 0,
        actions: [
          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSavingsPots,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadSavingsPots,
              child: _buildSavingsPotsList(),
            ),
    );
  }
  
  Widget _buildSavingsPotsList() {
    final savingsProvider = Provider.of<SavingsProvider>(context);
    final pots = savingsProvider.savingsPots;
    final currencyFormat = NumberFormat.currency(locale: 'id', symbol: 'Rp', decimalDigits: 0);
    
    if (pots.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.savings_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            const Text(
              'No savings pots yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Create a pot to start saving',
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: showCreatePotDialog,
              icon: const Icon(Icons.add),
              label: const Text('Create New Pot'),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
              itemCount: pots.length,        padding: const EdgeInsets.all(16),        itemBuilder: (context, index) {          final pot = pots[index];          return Card(            margin: const EdgeInsets.only(bottom: 16),            child: InkWell(              onTap: () => Navigator.of(context).push(                MaterialPageRoute(                  builder: (context) => PotDetailsScreen(potId: pot.id),                ),              ),              borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and icon
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                        child: Icon(
                          pot.icon,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          pot.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Balance
                  Text(
                    'Current Balance: ${currencyFormat.format(pot.currentBalance)}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  
                  // Target amount (if set)
                  if (pot.targetAmount != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Target: ${currencyFormat.format(pot.targetAmount!)}',
                      style: TextStyle(
                        color: Colors.grey[600],
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Progress bar
                    LinearProgressIndicator(
                      value: pot.progressPercentage / 100,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        pot.progressPercentage >= 100 
                            ? Colors.green 
                            : Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // Progress percentage
                    Text(
                      '${pot.progressPercentage.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                  
                  // Target date (if set)
                  if (pot.targetDate != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Target Date: ${DateFormat('MMM dd, yyyy').format(pot.targetDate!)}',
                      style: TextStyle(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  
  void _showPotDetails(SavingsPot pot) {
    final currencyFormat = NumberFormat.currency(locale: 'id', symbol: 'Rp', decimalDigits: 0);
    final savingsProvider = Provider.of<SavingsProvider>(context, listen: false);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              
              // Pot information
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: EdgeInsets.zero,
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
                            future: savingsProvider.calculateDailySavingsNeeded(pot.id),
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
                          future: savingsProvider.calculateDaysRemaining(pot.id),
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
                    
                    const SizedBox(height: 32),
                    
                    // Action buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildActionButton(
                          icon: Icons.add,
                          label: 'Add',
                          color: Colors.green,
                          onTap: () {
                            Navigator.pop(context);
                            // Show add transaction dialog
                            _showAddTransactionDialog(pot, TransactionType.income);
                          },
                        ),
                        _buildActionButton(
                          icon: Icons.remove,
                          label: 'Withdraw',
                          color: Colors.red,
                          onTap: () {
                            Navigator.pop(context);
                            // Show withdraw transaction dialog
                            _showAddTransactionDialog(pot, TransactionType.expense);
                          },
                        ),
                        _buildActionButton(
                          icon: Icons.edit,
                          label: 'Edit',
                          color: Colors.blue,
                          onTap: () {
                            Navigator.pop(context);
                            // Show edit pot dialog
                            _showEditPotDialog(pot);
                          },
                        ),
                        _buildActionButton(
                          icon: Icons.delete,
                          label: 'Delete',
                          color: Colors.red[900]!,
                          onTap: () {
                            Navigator.pop(context);
                            // Show delete confirmation
                            _showDeleteConfirmation(pot);
                          },
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Created/updated info
                    Text(
                      'Created: ${DateFormat('MMM dd, yyyy').format(pot.createdAt)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      'Last updated: ${DateFormat('MMM dd, yyyy').format(pot.updatedAt)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: color.withOpacity(0.2),
              child: Icon(
                icon,
                color: color,
                size: 20,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
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
      builder: (context) => StatefulBuilder(
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
                          
                          // Refresh savings pots to update balances
                          await _loadSavingsPots();
                          
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
  
  void _showEditPotDialog(SavingsPot pot) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Edit ${pot.name} will be implemented soon'),
      ),
    );
  }
  
  void _showDeleteConfirmation(SavingsPot pot) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Savings Pot'),
        content: RichText(
          text: TextSpan(
            style: TextStyle(color: Colors.grey[800], fontSize: 16),
            children: [
              const TextSpan(text: 'Are you sure you want to delete '),
              TextSpan(
                text: pot.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const TextSpan(text: '? This action cannot be undone.'),
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
          TextButton(
            onPressed: () async {
              final savingsProvider = Provider.of<SavingsProvider>(context, listen: false);
              
              Navigator.of(context).pop();
              
              // Show loading
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const AlertDialog(
                  content: Row(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(width: 16),
                      Text('Deleting...'),
                    ],
                  ),
                ),
              );
              
              // Delete the pot
              bool success = await savingsProvider.deleteSavingsPot(pot.id);
              
              if (!mounted) return;
              Navigator.of(context).pop(); // Pop loading dialog
              
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Savings pot deleted successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(savingsProvider.errorMessage ?? 'Failed to delete savings pot'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
  }
  
  void showCreatePotDialog() {
    print("Show create pot dialog triggered");
    
    if (!mounted) {
      print("Error: Widget not mounted when showCreatePotDialog was called");
      return;
    }
    
    // Controllers for text fields
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final targetAmountController = TextEditingController();
    
    // Variables for state
    DateTime? selectedDate;
    bool isSubmitting = false;
    String? errorMessage;
    
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dialog from closing when clicking outside
      builder: (dialogContext) {
        print("Dialog builder called with context: $dialogContext");
        return StatefulBuilder(
          builder: (context, setDialogState) {
            print("StatefulBuilder rebuilding");
            return AlertDialog(
              title: const Text('Create New Savings Pot'),
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
                        labelText: 'Name *',
                        hintText: 'e.g., Vacation Fund',
                      ),
                      textCapitalization: TextCapitalization.words,
                      maxLength: 50,
                      autofocus: true,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Description field
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        hintText: 'e.g., Saving for summer vacation',
                      ),
                      maxLength: 200,
                      maxLines: 2,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Target amount field
                    TextField(
                      controller: targetAmountController,
                      decoration: const InputDecoration(
                        labelText: 'Target Amount (Optional)',
                        hintText: 'e.g., 5000000',
                        prefixText: 'Rp ',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Target date field
                    const Text(
                      'Target Date (Optional)',
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
                            initialDate: DateTime.now().add(const Duration(days: 30)),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
                          );
                          
                          if (picked != null) {
                            setDialogState(() {
                              selectedDate = picked;
                              print("Selected date: $selectedDate");
                            });
                          }
                        } catch (e) {
                          print("Error selecting date: $e");
                        }
                      },
                      icon: const Icon(Icons.calendar_today),
                      label: Text(
                        selectedDate != null
                            ? DateFormat('MMM dd, yyyy').format(selectedDate!)
                            : 'Select Target Date',
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
                  child: const Text('CANCEL'),
                ),
                ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          print('Create button pressed');
                          
                          // Validate inputs
                          if (nameController.text.trim().isEmpty) {
                            setDialogState(() {
                              errorMessage = 'Please enter a name for your savings pot';
                            });
                            print("Validation error: Name is empty");
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
                                  errorMessage = 'Target amount must be greater than zero';
                                });
                                print("Validation error: Target amount <= 0");
                                return;
                              }
                            } catch (e) {
                              setDialogState(() {
                                errorMessage = 'Please enter a valid target amount';
                              });
                              print("Validation error parsing target amount: $e");
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
                            
                            // Use the numeric code point of Icons.savings_outlined
                            final iconCodePoint = Icons.savings_outlined.codePoint.toString();
                            
                            print('Attempting to create pot: ${nameController.text.trim()}');
                            print('Description: ${descriptionController.text.trim()}');
                            print('Icon: $iconCodePoint');
                            print('Target Amount: $targetAmount');
                            print('Target Date: $selectedDate');
                            
                            final success = await savingsProvider.createSavingsPot(
                              name: nameController.text.trim(),
                              description: descriptionController.text.trim(),
                              iconName: iconCodePoint,
                              targetAmount: targetAmount,
                              targetDate: selectedDate,
                            );
                            
                            print('Create savings pot result: $success');
                            
                            if (success) {
                              // Pop dialog and refresh list
                              if (dialogContext.mounted) {
                                Navigator.pop(dialogContext);
                              }
                              
                              // Refresh the list after slight delay
                              await Future.delayed(const Duration(milliseconds: 300));
                              await _loadSavingsPots();
                              
                              // Show success message
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Savings pot created successfully!'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            } else {
                              setDialogState(() {
                                isSubmitting = false;
                                errorMessage = savingsProvider.errorMessage ??
                                    'Failed to create savings pot';
                              });
                              print('Failed to create pot: ${savingsProvider.errorMessage}');
                            }
                          } catch (e) {
                            print('Exception creating pot: $e');
                            setDialogState(() {
                              isSubmitting = false;
                              errorMessage = 'An error occurred: ${e.toString()}';
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
                      : const Text('CREATE'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}