import 'package:args/args.dart';
import 'package:excel/excel.dart';
import 'package:tmind/tmind.dart' as tmind;

import 'dart:io';

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
    processFile(targetFile);
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

void processFile(String xlsFilePath) {
  try {
    final theFile = File(xlsFilePath);
    final xlsBytes = theFile.readAsBytesSync();
    print("File length in bytes: ${xlsBytes.length}");

    final excelFile = Excel.decodeBytes(xlsBytes);

    print("The keys");
    excelFile.tables.forEach((key, value) {
      print("${key}: ${value}");
    });

    final firstSheet = excelFile.sheets["member_reconcilation_report"];

    print("Max columns: ${firstSheet?.maxColumns}");
    print("Max rows: ${firstSheet?.maxRows}\n");

    final docTitle = firstSheet?.rows[0][0]?.value;
    final settlementDay = firstSheet?.rows[1][0]?.value;
    final finInstns = firstSheet?.rows[2][0]?.value;

    final dataCol = firstSheet?.rows[3].map((e) => e?.value).toList();

    print("docTitle: $docTitle"); //  = firstSheet?.rows[0][0]?.value;
    print("settlementDay: $settlementDay"); //  = firstSheet?.rows[1][0]?.value;
    print("finInstns: $finInstns"); //  = firstSheet?.rows[2][0]?.value;
    print("dataCol: $dataCol"); //  = firstSheet?.rows[3][0]?.value;
  } on PathNotFoundException catch (_) {
    print("\nPath ${xlsFilePath} not found");
    exit(1);
  }
}

const rowIssuer = 0;
const acquirer = 1;

// 0       1         2    3            4       5          6                7```` 8           9            10           11                 12        13          14              15         16
//[Issuer, Acquirer, MTI, Card_Number, Amount, Currency, Transaction_Date, null, Transaction_Description, Terminal_ID, Transaction_Place, STAN_F11, Refnum_F37, Authidresp_F38, Fe_utrnno, Bo_utrnno]
