class TransactionSummary {
  final double totalAmount;
  final String terminalId;
  final int numberOfTransactions;

  TransactionSummary({
    required this.totalAmount,
    required this.terminalId,
    required this.numberOfTransactions,
  });

  Map<String, dynamic> toJson() => {
        "totalAmount": totalAmount,
        "terminalId": terminalId,
        "numberOfTransactions": numberOfTransactions,
      };
}
