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
          // Edit button
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Edit Savings Pot',
            onPressed: () => _showEditPotDialog(pot),
          ),
          // Delete button
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: 'Delete Savings Pot',
            onPressed: () => _showDeleteConfirmation(pot),
          ),
          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Data',
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
                  child: Builder(
                    builder: (context) {
                      try {
                        // First check if icon name is valid
                        if (pot.iconName == null || pot.iconName!.isEmpty) {
                          return Icon(
                            Icons.savings_outlined,
                            color: Theme.of(context).colorScheme.primary,
                            size: 24,
                          );
                        }
                        
                        // Try to create the icon from code point
                        return Icon(
                          pot.icon,
                          color: Theme.of(context).colorScheme.primary,
                          size: 24,
                        );
                      } catch (e) {
                        print('PotDetailsScreen: Error rendering icon: $e');
                        return Icon(
                          Icons.savings_outlined,
                          color: Theme.of(context).colorScheme.primary,
                          size: 24,
                        );
                      }
                    },
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
                        primaryColor: Theme.of(context).colorScheme.primary,
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
  
  // Edit savings pot dialog
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
    String selectedIconCodePoint = pot.iconName ?? Icons.savings_outlined.codePoint.toString();
    
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
                    
                    // Icon selection
                    Row(
                      children: [
                        const Text(
                          'Icon:',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 16),
                        GestureDetector(
                          onTap: () => _showIconSelectionDialog(
                            context,
                            selectedIconCodePoint,
                            (String newIconCodePoint) {
                              setDialogState(() {
                                selectedIconCodePoint = newIconCodePoint;
                              });
                            },
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Builder(
                              builder: (context) {
                                try {
                                  return Icon(
                                    IconData(
                                      int.parse(selectedIconCodePoint),
                                      fontFamily: 'MaterialIcons',
                                    ),
                                    size: 28,
                                    color: Theme.of(context).colorScheme.primary,
                                  );
                                } catch (e) {
                                  print('Error rendering selected icon: $e');
                                  return Icon(
                                    Icons.savings_outlined,
                                    size: 28,
                                    color: Theme.of(context).colorScheme.primary,
                                  );
                                }
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () => _showIconSelectionDialog(
                            context,
                            selectedIconCodePoint,
                            (String newIconCodePoint) {
                              setDialogState(() {
                                selectedIconCodePoint = newIconCodePoint;
                              });
                            },
                          ),
                          child: const Text('Change'),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
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
                              iconName: selectedIconCodePoint,
                              targetAmount: targetAmount,
                              targetDate: selectedDate,
                            );
                            
                            if (success) {
                              if (dialogContext.mounted) {
                                Navigator.pop(dialogContext);
                              }
                              
                              // Refresh data
                              await _loadData();
                              
                              // Show success message
                              if (mounted) {
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
  
  // Delete confirmation dialog
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
                // Return to the previous screen since this pot no longer exists
                Navigator.of(context).pop();
                
                // Show success message
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
  
  // Icon selection dialog
  void _showIconSelectionDialog(
    BuildContext context, 
    String currentIconCodePoint,
    Function(String) onIconSelected
  ) {
    // List of commonly used Material icons for savings
    final List<IconData> icons = [
      // Finance related
      Icons.savings_outlined,
      Icons.account_balance_outlined,
      Icons.account_balance_wallet_outlined,
      Icons.attach_money,
      Icons.credit_card_outlined,
      Icons.payment_outlined,
      Icons.currency_exchange_outlined,
      
      // Shopping related
      Icons.shopping_bag_outlined,
      Icons.shopping_cart_outlined,
      Icons.store_outlined,
      Icons.redeem_outlined,
      Icons.card_giftcard_outlined,
      
      // Home and living
      Icons.house_outlined,
      Icons.home_outlined,
      Icons.apartment_outlined,
      Icons.chair_outlined,
      Icons.bed_outlined,
      Icons.kitchen_outlined,
      
      // Travel and transportation
      Icons.directions_car_outlined,
      Icons.flight_takeoff_outlined,
      Icons.beach_access_outlined,
      Icons.hotel_outlined,
      Icons.luggage_outlined,
      Icons.map_outlined,
      
      // Education
      Icons.school_outlined,
      Icons.book_outlined,
      Icons.auto_stories_outlined,
      
      // Health and wellness
      Icons.health_and_safety_outlined,
      Icons.medical_services_outlined,
      Icons.fitness_center_outlined,
      Icons.spa_outlined,
      
      // Technology
      Icons.phone_android_outlined,
      Icons.laptop_outlined,
      Icons.computer_outlined,
      Icons.headphones_outlined,
      Icons.camera_alt_outlined,
      Icons.sports_esports_outlined,
      
      // Family and lifestyle
      Icons.family_restroom,
      Icons.people_outline,
      Icons.child_care_outlined,
      Icons.pets_outlined,
      
      // Food and dining
      Icons.restaurant_outlined,
      Icons.local_cafe_outlined,
      Icons.bakery_dining_outlined,
      Icons.emoji_food_beverage_outlined,
      
      // Miscellaneous
      Icons.celebration_outlined,
      Icons.favorite_outline,
      Icons.star_outline,
      Icons.flag_outlined,
      Icons.emoji_emotions_outlined,
      Icons.emoji_nature_outlined,
      Icons.account_circle_outlined,
      Icons.sports_basketball_outlined,
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Icon'),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.8,
          height: MediaQuery.of(context).size.height * 0.5,
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              childAspectRatio: 1,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: icons.length,
            itemBuilder: (context, index) {
              final IconData icon = icons[index];
              final bool isSelected = icon.codePoint.toString() == currentIconCodePoint;
              
              return InkWell(
                onTap: () {
                  onIconSelected(icon.codePoint.toString());
                  Navigator.of(context).pop();
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? Theme.of(context).colorScheme.primaryContainer 
                        : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: isSelected
                        ? Border.all(
                            color: Theme.of(context).colorScheme.primary,
                            width: 2,
                          )
                        : null,
                  ),
                  child: Center(
                    child: Icon(
                      icon,
                      size: 32,
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey[800],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('CANCEL'),
          ),
        ],
      ),
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
  
  // Helper method to build action buttons
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
} 