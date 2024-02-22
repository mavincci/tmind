import 'package:args/args.dart';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:sprintf/sprintf.dart';
import 'package:tmind/tmind.dart' as tmind;

import 'dart:io';

import 'transaction_data.dart';
import 'transaction_summary.dart';

void main(List<String> arguments) {
  var parser = ArgParser();

  parser.addSeparator('===== Targets');

  parser.addOption(
    "target",
    mandatory: true,
    abbr: 't',
    help: "Daily transaction report file.",
  );

  try {
    final result = parser.parse(arguments);

    final targetFile = result['target'];

    print('Parsing ${targetFile}');
    final txns = processFile(targetFile);

    processTransactionData(txns);
  } on FormatException catch (_) {
    print("Improper usage of arguments\n");
    print("Usage: tmind [args]\n");
    print(parser.usage);
    print("");
    exit(1);
  } on ArgumentError catch (err) {
    print(err.message);
    print("");

    print(parser.usage);
    print("");

    exit(1);
  }
}

Map<String, List<TransactionData>> categorizeByTerminalId(
    List<TransactionData> txns) {
  final tempMap = <String, List<TransactionData>>{};

  txns.forEach((txn) {
    final noData = tempMap[txn.terminalId] == null;

    if (noData) tempMap[txn.terminalId] = [];

    tempMap[txn.terminalId]!.add(txn);
  });

  return tempMap;
}

void processTransactionData(List<TransactionData> txns) {
  final settledTxns = txns
      .where((element) => element.issuer.compareTo("Arifpay") != 0)
      .where((element) => element.issuer.compareTo("EthSwitch") != 0)
      .where((element) => element.amount > 5);

  // settledTxns.forEach((element) {
  //   print("${element.rrn}: ${element.transactionPlace}: ${element.amount}");
  // });

  // print(settledTxns.first.toJson());

  final categorized = categorizeByTerminalId(settledTxns.toList());

  final summaries = categorized.entries
      .map((entry) => TransactionSummary(
          totalAmount: entry.value
              .fold(0.0, (previousValue, txn) => txn.amount + previousValue),
          terminalId: entry.key,
          numberOfTransactions: entry.value.length))
      .toList();

  summaries.sort((a, b) => b.totalAmount.compareTo(a.totalAmount));

  saveSummaryData(summaries);

  // categorized.entries.forEach((entry) {
  //   // print("\n-------> ${entry.key}");

  //   final st = sprintf("%s ----- %5i ----- ETB %10.02f", [
  //     entry.key,
  //     entry.value.length,
  //     entry.value.fold(0.0, (previousValue, txn) => txn.amount + previousValue)
  //   ]);

  //   print(st);

  //   // entry.value.forEach((txn) {
  //   //   print(
  //   //       "${txn.transactionDateTime} ${txn.rrn}: ${txn.transactionPlace}: ${txn.amount}");
  //   // });
  //   // print("\nNumber of txns: ${entry.value.length}");
  //   // print(
  //   // "Total amount: ${entry.value.fold(0.0, (previousValue, txn) => txn.amount + previousValue).toStringAsFixed(2)}");
  // });
}

void saveSummaryData(List<TransactionSummary> summaries) {
  // summaries.forEach((element) {
  //   final st = sprintf("%s ----- %5i ----- ETB %10.02f", [
  //     element.terminalId,
  //     element.numberOfTransactions,
  //     element.totalAmount,
  //   ]);

  //   print(st);
  // });

  print("Generating output ...");

  final outXlsx = Excel.createExcel();
  final sheet = outXlsx["Sheet1"];

  summaries.indexed.forEach((element) {
    final i = element.$1;
    final txnSummary = element.$2;

    final terminalIdCell =
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: i));

    terminalIdCell.value = TextCellValue(txnSummary.terminalId);

    final noOfTransactionsCell =
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: i));
    noOfTransactionsCell.value =
        TextCellValue(txnSummary.numberOfTransactions.toString());

    final totalAmountCell =
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: i));
    totalAmountCell.value =
        TextCellValue(txnSummary.totalAmount.toStringAsFixed(2));
  });

  // for (var i = 0; i < summaries.length; ++i) {
  //   final terminalIdCell =
  //       sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: i + 1));

  //       terminalIdCell.value = TextCellValue(summaries[i].terminalId);

  //   final noOfTransacrionsCell =
  //       sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: i + 1));
  //       noOfTransacrionsCell.value = IntCellValue(su)

  //   final totalTransactionsCell =
  //       sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: i + 1));
  // }

  print("Finished generating output");
  print("Creating output file ...");

  final outXlsxBytes = outXlsx.save(fileName: "testing file");

  final outFile = File("output.xlsx");

  outFile.writeAsBytesSync(outXlsxBytes!);

  print("Finished creating output file");
}

List<TransactionData> processFile(String xlsFilePath) {
  try {
    final theFile = File(xlsFilePath);
    final xlsBytes = theFile.readAsBytesSync();
    print("File length in bytes: ${xlsBytes.length}");

    final excelFile = Excel.decodeBytes(xlsBytes);

    // print("The keys");
    // excelFile.tables.forEach((key, value) {
    //   print("${key}: ${value}");
    // });

    final firstSheet = excelFile.sheets["member_reconcilation_report"];

    print("Max columns: ${firstSheet?.maxColumns}");
    print("Max rows: ${firstSheet?.maxRows}\n");

    final docTitle = firstSheet!.rows[0][0]?.value;
    final settlementDay = firstSheet.rows[1][0]?.value;
    final finInstns = firstSheet.rows[2][0]?.value;

    final dataCol = firstSheet.rows[3].map((e) => e?.value).toList();

    // print("docTitle: $docTitle"); //  = firstSheet?.rows[0][0]?.value;
    // print("settlementDay: $settlementDay"); //  = firstSheet?.rows[1][0]?.value;
    // print("finInstns: $finInstns"); //  = firstSheet?.rows[2][0]?.value;
    // print("dataCol: $dataCol"); //  = firstSheet?.rows[3][0]?.value;

    final txns = <TransactionData>[];

    // for (var r = 4; r < 20; ++r) {
    for (var r = 4; r < firstSheet.rows.length; ++r) {
      final row = firstSheet.rows[r];

      final txn = TransactionData(
        issuer: row[rowIssuer]?.value.toString() ?? "unrecognized",
        acquirer: row[rowAcquirer]?.value.toString() ?? "unrecognized",
        transactionDateTime: ethSwitchDateTimeFormat.parse(
            row[rowTransactionDateTime]?.value.toString() ?? "unrecognized"),
        amount:
            double.parse(row[rowAmount]?.value.toString() ?? "unrecognized"),
        rrn: row[rowRRN]?.value.toString() ?? "unrecognized",
        terminalId: row[rowTerminalId]?.value.toString() ?? "unrecognized",
        transactionPlace:
            row[rowTransactionPlace]?.value.toString() ?? "unrecognized",
        cardNumber: row[rowCardNumber]?.value.toString() ?? "unrecognized",
      );
      txns.add(txn);
    }

    return txns;
  } on PathNotFoundException catch (_) {
    print("\nPath ${xlsFilePath} not found");
    exit(1);
  } on FormatException catch (err) {
    print(err.message);
    exit(1);
  }
}

const rowIssuer = 0;
const rowAcquirer = 1;
const rowCardNumber = 3;
const rowAmount = 4;
const rowTransactionDateTime = 6;
const rowTerminalId = 9;
const rowTransactionPlace = 10;
const rowRRN = 12;

final ethSwitchDateTimeFormat = DateFormat("dd.MM.yyyy HH:mm:ss");
