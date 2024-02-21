class TransactionData {
  final String issuer;
  final String acquirer;
  final DateTime transactionDateTime;
  final double amount;
  final String rrn;
  final String terminalId;
  final String transactionPlace;
  final String cardNumber;

  TransactionData({
    required this.issuer,
    required this.acquirer,
    required this.transactionDateTime,
    required this.amount,
    required this.rrn,
    required this.terminalId,
    required this.transactionPlace,
    required this.cardNumber,
  });

  Map<String, dynamic> toJson() => {
        "issuer": issuer,
        "acquirer": acquirer,
        "transactionDateTime": transactionDateTime,
        "amount": amount,
        "rrn": rrn,
        "terminalId": terminalId,
        "transactionPlace": transactionPlace,
        "cardNumber": cardNumber,
      };
}
