import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../models/transaction_category.dart';
import '../models/savings_pot.dart';

class ChartUtils {
  /// Generates data for a pie chart showing transaction distribution by category
  static List<PieChartSectionData> generateCategoryPieCharts({
    required List<Transaction> transactions,
    required List<TransactionCategory> categories,
    required TransactionType type,
    double radius = 100,
    List<SavingsPot>? savingsPots,
    bool groupBySavingsPot = true,
  }) {
    // Filter transactions by type
    final filteredTransactions = transactions
        .where((txn) => txn.type == type)
        .toList();
    
    if (filteredTransactions.isEmpty) {
      return [
        PieChartSectionData(
          color: Colors.grey.shade300,
          value: 100,
          title: 'No data',
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.black54,
          ),
          radius: radius,
        ),
      ];
    }
    
    if (groupBySavingsPot && savingsPots != null) {
      // Group transactions by savings pot ID
      final potAmounts = <String, double>{};
      final potNames = <String, String>{};
      
      for (final txn in filteredTransactions) {
        final potId = txn.savingsPotId;
        potAmounts[potId] = (potAmounts[potId] ?? 0) + txn.amount;
        
        // Find the pot name
        try {
          final pot = savingsPots.firstWhere(
            (pot) => pot.id == potId,
            orElse: () => SavingsPot(
              id: potId,
              userId: '',
              name: 'Unknown',
              description: '',
              currentBalance: 0,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );
          potNames[potId] = pot.name;
        } catch (_) {
          potNames[potId] = 'Unknown';
        }
      }
      
      // Filter out pots with no progress (amount = 0)
      potAmounts.removeWhere((key, value) => value <= 0);
      
      if (potAmounts.isEmpty) {
        return [
          PieChartSectionData(
            color: Colors.grey.shade300,
            value: 100,
            title: 'No data',
            titleStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.black54,
            ),
            radius: radius,
          ),
        ];
      }
      
      // Sort by amount (descending) to ensure consistent color assignment
      final sortedEntries = potAmounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      
      // Calculate total amount
      final totalAmount = potAmounts.values.fold<double>(0, (sum, amount) => sum + amount);
      
      // Generate pie chart sections for savings pots
      final sections = <PieChartSectionData>[];
      
      // Define a list of distinct colors for different pots
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
      
      // Use sorted entries to ensure consistent color assignment with legend
      for (int i = 0; i < sortedEntries.length; i++) {
        final entry = sortedEntries[i];
        final potId = entry.key;
        final amount = entry.value;
        final percentage = (amount / totalAmount) * 100;
        final potName = potNames[potId] ?? 'Unknown';
        final color = potColors[i % potColors.length];
        
        sections.add(
          PieChartSectionData(
            color: color,
            value: amount,
            title: percentage >= 5 ? '${percentage.toStringAsFixed(1)}%' : '',
            titleStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            radius: radius,
            badgeWidget: percentage >= 5 
                ? Icon(
                    Icons.savings,
                    color: Colors.white,
                    size: 16,
                  )
                : null,
            badgePositionPercentageOffset: 0.9,
          ),
        );
      }
      
      return sections;
    }
    
    // Original behavior - group by category
    final categoryAmounts = <String, double>{};
    for (final txn in filteredTransactions) {
      if (txn.categoryId != null) {
        categoryAmounts[txn.categoryId!] = 
            (categoryAmounts[txn.categoryId!] ?? 0) + txn.amount;
      } else {
        // Handle transactions with no category
        categoryAmounts['uncategorized'] = 
            (categoryAmounts['uncategorized'] ?? 0) + txn.amount;
      }
    }
    
    // Calculate total amount
    final totalAmount = categoryAmounts.values.fold<double>(0, (sum, amount) => sum + amount);
    
    // Generate pie chart sections
    final sections = <PieChartSectionData>[];
    categoryAmounts.forEach((categoryId, amount) {
      // Find the category
      TransactionCategory? category;
      if (categoryId != 'uncategorized') {
        category = categories.firstWhere(
          (cat) => cat.id == categoryId,
          orElse: () => TransactionCategory(
            id: 'uncategorized',
            name: 'Uncategorized',
            type: type,
            iconName: 'help_outline',
            color: Colors.grey,
            createdAt: DateTime.now(),
          ),
        );
      }
      
      // Calculate percentage
      final percentage = (amount / totalAmount) * 100;
      
      // Get color from category or use default
      final color = categoryId == 'uncategorized'
          ? Colors.grey
          : category!.color ?? Colors.grey;
      
      // Get icon for the category
      final iconData = categoryId == 'uncategorized'
          ? Icons.help_outline
          : Icons.category;
      
      // Create pie chart section
      sections.add(
        PieChartSectionData(
          color: color,
          value: amount,
          title: percentage >= 5 ? '${percentage.toStringAsFixed(1)}%' : '',
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          radius: radius,
          badgeWidget: percentage >= 5 
              ? Icon(
                  iconData,
                  color: Colors.white,
                  size: 16,
                )
              : null,
          badgePositionPercentageOffset: 0.9,
        ),
      );
    });
    
    return sections;
  }

  /// Generates bar chart data for monthly savings
  static List<BarChartGroupData> generateMonthlySavingsBarChart({
    required List<Transaction> transactions,
    int numberOfMonths = 6,
  }) {
    final now = DateTime.now();
    final barGroups = <BarChartGroupData>[];
    
    // Create a map to store monthly totals
    final monthlySavings = <int, double>{};
    
    // Calculate start date (e.g., 6 months ago)
    final startDate = DateTime(now.year, now.month - numberOfMonths + 1, 1);
    
    // Filter and group transactions by month
    for (final txn in transactions) {
      if (txn.date.isAfter(startDate) || 
          (txn.date.year == startDate.year && txn.date.month == startDate.month)) {
        // Create a unique key for year-month
        final monthKey = txn.date.year * 100 + txn.date.month;
        
        // Add or subtract based on transaction type
        if (txn.type == TransactionType.income) {
          monthlySavings[monthKey] = (monthlySavings[monthKey] ?? 0) + txn.amount;
        } else {
          monthlySavings[monthKey] = (monthlySavings[monthKey] ?? 0) - txn.amount;
        }
      }
    }
    
    // Create bar chart groups for each month
    for (int i = 0; i < numberOfMonths; i++) {
      final month = now.month - i;
      final year = now.year - (month <= 0 ? 1 : 0);
      final adjustedMonth = month <= 0 ? month + 12 : month;
      
      final monthKey = year * 100 + adjustedMonth;
      final savings = monthlySavings[monthKey] ?? 0;
      
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: savings.abs(),
              color: savings >= 0 ? Colors.green : Colors.red,
              width: 16,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(3),
                topRight: Radius.circular(3),
              ),
            ),
          ],
        ),
      );
    }
    
    // Return in reverse order so the most recent month is on the right
    return barGroups.reversed.toList();
  }

  /// Generates line chart data for progress tracking of savings goals
  static LineChartData generateGoalLineChart({
    required SavingsPot pot,
    required List<Transaction> transactions,
    Color primaryColor = Colors.blue,
  }) {
    // Return empty chart if no target amount
    if (pot.targetAmount == null || pot.targetAmount == 0) {
      return LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
      );
    }
    
    final now = DateTime.now();
    final createdAt = pot.createdAt;
    final targetDate = pot.targetDate ?? now.add(const Duration(days: 30));
    
    // Calculate total duration in days
    final totalDuration = targetDate.difference(createdAt).inDays;
    final daysElapsed = now.difference(createdAt).inDays;
    
    // Target line points (straight line from start to target)
    final targetSpots = [
      FlSpot(0, 0), // Starting point
      FlSpot(totalDuration.toDouble(), pot.targetAmount!.toDouble()), // Target point
    ];
    
    // Actual progress line points
    final actualSpots = <FlSpot>[];
    
    // Sort transactions by date
    final sortedTransactions = List<Transaction>.from(transactions)
      ..sort((a, b) => a.date.compareTo(b.date));
    
    // Add starting point
    actualSpots.add(const FlSpot(0, 0));
    
    // Current cumulative amount
    double cumulativeAmount = 0;
    
    // Add points for each transaction date
    for (final txn in sortedTransactions) {
      final days = txn.date.difference(createdAt).inDays.toDouble();
      
      if (txn.type == TransactionType.income) {
        cumulativeAmount += txn.amount;
      } else {
        cumulativeAmount -= txn.amount;
      }
      
      actualSpots.add(FlSpot(days, cumulativeAmount));
    }
    
    // Add current point if not already added
    if (actualSpots.last.x != daysElapsed.toDouble()) {
      actualSpots.add(FlSpot(daysElapsed.toDouble(), cumulativeAmount));
    }
    
    // Fixed color for progress line that works in both light and dark mode
    final progressLineColor = Colors.blue;
    
    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        horizontalInterval: pot.targetAmount! / 5,
        verticalInterval: totalDuration / 5,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: Colors.grey.withOpacity(0.3),
            strokeWidth: 1,
          );
        },
        getDrawingVerticalLine: (value) {
          return FlLine(
            color: Colors.grey.withOpacity(0.3),
            strokeWidth: 1,
          );
        },
      ),
      titlesData: FlTitlesData(
        show: true,
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            getTitlesWidget: (value, meta) {
              // Show some dates on the bottom axis
              final date = createdAt.add(Duration(days: value.toInt()));
              if (value == 0 || value == totalDuration.toDouble() || value == totalDuration.toDouble() / 2) {
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    '${date.day}/${date.month}',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 45,
            getTitlesWidget: (value, meta) {
              // Only show a few values on the left axis
              if (value == 0 || value == pot.targetAmount || value == pot.targetAmount! / 2) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Text(
                    value >= 1000 ? '${(value / 1000).toStringAsFixed(1)}k' : value.toInt().toString(),
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ),
        topTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
      ),
      minX: 0,
      maxX: totalDuration.toDouble(),
      minY: 0,
      maxY: pot.targetAmount! * 1.1, // Add 10% margin on top
      lineBarsData: [
        // Target line
        LineChartBarData(
          spots: targetSpots,
          isCurved: false,
          color: Colors.grey.withOpacity(0.7),
          barWidth: 2,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(show: false),
        ),
        // Actual progress line
        LineChartBarData(
          spots: actualSpots,
          isCurved: true,
          color: progressLineColor,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) {
              return FlDotCirclePainter(
                radius: 4,
                color: progressLineColor,
                strokeWidth: 1,
                strokeColor: Colors.white,
              );
            },
          ),
          belowBarData: BarAreaData(
            show: true,
            color: progressLineColor.withOpacity(0.2),
          ),
        ),
      ],
    );
  }
} 