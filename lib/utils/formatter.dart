import 'package:intl/intl.dart';

class Formatter {
  // Currency formatter (IDR)
  static final _currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp',
    decimalDigits: 0,
  );
  
  // Date formatters
  static final _fullDateFormatter = DateFormat('dd MMMM yyyy');
  static final _shortDateFormatter = DateFormat('dd/MM/yyyy');
  static final _monthYearFormatter = DateFormat('MMMM yyyy');
  static final _timeFormatter = DateFormat('HH:mm');
  static final _dateTimeFormatter = DateFormat('dd MMM yyyy, HH:mm');
  
  // Format currency
  static String formatCurrency(double amount) {
    return _currencyFormatter.format(amount);
  }
  
  // Format as full date (e.g., "12 January 2023")
  static String formatFullDate(DateTime date) {
    return _fullDateFormatter.format(date);
  }
  
  // Format as short date (e.g., "12/01/2023")
  static String formatShortDate(DateTime date) {
    return _shortDateFormatter.format(date);
  }
  
  // Format as month and year (e.g., "January 2023")
  static String formatMonthYear(DateTime date) {
    return _monthYearFormatter.format(date);
  }
  
  // Format as time (e.g., "14:30")
  static String formatTime(DateTime date) {
    return _timeFormatter.format(date);
  }
  
  // Format as date and time (e.g., "12 Jan 2023, 14:30")
  static String formatDateTime(DateTime date) {
    return _dateTimeFormatter.format(date);
  }
  
  // Format remaining days until target date
  static String formatRemainingDays(DateTime targetDate) {
    final now = DateTime.now();
    final difference = targetDate.difference(now);
    
    if (difference.isNegative) {
      return 'Target date passed';
    }
    
    final days = difference.inDays;
    if (days == 0) {
      return 'Today';
    } else if (days == 1) {
      return '1 day left';
    } else {
      return '$days days left';
    }
  }
  
  // Format transaction amount with + or - prefix
  static String formatTransactionAmount(double amount, bool isIncome) {
    final prefix = isIncome ? '+ ' : '- ';
    return prefix + _currencyFormatter.format(amount);
  }
} 