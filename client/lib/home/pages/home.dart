import 'package:flutter/material.dart';
import 'package:libraryapp/core/theme/app_pallete.dart';
import 'package:libraryapp/core/widgets/book_section.dart';
import 'package:libraryapp/models/category.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  @override
  Widget build(BuildContext context) {

    final categories = [
      Category(id: 'c1', name: 'Fiction'),
      Category(id: 'c2', name: 'Science'),
      Category(id: 'c3', name: 'History'),
      Category(id: 'c4', name: 'Programming'),
      Category(id: 'c5', name: 'Maths'),
    ];
    final trendingBooks = [
      {'title': 'Clean Code', 'author': 'Robert C. Martin'},
      {'title': 'Flutter in Action', 'author': 'Eric Windmill'},
      {'title': 'Sapiens', 'author': 'Yuval Noah Harari'},
      {'title': 'Atomic Habits', 'author': 'James Clear'},
      {'title': 'The Alchemist', 'author': 'Paulo Coelho'},
      {'title': 'Deep Work', 'author': 'Cal Newport'},
      {'title': 'Extra Book', 'author': 'Hidden'}, 
    ];
    final suggestedBooks = [
      {'title': 'Clean Code', 'author': 'Robert C. Martin'},
      {'title': 'Flutter in Action', 'author': 'Eric Windmill'},
      {'title': 'Sapiens', 'author': 'Yuval Noah Harari'},
      {'title': 'Atomic Habits', 'author': 'James Clear'},
      {'title': 'The Alchemist', 'author': 'Paulo Coelho'},
      {'title': 'Deep Work', 'author': 'Cal Newport'},
      {'title': 'Extra Book', 'author': 'Hidden'}, 
    ];


    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [const Text("XYZ Librart"), Icon(Icons.notifications)],
        ),
        backgroundColor: Pallete.appBarBackground,
      ),
      body: Padding(
        padding: const EdgeInsets.only(left: 10, right: 10),
        child: Column(
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Pallete.btnBackground,
                      foregroundColor: Pallete.btnTextColor,
                    ),
                    onPressed: () {},
                    child: Row(
                      children: [Icon(Icons.book), Text("Categories")],
                    ),
                  ),
                  ...categories.map(
                    (category) => Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ElevatedButton(
                        onPressed: () {},
                        child: Row(
                          children: [Icon(Icons.book), Text(category.name)],
                        ),
                      ),
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Pallete.btnBackground,
                      foregroundColor: Pallete.btnTextColor,
                    ),
                    onPressed: () {},
                    child: Row(children: [Icon(Icons.book), Text("More")]),
                  ),
                ],
              ),
            ),
            BookSection(booksDetail: trendingBooks,heading: 'Trending Books',),
            BookSection(booksDetail: suggestedBooks,heading: 'Recommended For you')
          ],
        ),
      ),
    );
  }
}
