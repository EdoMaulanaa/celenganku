import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/auth_provider.dart';
import '../../providers/savings_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/category_provider.dart';
import '../../utils/formatter.dart';
import '../../utils/chart_utils.dart';
import '../../models/savings_pot.dart';
import '../../models/transaction.dart';
import '../../models/transaction_category.dart';

class DashboardTab extends StatefulWidget {
  const DashboardTab({super.key});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  @override
  void initState() {
    super.initState();
    // Refresh data when screen is loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SavingsProvider>(context, listen: false).loadSavingsPots();
      Provider.of<TransactionProvider>(context, listen: false).loadTransactions();
      Provider.of<CategoryProvider>(context, listen: false).loadCategories();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final savingsProvider = Provider.of<SavingsProvider>(context);
    final transactionProvider = Provider.of<TransactionProvider>(context);
    final categoryProvider = Provider.of<CategoryProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await savingsProvider.loadSavingsPots();
          await transactionProvider.loadTransactions();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting card
              _buildGreetingCard(authProvider),
              
              const SizedBox(height: 24),
              
              // Total balance card
              _buildTotalBalanceCard(savingsProvider),
              
              const SizedBox(height: 24),
              
              // Monthly savings chart
              _buildMonthlySavingsChart(transactionProvider),
              
              const SizedBox(height: 24),
              
              // Expense breakdown
              _buildExpenseBreakdownChart(transactionProvider, categoryProvider),
              
              const SizedBox(height: 24),
              
              // Recent pots 
              _buildRecentPotsSection(savingsProvider),
            ],
          ),
        ),
      ),
    );
  }
  
  // Build greeting card with user info
  Widget _buildGreetingCard(AuthProvider authProvider) {
    final username = authProvider.profile?.username 
      ?? authProvider.user?.email?.split('@').first
      ?? 'User';
    
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // User avatar or placeholder
            CircleAvatar(
              radius: 30,
              backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
              backgroundImage: authProvider.profile?.avatarUrl != null
                ? NetworkImage(authProvider.profile!.avatarUrl!)
                : null,
              child: authProvider.profile?.avatarUrl == null
                ? Icon(
                    Icons.person,
                    size: 32,
                    color: Theme.of(context).colorScheme.primary,
                  )
                : null,
            ),
            
            const SizedBox(width: 16),
            
            // Greeting text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hello, $username',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  const SizedBox(height: 4),
                  
                  Text(
                    'Welcome to your savings dashboard',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).textTheme.bodySmall?.color,
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
  
  // Build total balance card
  Widget _buildTotalBalanceCard(SavingsProvider savingsProvider) {
    return Card(
      margin: EdgeInsets.zero,
      color: Theme.of(context).colorScheme.primary,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Balance label
            const Text(
              'Total Balance',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Balance amount
            Text(
              Formatter.formatCurrency(savingsProvider.totalBalance),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Pots count
            Row(
              children: [
                const Icon(
                  Icons.savings_outlined,
                  color: Colors.white70,
                  size: 20,
                ),
                
                const SizedBox(width: 8),
                
                Text(
                  '${savingsProvider.savingsPots.length} Savings Pots',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  // Build monthly savings chart
  Widget _buildMonthlySavingsChart(TransactionProvider transactionProvider) {
    final transactions = transactionProvider.transactions;
    
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Monthly Savings',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Net savings per month over the last 6 months',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: transactions.isEmpty
                  ? const Center(
                      child: Text(
                        'No transaction data available',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        barGroups: ChartUtils.generateMonthlySavingsBarChart(
                          transactions: transactions,
                          numberOfMonths: 6,
                        ),
                        titlesData: FlTitlesData(
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                final now = DateTime.now();
                                final month = now.month - (5 - value.toInt());
                                final adjustedMonth = month <= 0 ? month + 12 : month;
                                
                                // Get month name abbreviation
                                final monthName = DateFormat('MMM').format(
                                  DateTime(2022, adjustedMonth, 1),
                                );
                                
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    monthName,
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                );
                              },
                              reservedSize: 30,
                            ),
                          ),
                          leftTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        gridData: const FlGridData(show: false),
                        borderData: FlBorderData(show: false),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Build expense breakdown chart
  Widget _buildExpenseBreakdownChart(TransactionProvider transactionProvider, CategoryProvider categoryProvider) {
    final transactions = transactionProvider.transactions;
    final categories = categoryProvider.allCategories;
    
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Expense Breakdown',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'How your money is spent by category',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 240,
              child: transactions.isEmpty
                  ? const Center(
                      child: Text(
                        'No expense data available',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : PieChart(
                      PieChartData(
                        sections: ChartUtils.generateCategoryPieCharts(
                          transactions: transactions,
                          categories: categories,
                          type: TransactionType.expense,
                          radius: 100,
                        ),
                        sectionsSpace: 2,
                        centerSpaceRadius: 40,
                      ),
                    ),
            ),
            const SizedBox(height: 16),
            _buildCategoryLegend(transactionProvider, categoryProvider, TransactionType.expense),
          ],
        ),
      ),
    );
  }
  
  // Build category legend for pie chart
  Widget _buildCategoryLegend(
    TransactionProvider transactionProvider,
    CategoryProvider categoryProvider,
    TransactionType type
  ) {
    final transactions = transactionProvider.transactions
        .where((txn) => txn.type == type)
        .toList();
    final categories = categoryProvider.allCategories
        .where((cat) => cat.type == type)
        .toList();
    
    if (transactions.isEmpty) return const SizedBox.shrink();
    
    // Map to store total amount per category
    final categoryTotals = <String, double>{};
    
    // Calculate totals
    for (final txn in transactions) {
      final categoryId = txn.categoryId ?? 'uncategorized';
      categoryTotals[categoryId] = (categoryTotals[categoryId] ?? 0) + txn.amount;
    }
    
    // Sort by amount (descending)
    final sortedEntries = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    // Take top 5 categories
    final topCategories = sortedEntries.take(5).toList();
    
    // Total amount
    final totalAmount = categoryTotals.values.fold<double>(0, (sum, amount) => sum + amount);
    
    // Format currency
    final formatter = NumberFormat.currency(locale: 'id', symbol: 'Rp', decimalDigits: 0);
    
    return Column(
      children: topCategories.map((entry) {
        final categoryId = entry.key;
        final amount = entry.value;
        final percentage = (amount / totalAmount) * 100;
        
        // Find category if available
        TransactionCategory? category;
        if (categoryId != 'uncategorized') {
          try {
            category = categories.firstWhere(
              (cat) => cat.id == categoryId,
            );
          } catch (_) {
            // Category not found
            category = null;
          }
        }
        
        final categoryName = category?.name ?? 'Uncategorized';
        final categoryColor = category?.color ?? Colors.grey;
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Row(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: categoryColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(categoryName),
              ),
              Text(
                '${percentage.toStringAsFixed(1)}%',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                formatter.format(amount),
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
  
  // Build recent pots section
  Widget _buildRecentPotsSection(SavingsProvider savingsProvider) {
    final pots = savingsProvider.savingsPots;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Your Savings Pots',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            // View all button
            TextButton(
              onPressed: () {
                // Switch to Pots tab
                final tabController = DefaultTabController.of(context);
                if (tabController != null) {
                  tabController.animateTo(1); // Navigate to Pots tab
                }
              },
              child: const Text('View All'),
            ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        // Pots list
        if (savingsProvider.status == SavingsStatus.loading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          )
        else if (pots.isEmpty)
          _buildEmptyState()
        else
          ListView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: pots.length > 3 ? 3 : pots.length,
            itemBuilder: (context, index) {
              return _buildPotCard(pots[index]);
            },
          ),
      ],
    );
  }
  
  // Build pot card
  Widget _buildPotCard(SavingsPot pot) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Pot name and icon
            Row(
              children: [
                // Pot icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Builder(
                    builder: (context) {
                      try {
                        // First check if icon name is valid
                        if (pot.iconName == null || pot.iconName!.isEmpty) {
                          return Icon(
                            Icons.savings_outlined,
                            color: Theme.of(context).colorScheme.primary,
                          );
                        }
                        
                        // Try to create the icon from code point
                        return Icon(
                          pot.icon,
                          color: Theme.of(context).colorScheme.primary,
                        );
                      } catch (e) {
                        print('Dashboard: Error rendering icon: $e');
                        return Icon(
                          Icons.savings_outlined,
                          color: Theme.of(context).colorScheme.primary,
                        );
                      }
                    },
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Pot name
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pot.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (pot.targetAmount != null)
                        Text(
                          '${pot.progressPercentage.toStringAsFixed(1)}% of target',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ),
                
                // Current balance
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      Formatter.formatCurrency(pot.currentBalance),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    if (pot.targetAmount != null)
                      Text(
                        'of ${Formatter.formatCurrency(pot.targetAmount!)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                  ],
                ),
              ],
            ),
            
            if (pot.targetAmount != null) ...[
              const SizedBox(height: 12),
              
              // Progress bar
              LinearProgressIndicator(
                value: pot.progressPercentage / 100,
                backgroundColor: Colors.grey[200],
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
                valueColor: AlwaysStoppedAnimation<Color>(
                  pot.progressPercentage >= 100 
                      ? Colors.green 
                      : Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  // Build empty state
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.savings_outlined,
            size: 64,
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
        ],
      ),
    );
  }
} 