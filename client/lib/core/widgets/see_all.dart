import 'package:flutter/material.dart';
import 'package:libraryapp/core/widgets/book_card.dart';
import 'package:libraryapp/core/widgets/book_view.dart';
import 'package:libraryapp/models/book.dart';

class SeeAll extends StatefulWidget {
  final List<Book> bookDetail;
  const SeeAll({super.key, required this.bookDetail});

  @override
  State<SeeAll> createState() => _SeeAllState();
}

class _SeeAllState extends State<SeeAll> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: GridView.builder(
        padding: EdgeInsets.all(10),
        itemCount: widget.bookDetail.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.7,
        ), // adjust card height/width),
        itemBuilder: (context, index) => ListTile(
          title: BookCard(
            book: widget.bookDetail[index],
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => BookView(id: index)),
              );
            },
          ),
        ),
      ),
    );
  }
}
