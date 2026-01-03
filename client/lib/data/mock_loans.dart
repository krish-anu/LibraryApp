import 'package:libraryapp/models/loan.dart';

final mockLoans = <Loan>[
  Loan(
    id: 'l1',
    bookId: '1', // Clean Code
    memberId: 'm1',
    loanDate: DateTime(2023, 12, 1),
    returnedDate: DateTime(2023, 12, 15),
  ),
  Loan(
    id: 'l2',
    bookId: '3', // Sapiens
    memberId: 'm1',
    loanDate: DateTime(2025, 12, 26),
    returnedDate: DateTime(2024, 1, 19),
  ),
  Loan(
    id: 'l3',
    bookId: '5', // The Alchemist
    memberId: 'm1',
    loanDate: DateTime(2024, 1, 10),
    returnedDate: DateTime(2024, 1, 24),
  ),
  Loan(
    id: 'l4',
    bookId: '7', // Dart Apprentice
    memberId: 'm1',
    loanDate: DateTime(2026, 1, 1),
    returnedDate: DateTime(2026, 1, 1),
  ),
  Loan(
    id: 'l5',
    bookId: '10', // Eleven Minutes
    memberId: 'm1',
    loanDate: DateTime(2024, 1, 20),
    returnedDate: DateTime(2024, 2, 3),
  ),
  Loan(
    id: 'l6',
    bookId: '12', // Design Patterns
    memberId: 'm1',
    loanDate: DateTime(2024, 1, 25),
    returnedDate: DateTime(2024, 2, 8),
  ),
  Loan(
    id: 'l7',
    bookId: '15', // Effective Java
    memberId: 'm1',
    loanDate: DateTime(2024, 2, 1),
    returnedDate: DateTime(2024, 2, 15),
  ),
];
