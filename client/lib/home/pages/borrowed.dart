import 'package:flutter/material.dart';

class Borrowed extends StatefulWidget {
  const Borrowed({super.key});

  @override
  State<Borrowed> createState() => _BorrowedState();
}

class _BorrowedState extends State<Borrowed> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(),
    body: Text("Borrowed"),);
  }
}