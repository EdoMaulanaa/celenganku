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

class SavingsPotTabState extends State<SavingsPotTab> with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  late AnimationController _animationController;
  final TextEditingController _searchController = TextEditingController();
  bool _showSearchField = false;
  final FocusNode _searchFocusNode = FocusNode();
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    // Using Future.microtask to ensure this doesn't run during build phase
    Future.microtask(() {
      _loadSavingsPots();
      _animationController.forward();
    });
    
    // Add listener to search controller
    _searchController.addListener(_onSearchChanged);
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }
  
  // Handle search text changes
  void _onSearchChanged() {
    if (!mounted) return;  // Check if widget is still mounted
    
    final query = _searchController.text.trim();
    
    // Debounce search queries
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;  // Check again after delay
      if (query == _searchController.text.trim()) {
        final savingsProvider = Provider.of<SavingsProvider>(context, listen: false);
        
        // Store current search state to detect changes
        final wasSearching = savingsProvider.isSearching;
        final previousResultCount = wasSearching ? savingsProvider.searchResults.length : 0;
        
        if (query.isEmpty) {
          savingsProvider.clearSearch();
        } else {
          savingsProvider.searchSavingsPots(query);
        }
        
        // Reset animation only if search state or results count changed
        if (!wasSearching != !savingsProvider.isSearching || 
            (savingsProvider.isSearching && 
             previousResultCount != savingsProvider.searchResults.length)) {
          _animationController.reset();
          _animationController.forward();
        }
      }
    });
  }
  
  // Method to reset animation when returning to this tab
  void resetAnimation() {
    _animationController.reset();
    _animationController.forward();
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
    
    // Start animation after loading
    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _showSearchField
            ? TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search pots...',
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 16),
                ),
                style: const TextStyle(fontSize: 16),
              )
            : const Text('Savings Pots'),
        elevation: 0,
        actions: [
          // Search button
          IconButton(
            icon: Icon(_showSearchField ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _showSearchField = !_showSearchField;
                if (_showSearchField) {
                  // Focus the search field after showing it
                  Future.delayed(const Duration(milliseconds: 100), () {
                    _searchFocusNode.requestFocus();
                  });
                } else {
                  _searchController.clear();
                  Provider.of<SavingsProvider>(context, listen: false)
                      .clearSearch();
                }
              });
            },
          ),
          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _loadSavingsPots();
              _animationController.reset();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                await _loadSavingsPots();
                _animationController.reset();
                _animationController.forward();
              },
              child: _buildSavingsPotsList(),
            ),
    );
  }
  
  Widget _buildSavingsPotsList() {
    final savingsProvider = Provider.of<SavingsProvider>(context);
    final isSearching = savingsProvider.isSearching;
    final pots = isSearching ? savingsProvider.searchResults : savingsProvider.savingsPots;
    final currencyFormat = NumberFormat.currency(locale: 'id', symbol: 'Rp', decimalDigits: 0);
    
    if (isSearching && pots.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'No pots found matching "${_searchController.text}"',
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    
    if (pots.isEmpty) {
      return _buildEmptyState();
    }
    
    return ListView.builder(
      itemCount: pots.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final pot = pots[index];
        
        // Create staggered animation for each item
        final animation = Tween<Offset>(
          begin: const Offset(0, -0.3),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Interval(
              index < 15 ? (index * 0.05).clamp(0.0, 0.9) : 0.9, // First 15 items staggered, rest together
              index < 15 ? (index * 0.05 + 0.5).clamp(0.0, 1.0) : 1.0,
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
              index < 15 ? (index * 0.05).clamp(0.0, 0.9) : 0.9,
              index < 15 ? (index * 0.05 + 0.5).clamp(0.0, 1.0) : 1.0,
              curve: Curves.easeOut,
            ),
        ),
      );
        
        return SlideTransition(
          position: animation,
          child: FadeTransition(
            opacity: fadeAnim,
            child: Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: InkWell(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => PotDetailsScreen(potId: pot.id),
                  ),
                ),
                borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and icon
                  Row(
                    children: [
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
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _showSearchField = true;
                  // Focus the search field after showing it
                  Future.delayed(const Duration(milliseconds: 100), () {
                    _searchFocusNode.requestFocus();
                  });
                });
              },
              icon: const Icon(Icons.search),
              label: const Text('Search Pots'),
            ),
          ],
        ),
      ),
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
      barrierDismissible: false, // Prevent dialog from closing when clicking outside
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Edit Savings Pot'),
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
                          // Validate inputs
                          if (nameController.text.trim().isEmpty) {
                            setDialogState(() {
                              errorMessage = 'Please enter a name for your savings pot';
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
                                  errorMessage = 'Target amount must be greater than zero';
                                });
                                return;
                              }
                            } catch (e) {
                              setDialogState(() {
                                errorMessage = 'Please enter a valid target amount';
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
                              
                              // Refresh the list after slight delay
                              await Future.delayed(const Duration(milliseconds: 300));
                              
                              if (mounted) {
                                await _loadSavingsPots();
                                
                                // Show success message
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Savings pot updated successfully!'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            } else {
                              if (!mounted) return;
                              setDialogState(() {
                                isSubmitting = false;
                                errorMessage = savingsProvider.errorMessage ??
                                    'Failed to update savings pot';
                              });
                            }
                          } catch (e) {
                            if (!mounted) return;
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
                      : const Text('SAVE'),
                ),
              ],
            );
          },
        );
      },
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
                            
                            print('Attempting to create pot: ${nameController.text.trim()}');
                            print('Description: ${descriptionController.text.trim()}');
                            print('Target Amount: $targetAmount');
                            print('Target Date: $selectedDate');
                            
                            final success = await savingsProvider.createSavingsPot(
                              name: nameController.text.trim(),
                              description: descriptionController.text.trim(),
                              targetAmount: targetAmount,
                              targetDate: selectedDate,
                            );
                            
                            print('Create savings pot result: $success');
                            
                            if (success) {
                              if (dialogContext.mounted) {
                                Navigator.pop(dialogContext);
                              }
                              
                              // Refresh the list after slight delay
                              await Future.delayed(const Duration(milliseconds: 300));
                              
                              if (mounted) {
                                await _loadSavingsPots();
                                
                                // Show success message
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Savings pot created successfully!'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            } else {
                              if (!mounted) return;
                              setDialogState(() {
                                isSubmitting = false;
                                errorMessage = savingsProvider.errorMessage ??
                                    'Failed to create savings pot';
                              });
                              print('Failed to create pot: ${savingsProvider.errorMessage}');
                            }
                          } catch (e) {
                            print('Exception creating pot: $e');
                            if (!mounted) return;
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
}