import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:libraryapp/core/theme/app_pallete.dart';
import 'package:libraryapp/core/widgets/book_section.dart';
import 'package:libraryapp/data/repository/book_repository.dart';
import 'package:libraryapp/home/pages/search.dart';
import 'package:libraryapp/models/category.dart';

class Home extends ConsumerStatefulWidget {
  const Home({super.key});

  @override
  ConsumerState<Home> createState() => _HomeState();
}

class _HomeState extends ConsumerState<Home> {
  @override
  Widget build(BuildContext context) {
    final categories = [
      Category(id: 'c1', name: 'Fiction'),
      Category(id: 'c2', name: 'Science'),
      Category(id: 'c3', name: 'History'),
      Category(id: 'c4', name: 'Programming'),
    ];
    final booksAsync = ref.watch(fetchAllBooksProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [const Text("XYZ Library"), Icon(Icons.notifications)],
        ),
        backgroundColor: Pallete.appBarBackground,
      ),
      body: SingleChildScrollView(
        child: Padding(
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
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    Search(currentCategory: category.name),
                              ),
                            );
                          },
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
              booksAsync.when(
                data: (books) {
                  return Column(
                    children: [
                      BookSection(
                        booksDetail: books, // Display all books as trending for now
                        heading: 'Trending Books',
                      ),
                      BookSection(
                        booksDetail: books.reversed.toList(), // Display reversed for recommended
                        heading: 'Recommended For you',
                      ),
                    ],
                  );
                },
                error: (err, stack) => Center(child: Text(err.toString())),
                loading: () => const Center(child: CircularProgressIndicator()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
