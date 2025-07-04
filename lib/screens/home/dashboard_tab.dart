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
import 'home_screen.dart';

class DashboardTab extends StatefulWidget {
  const DashboardTab({super.key});

  @override
  State<DashboardTab> createState() => DashboardTabState();
}

class DashboardTabState extends State<DashboardTab> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late List<Animation<Offset>> _slideAnimations = [];
  late List<Animation<double>> _fadeAnimations = [];
  
  // Store provider references for safer disposal
  late TransactionProvider _transactionProvider;
  late SavingsProvider _savingsProvider;
  late CategoryProvider _categoryProvider;
  
  final List<GlobalKey> _cardKeys = [
    GlobalKey(), // Greeting card
    GlobalKey(), // Total balance card
    GlobalKey(), // Monthly savings chart
    GlobalKey(), // Expense breakdown
    GlobalKey(), // Recent pots
  ];

  // Reset animation to play again
  void resetAnimation() {
    _animationController.reset();
    _animationController.forward();
    
    // Reset currentPotId when returning to the dashboard
    // This ensures all transactions are shown, not just transactions from a specific pot
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
      transactionProvider.setCurrentPotId(null);
      
      // Refresh data to ensure we're showing the latest
      transactionProvider.refresh();
    });
  }

  @override
  void initState() {
    super.initState();
    
    // Animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    // Create animations for each card
    _setupAnimations();
    
    // Start animation
    _animationController.forward();
    
    // Set up change listeners
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupProviderListeners();
      
      // Reset currentPotId to ensure all transactions are shown in the dashboard
      final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
      transactionProvider.setCurrentPotId(null);
    });
  }
  
  void _setupProviderListeners() {
    // Store references to providers
    _transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
    _savingsProvider = Provider.of<SavingsProvider>(context, listen: false);
    _categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
    
    // Listen for transaction changes
    _transactionProvider.addListener(_onDataChanged);
    
    // Listen for savings pot changes
    _savingsProvider.addListener(_onDataChanged);
    
    // Listen for category changes
    _categoryProvider.addListener(_onDataChanged);
  }
  
  void _onDataChanged() {
    // This will be called when any of the providers notify their listeners
    // We don't need to setState here since the Consumers in the build method will handle the UI updates
    print('Dashboard data changed, charts will update');
  }

  void _setupAnimations() {
    // Create slide animations for each card with different delays
    _slideAnimations = List.generate(
      _cardKeys.length,
      (index) => Tween<Offset>(
        begin: const Offset(1.0, 0.0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Interval(
          index * 0.1, // Start time (staggered)
          index * 0.1 + 0.5, // End time
          curve: Curves.easeOutCubic,
        ),
      )),
    );
    
    // Create fade animations for each card
    _fadeAnimations = List.generate(
      _cardKeys.length,
      (index) => Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Interval(
          index * 0.1, // Start time (staggered)
          index * 0.1 + 0.5, // End time
          curve: Curves.easeOut,
        ),
      )),
    );
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    
    // Remove listeners safely without accessing Provider directly in dispose
    try {
      // Remove listeners using stored provider references
      _transactionProvider.removeListener(_onDataChanged);
      _savingsProvider.removeListener(_onDataChanged);
      _categoryProvider.removeListener(_onDataChanged);
    } catch (e) {
      print('Error removing listeners in DashboardTab dispose: $e');
    }
    
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get media query data for responsive layout and safe areas
    final mediaQuery = MediaQuery.of(context);
    // Calculate additional padding to avoid camera notch
    final topPadding = mediaQuery.padding.top > 0 ? mediaQuery.padding.top + 25.0 : 50.0;
    
    return Consumer4<AuthProvider, TransactionProvider, SavingsProvider, CategoryProvider>(
      builder: (context, authProvider, transactionProvider, savingsProvider, categoryProvider, _) {
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(16, topPadding, 16, 16), // Dynamic padding based on device
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
              
              const SizedBox(height: 16),
              
              // Recent pots 
              _buildRecentPotsSection(savingsProvider),
            ],
          ),
        );
      },
    );
  }
  
  // Build greeting card with user info
  Widget _buildGreetingCard(AuthProvider authProvider) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return SlideTransition(
          position: _slideAnimations[0],
          child: FadeTransition(
            opacity: _fadeAnimations[0],
            child: child,
          ),
        );
      },
      child: Card(
        key: _cardKeys[0],
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
                      'Halo, ${authProvider.profile?.username ?? authProvider.user?.email?.split('@').first ?? 'Pengguna'}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  const SizedBox(height: 4),
                  
                  Text(
                    'Selamat datang di dashboard tabungan Anda',
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
      ),
    );
  }
  
  // Build total balance card
  Widget _buildTotalBalanceCard(SavingsProvider savingsProvider) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return SlideTransition(
          position: _slideAnimations[1],
          child: FadeTransition(
            opacity: _fadeAnimations[1],
            child: child,
          ),
        );
      },
      child: Card(
        key: _cardKeys[1],
      margin: EdgeInsets.zero,
      color: Theme.of(context).colorScheme.primary,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Balance label
            const Text(
              'Total Saldo',
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
                  '${savingsProvider.savingsPots.length} Celengan',
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
      ),
    );
  }
  
  // Build monthly savings chart
  Widget _buildMonthlySavingsChart(TransactionProvider transactionProvider) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return SlideTransition(
          position: _slideAnimations[2],
          child: FadeTransition(
            opacity: _fadeAnimations[2],
            child: child,
          ),
        );
      },
      child: Card(
        key: _cardKeys[2],
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tabungan Bulanan',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tabungan bersih per bulan selama 6 bulan terakhir',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
                child: transactionProvider.transactions.isEmpty
                  ? const Center(
                      child: Text(
                        'Tidak ada data transaksi',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        barGroups: ChartUtils.generateMonthlySavingsBarChart(
                          transactions: transactionProvider.transactions,
                          numberOfMonths: 6,
                        ),
                        titlesData: FlTitlesData(
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                // Get month names for the last 6 months
                                final now = DateTime.now();
                                final month = now.month - value.toInt();
                                final adjustedMonth = month <= 0 ? month + 12 : month;
                                return Text(
                                  DateFormat('MMM').format(DateTime(now.year, adjustedMonth)),
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 10,
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
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeInOut,
                    ),
            ),
          ],
          ),
        ),
      ),
    );
  }
  
  // Build expense breakdown chart
  Widget _buildExpenseBreakdownChart(TransactionProvider transactionProvider, CategoryProvider categoryProvider) {
    final savingsProvider = Provider.of<SavingsProvider>(context, listen: false);
    // Always group by savings pot
    final bool groupBySavingsPot = true;
    
    // Define a list of distinct colors for different pots - shared between chart and legend
    final potColors = [
      Colors.purple,
      Colors.blue,
      Colors.green,
      Colors.amber,
      Colors.orange,
      Colors.red,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
      Colors.brown,
      Colors.cyan,
      Colors.deepOrange,
      Colors.lime,
      Colors.deepPurple,
      Colors.lightBlue,
    ];
    
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return SlideTransition(
          position: _slideAnimations[3],
          child: FadeTransition(
            opacity: _fadeAnimations[3],
            child: child,
          ),
        );
      },
      child: Card(
        key: _cardKeys[3],
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Rincian Pengeluaran',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Bagaimana uang Anda digunakan per celengan',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 240,
                child: transactionProvider.transactions.isEmpty
                  ? const Center(
                      child: Text(
                        'Tidak ada data pengeluaran per celengan',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : PieChart(
                      PieChartData(
                        sections: ChartUtils.generateCategoryPieCharts(
                          transactions: transactionProvider.transactions,
                          categories: categoryProvider.allCategories,
                          type: TransactionType.expense,
                          radius: 100,
                          savingsPots: savingsProvider.savingsPots,
                          groupBySavingsPot: groupBySavingsPot,
                        ),
                        sectionsSpace: 2,
                        centerSpaceRadius: 40,
                      ),
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeInOut,
                    ),
              ),
              const SizedBox(height: 16),
              _buildCategoryLegend(
                transactionProvider, 
                categoryProvider, 
                TransactionType.expense,
                true, // Always group by savings pot
                savingsProvider.savingsPots,
                potColors, // Pass the colors to the legend
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // Build category legend for pie chart
  Widget _buildCategoryLegend(
    TransactionProvider transactionProvider,
    CategoryProvider categoryProvider,
    TransactionType type,
    [bool groupBySavingsPot = true,  // Default to true
    List<SavingsPot>? savingsPots,
    List<Color>? potColors]
  ) {
    final transactions = transactionProvider.transactions
        .where((txn) => txn.type == type)
        .toList();
        
    if (transactions.isEmpty) return const SizedBox.shrink();
    
    // Format currency
    final formatter = NumberFormat.currency(locale: 'id', symbol: 'Rp', decimalDigits: 0);
    
    if (groupBySavingsPot && savingsPots != null) {
      // Group transactions by savings pot ID
      final potAmounts = <String, double>{};
      final potNames = <String, String>{};
      
      for (final txn in transactions) {
        final potId = txn.savingsPotId;
        potAmounts[potId] = (potAmounts[potId] ?? 0) + txn.amount;
        
        // Find the pot name
        try {
          final pot = savingsPots.firstWhere(
            (pot) => pot.id == potId,
          );
          potNames[potId] = pot.name;
        } catch (_) {
          potNames[potId] = 'Unknown';
        }
      }
      
      // Filter out pots with no progress (amount = 0)
      potAmounts.removeWhere((key, value) => value <= 0);
      
      if (potAmounts.isEmpty) {
        return const Center(
          child: Text(
            'Tidak ada data pengeluaran per celengan',
            style: TextStyle(color: Colors.grey),
          ),
        );
      }
      
      // Sort by amount (descending)
      final sortedEntries = potAmounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      
      // Total amount
      final totalAmount = potAmounts.values.fold<double>(0, (sum, amount) => sum + amount);
      
      // Use the provided colors or default ones
      final colors = potColors ?? [
        Colors.purple,
        Colors.blue,
        Colors.green,
        Colors.amber,
        Colors.orange,
        Colors.red,
        Colors.teal,
        Colors.indigo,
        Colors.pink,
        Colors.brown,
        Colors.cyan,
        Colors.deepOrange,
        Colors.lime,
        Colors.deepPurple,
        Colors.lightBlue,
      ];
      
      return Column(
        children: sortedEntries.asMap().entries.map((entry) {
          final index = entry.key;
          final potId = entry.value.key;
          final amount = entry.value.value;
          final percentage = (amount / totalAmount) * 100;
          final potName = potNames[potId] ?? 'Unknown';
          final color = colors[index % colors.length];
          
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(potName),
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
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      );
    } else {
      // Original behavior - group by category
      final categories = categoryProvider.allCategories
          .where((cat) => cat.type == type)
          .toList();
      
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
          
          final categoryName = category?.name ?? 'Tidak Terkategori';
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
  }
  
  // Build recent pots section
  Widget _buildRecentPotsSection(SavingsProvider savingsProvider) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return SlideTransition(
          position: _slideAnimations[4],
          child: FadeTransition(
            opacity: _fadeAnimations[4],
            child: child,
          ),
        );
      },
      child: Column(
        key: _cardKeys[4],
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Celengan Anda',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            // View all button
            TextButton(
              onPressed: () {
                // Navigate to Pots tab (index 1)
                HomeScreen.navigateToTab(context, 1);
              },
              child: const Text('Lihat Semua'),
            ),
          ],
        ),
        
        const SizedBox(height: 4),
        
        // Pots list
        if (savingsProvider.status == SavingsStatus.loading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          )
          else if (savingsProvider.savingsPots.isEmpty)
          _buildEmptyState()
        else
          ListView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
              itemCount: savingsProvider.savingsPots.length > 3 ? 3 : savingsProvider.savingsPots.length,
            itemBuilder: (context, index) {
                return _buildPotCard(savingsProvider.savingsPots[index]);
            },
          ),
      ],
      ),
    );
  }
  
  // Build pot card
  Widget _buildPotCard(SavingsPot pot) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
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
                  child: Icon(
                          Icons.savings_outlined,
                          color: Theme.of(context).colorScheme.primary,
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
                          '${pot.progressPercentage.toStringAsFixed(1)}% dari target',
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
                        'dari ${Formatter.formatCurrency(pot.targetAmount!)}',
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
            'Belum ada celengan',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Buat celengan untuk mulai menabung',
            style: TextStyle(
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
} 