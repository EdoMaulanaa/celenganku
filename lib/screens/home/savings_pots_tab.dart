import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
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

class SavingsPotTabState extends State<SavingsPotTab> with TickerProviderStateMixin {
  bool _isLoading = false;
  late AnimationController _animationController;
  final TextEditingController _searchController = TextEditingController();
  bool _showSearchField = false;
  final FocusNode _searchFocusNode = FocusNode();
  
  // Animation controller for search field
  late AnimationController _searchAnimationController;
  late Animation<double> _searchWidthAnimation;
  late Animation<double> _searchOpacityAnimation;
  
  @override
  void initState() {
    super.initState();
    // Initialize locale for Indonesian date formatting
    initializeDateFormatting('id_ID', null);
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    // Initialize search animation controller
    _searchAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    // Create animations for search field
    _searchWidthAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _searchAnimationController,
      curve: Curves.easeOutCubic,
    ));
    
    _searchOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _searchAnimationController,
      curve: Curves.easeOut,
    ));
    
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
    _searchAnimationController.dispose();
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
    
    // Reset search field if it was showing
    if (_showSearchField) {
      setState(() {
        _showSearchField = false;
      });
      _searchAnimationController.value = 0.0; // Reset to beginning without animation
      _searchController.clear();
      Provider.of<SavingsProvider>(context, listen: false).clearSearch();
    }
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
        title: AnimatedBuilder(
          animation: _searchAnimationController,
          builder: (context, child) {
            return _showSearchField
                ? Opacity(
                    opacity: _searchOpacityAnimation.value,
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width * _searchWidthAnimation.value,
                      child: TextField(
                        controller: _searchController,
                        focusNode: _searchFocusNode,
                        autofocus: true,
                        decoration: InputDecoration(
                          hintText: 'Cari celengan...',
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 16),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? AnimatedOpacity(
                                  opacity: 1.0,
                                  duration: const Duration(milliseconds: 200),
                                  child: IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      _searchController.clear();
                                      Provider.of<SavingsProvider>(context, listen: false).clearSearch();
                                    },
                                  ),
                                )
                              : null,
                        ),
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  )
                : Opacity(
                    opacity: 1 - _searchOpacityAnimation.value,
                    child: const Text('Celengan'),
                  );
          },
        ),
        elevation: 0,
        actions: [
          // Search button
          IconButton(
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return ScaleTransition(scale: animation, child: child);
              },
              child: Icon(
                _showSearchField ? Icons.close : Icons.search,
                key: ValueKey<bool>(_showSearchField),
              ),
            ),
            onPressed: () {
              if (_showSearchField) {
                // Hide search field
                setState(() {
                  _showSearchField = false;
                });
                _searchAnimationController.reverse();
                _searchController.clear();
                Provider.of<SavingsProvider>(context, listen: false).clearSearch();
              } else {
                // Show search field
                setState(() {
                  _showSearchField = true;
                });
                _searchAnimationController.forward();
                // Focus the search field after showing it
                Future.delayed(const Duration(milliseconds: 100), () {
                  _searchFocusNode.requestFocus();
                });
              }
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
              'Tidak ditemukan celengan yang cocok dengan "${_searchController.text}"',
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
        return _buildSavingsPotItem(pot, index, currencyFormat);
      },
    );
  }
  
  Widget _buildSavingsPotItem(SavingsPot pot, int index, NumberFormat currencyFormat) {
    // Create staggered animation for each item with unique keys
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
                    'Saldo: ${currencyFormat.format(pot.currentBalance)}',
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
                      'Tanggal Target: ${DateFormat('d MMM yyyy', 'id_ID').format(pot.targetDate!)}',
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
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: showCreatePotDialog,
              icon: const Icon(Icons.add),
              label: const Text('Buat Celengan Baru'),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _showSearchField = true;
                });
                _searchAnimationController.forward();
                // Focus the search field after showing it
                Future.delayed(const Duration(milliseconds: 100), () {
                  _searchFocusNode.requestFocus();
                });
              },
              icon: const Icon(Icons.search),
              label: const Text('Cari Celengan'),
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
                    
                    // Current Balance
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
                            future: savingsProvider.calculateDailySavingsNeeded(pot.id),
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
                          future: savingsProvider.calculateDaysRemaining(pot.id),
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
                    
                    const SizedBox(height: 32),
                    
                    // Action buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildActionButton(
                          icon: Icons.add,
                          label: 'Tambah',
                          color: Colors.green,
                          onTap: () {
                            Navigator.pop(context);
                            // Show add transaction dialog
                            _showAddTransactionDialog(pot, TransactionType.income);
                          },
                        ),
                        _buildActionButton(
                          icon: Icons.remove,
                          label: 'Tarik',
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
                          label: 'Hapus',
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
                      'Dibuat: ${DateFormat('d MMM yyyy', 'id_ID').format(pot.createdAt)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      'Terakhir diperbarui: ${DateFormat('d MMM yyyy', 'id_ID').format(pot.updatedAt)}',
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
                    labelText: '${type == TransactionType.income ? 'Jumlah Tambahan' : 'Jumlah Penarikan'} *',
                    hintText: 'contoh: 500000',
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
                    labelText: 'Catatan (Opsional)',
                    hintText: 'contoh: Gaji, Hadiah, Belanja',
                  ),
                  maxLength: 100,
                ),
                
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
                Navigator.of(context).pop();
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
                      if (type == TransactionType.expense && amount > pot.currentBalance) {
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
                                    ? 'Berhasil menambahkan ke ${pot.name}'
                                    : 'Berhasil menarik dari ${pot.name}',
                              ),
                              backgroundColor: Colors.green,
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
                      type == TransactionType.income ? 'TAMBAH' : 'TARIK'
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
                              
                              // Refresh the list after slight delay
                              await Future.delayed(const Duration(milliseconds: 300));
                              
                              if (mounted) {
                                await _loadSavingsPots();
                                
                                // Show success message
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Celengan berhasil diperbarui!'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            } else {
                              if (!mounted) return;
                              setDialogState(() {
                                isSubmitting = false;
                                errorMessage = savingsProvider.errorMessage ??
                                    'Gagal memperbarui celengan';
                              });
                            }
                          } catch (e) {
                            if (!mounted) return;
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
                      : const Text('SIMPAN'),
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
              title: const Text('Buat Celengan Baru'),
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
                      autofocus: true,
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
                          print('Create button pressed');
                          
                          // Validate inputs
                          if (nameController.text.trim().isEmpty) {
                            setDialogState(() {
                              errorMessage = 'Silakan masukkan nama untuk celengan Anda';
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
                                  errorMessage = 'Jumlah target harus lebih besar dari nol';
                                });
                                print("Validation error: Target amount <= 0");
                                return;
                              }
                            } catch (e) {
                              setDialogState(() {
                                errorMessage = 'Silakan masukkan jumlah target yang valid';
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
                                    content: Text('Celengan berhasil dibuat!'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            } else {
                              if (!mounted) return;
                              setDialogState(() {
                                isSubmitting = false;
                                errorMessage = savingsProvider.errorMessage ??
                                    'Gagal membuat celengan';
                              });
                              print('Failed to create pot: ${savingsProvider.errorMessage}');
                            }
                          } catch (e) {
                            print('Exception creating pot: $e');
                            if (!mounted) return;
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
                      : const Text('BUAT'),
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
              Navigator.of(context).pop();
            },
            child: const Text('BATAL'),
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
                      Text('Menghapus...'),
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