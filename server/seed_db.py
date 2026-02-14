import sys
import os

# Ensure the server directory is in the python path
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from app.database import SessionLocal, engine
from app.models.book import Book
from app.models.loan import Loan
from app.models.users import User
from app.models.category import Category
from app.models.base import Base
from sqlalchemy import text
from datetime import date

# Mock Loans Data
loans_data = [
    {
        "id": "l1",
        "book_id": "1",
        "member_id": "m1",
        "loan_date": date(2026, 1, 1),
        "returned_date": date(2026, 1, 15),  # Due in 6 days
    },
    {
        "id": "l2",
        "book_id": "3",
        "member_id": "m1",
        "loan_date": date(2026, 1, 5),
        "returned_date": date(2026, 1, 19),  # Due in 10 days
    },
    {
        "id": "l3",
        "book_id": "5",
        "member_id": "m1",
        "loan_date": date(2026, 1, 7),
        "returned_date": date(2026, 1, 21),  # Due in 12 days
    },
    {
        "id": "l4",
        "book_id": "7",
        "member_id": "m1",
        "loan_date": date(2025, 12, 28),
        "returned_date": date(2026, 1, 11),  # Due in 2 days (due soon)
    },
    {
        "id": "l5",
        "book_id": "10",
        "member_id": "m1",
        "loan_date": date(2025, 12, 20),
        "returned_date": date(2026, 1, 3),  # Overdue by 6 days
    },
    {
        "id": "l6",
        "book_id": "12",
        "member_id": "m1",
        "loan_date": date(2025, 12, 15),
        "returned_date": date(2025, 12, 29),  # Overdue by 11 days
    },
    {
        "id": "l7",
        "book_id": "15",
        "member_id": "m1",
        "loan_date": date(2026, 1, 8),
        "returned_date": date(2026, 1, 22),  # Due in 13 days
    },
]

books_data = [
    {
        "id": "1",
        "title": "Clean Code",
        "author": "Robert C. Martin",
        "category_id": "1",
        "description": "Even bad code can function. But if code isn't clean, it can bring a development organization to its knees. Every year, countless hours and significant resources are lost because of poorly written code. But it doesn't have to be that way.",
        "rating": 4.8,
        "publication_year": 2008,
        "copies_owned": 0,
        "image": "client/assets/book/book_cover.webp",
        "language": "English",
        "pages": 464,
        "rating_count": 12500,
    },
    {
        "id": "2",
        "title": "Flutter in Action",
        "author": "Eric Windmill",
        "category_id": "1",
        "description": "Flutter in Action teaches you to build professional-quality mobile applications using the Flutter SDK and the Dart programming language. You'll begin with a quick tour of Dart essentials and then dive into engaging, well-described techniques for building beautiful user interfaces using Flutter's huge collection of built-in widgets.",
        "rating": 4.5,
        "publication_year": 2019,
        "copies_owned": 0,
        "image": "client/assets/book/book_cover.webp",
        "language": "English",
        "pages": 368,
        "rating_count": 890,
    },
    {
        "id": "3",
        "title": "Sapiens",
        "author": "Yuval Noah Harari",
        "category_id": "2",
        "description": 'From a renowned historian comes a groundbreaking narrative of humanity’s creation and evolution—a #1 international bestseller—that explores the ways in which biology and history have defined us and enhanced our understanding of what it means to be "human."',
        "rating": 4.7,
        "publication_year": 2011,
        "copies_owned": 4,
        "image": "client/assets/book/book_cover.webp",
        "language": "English",
        "pages": 443,
        "rating_count": 45200,
    },
    {
        "id": "4",
        "title": "A Brief History of Time",
        "author": "Stephen Hawking",
        "category_id": "3",
        "description": "A landmark volume in science writing by one of the great minds of our time, Stephen Hawking’s book explores such profound questions as: How did the universe begin—and what made its start possible? Does time always flow forward? Is the universe unending—or are there boundaries?",
        "rating": 4.6,
        "publication_year": 1988,
        "copies_owned": 1,
        "image": "client/assets/book/book_cover.webp",
        "language": "English",
        "pages": 212,
        "rating_count": 38700,
    },
    {
        "id": "5",
        "title": "The Alchemist",
        "author": "Paulo Coelho",
        "category_id": "4",
        "description": "Combining magic, mysticism, wisdom and wonder into an inspiring tale of self-discovery, The Alchemist has become a modern classic, selling millions of copies around the world and transforming the lives of countless readers across generations.",
        "rating": 4.9,
        "publication_year": 1988,
        "copies_owned": 5,
        "image": "client/assets/book/book_cover.webp",
        "language": "Portuguese",
        "pages": 197,
        "rating_count": 98500,
    },
    {
        "id": "6",
        "title": "Clean Architecture",
        "author": "Robert C. Martin",
        "category_id": "1",
        "description": "By applying universal rules of software architecture, you can dramatically improve developer productivity throughout the life of any software system. Now, building upon the success of his best-selling books Clean Code and The Clean Coder, legendary software craftsman Robert C. Martin (“Uncle Bob”) reveals these rules and helps you apply them.",
        "rating": 4.7,
        "publication_year": 2017,
        "copies_owned": 3,
        "image": "client/assets/book/book_cover.webp",
        "language": "English",
        "pages": 432,
        "rating_count": 8900,
    },
    {
        "id": "7",
        "title": "Dart Apprentice",
        "author": "Eric Windmill",
        "category_id": "1",
        "description": "Dart Apprentice will teach you all the basic concepts you need to master this language. Follow along with the easy and fun tutorials to begin your journey to becoming a Dart master.",
        "rating": 4.6,
        "publication_year": 2020,
        "copies_owned": 6,
        "image": "client/assets/book/book_cover.webp",
        "language": "English",
        "pages": 324,
        "rating_count": 1250,
    },
    {
        "id": "8",
        "title": "Homo Deus",
        "author": "Yuval Noah Harari",
        "category_id": "2",
        "description": "Yuval Noah Harari, author of the critically-acclaimed New York Times bestseller and international phenomenon Sapiens, returns with an equally original, compelling, and provocative book, turning his focus toward humanity’s future, and our quest to upgrade humans into gods.",
        "rating": 4.6,
        "publication_year": 2015,
        "copies_owned": 2,
        "image": "client/assets/book/book_cover.webp",
        "language": "English",
        "pages": 450,
        "rating_count": 28300,
    },
    {
        "id": "9",
        "title": "The Universe in a Nutshell",
        "author": "Stephen Hawking",
        "category_id": "3",
        "description": "Stephen Hawking’s phenomenal, multimillion-copy bestseller, A Brief History of Time, introduced the ideas of this brilliant theoretical physicist to readers all over the world. Now, in a major publishing event, Hawking returns with a lavishly illustrated sequel that unravels the mysteries of the major breakthroughs that have occurred in the years since the release of his acclaimed first book.",
        "rating": 4.5,
        "publication_year": 2001,
        "copies_owned": 3,
        "image": "client/assets/book/book_cover.webp",
        "language": "English",
        "pages": 224,
        "rating_count": 15600,
    },
    {
        "id": "10",
        "title": "Eleven Minutes",
        "author": "Paulo Coelho",
        "category_id": "4",
        "description": "Eleven Minutes is the story of Maria, a young girl from a Brazilian village, whose first innocent brushes with love leave her heartbroken. At a tender age, she becomes convinced that she will never find true love, instead believing that “love is a terrible thing that will make you suffer. . . .”",
        "rating": 4.4,
        "publication_year": 2003,
        "copies_owned": 4,
        "image": "client/assets/book/book_cover.webp",
        "language": "Portuguese",
        "pages": 273,
        "rating_count": 21400,
    },
    {
        "id": "11",
        "title": "Refactoring",
        "author": "Martin Fowler",
        "category_id": "1",
        "description": 'Refactoring is a controlled technique for improving the design of an existing code base. Its essence is applying a series of small behavior-preserving transformations, each of which "too small to be worth doing". However, the cumulative effect of each of these transformations is quite significant.',
        "rating": 4.7,
        "publication_year": 1999,
        "copies_owned": 3,
        "image": "client/assets/book/book_cover.webp",
        "language": "English",
        "pages": 448,
        "rating_count": 9800,
    },
    {
        "id": "12",
        "title": "Design Patterns",
        "author": "Erich Gamma",
        "category_id": "1",
        "description": "Capturing a wealth of experience about the design of object-oriented software, four top-notch designers present a catalog of simple and succinct solutions to commonly occurring design problems.",
        "rating": 4.8,
        "publication_year": 1994,
        "copies_owned": 5,
        "image": "client/assets/book/book_cover.webp",
        "language": "English",
        "pages": 395,
        "rating_count": 14200,
    },
    {
        "id": "13",
        "title": "The Pragmatic Programmer",
        "author": "Andrew Hunt",
        "category_id": "1",
        "description": "The Pragmatic Programmer cuts through the increasing specialization and technicalities of modern software development to examine the core process--taking a requirement and producing working, maintainable code that delights its users.",
        "rating": 4.9,
        "publication_year": 1999,
        "copies_owned": 4,
        "image": "client/assets/book/book_cover.webp",
        "language": "English",
        "pages": 352,
        "rating_count": 18700,
    },
    {
        "id": "14",
        "title": "Introduction to Algorithms",
        "author": "Thomas H. Cormen",
        "category_id": "1",
        "description": "This title covers a broad range of algorithms in depth, yet makes their design and analysis accessible to all levels of readers. Each chapter is relatively self-contained and can be used as a unit of study.",
        "rating": 4.6,
        "publication_year": 2009,
        "copies_owned": 2,
        "image": "client/assets/book/book_cover.webp",
        "language": "English",
        "pages": 1312,
        "rating_count": 7800,
    },
    {
        "id": "15",
        "title": "Effective Java",
        "author": "Joshua Bloch",
        "category_id": "1",
        "description": "Are you looking for a deeper understanding of the Java programming language so that you can write code that is clearer, more correct, more robust, and more reusable? Look no further than Effective Java.",
        "rating": 4.8,
        "publication_year": 2017,
        "copies_owned": 3,
        "image": "client/assets/book/book_cover.webp",
        "language": "English",
        "pages": 416,
        "rating_count": 11200,
    },
    {
        "id": "16",
        "title": "1984",
        "author": "George Orwell",
        "category_id": "4",
        "description": "Among the seminal texts of the 20th century, Nineteen Eighty-Four is a rare work that grows more haunting as its futuristic purgatory becomes more real.",
        "rating": 4.7,
        "publication_year": 1949,
        "copies_owned": 6,
        "image": "client/assets/book/book_cover.webp",
        "language": "English",
        "pages": 328,
        "rating_count": 67500,
    },
    {
        "id": "17",
        "title": "To Kill a Mockingbird",
        "author": "Harper Lee",
        "category_id": "4",
        "description": 'The unforgettable novel of a childhood in a sleepy Southern town and the crisis of conscience that rocked it. "To Kill a Mockingbird" became both an instant bestseller and a critical success when it was first published in 1960.',
        "rating": 4.9,
        "publication_year": 1960,
        "copies_owned": 5,
        "image": "client/assets/book/book_cover.webp",
        "language": "English",
        "pages": 376,
        "rating_count": 95300,
    },
    {
        "id": "18",
        "title": "The Great Gatsby",
        "author": "F. Scott Fitzgerald",
        "category_id": "4",
        "description": "The Great Gatsby, F. Scott Fitzgerald’s third book, stands as the supreme achievement of his career. This exemplary novel of the Jazz Age has been acclaimed by generations of readers.",
        "rating": 4.4,
        "publication_year": 1925,
        "copies_owned": 4,
        "image": "client/assets/book/book_cover.webp",
        "language": "English",
        "pages": 180,
        "rating_count": 54200,
    },
    {
        "id": "19",
        "title": "Pride and Prejudice",
        "author": "Jane Austen",
        "category_id": "4",
        "description": 'Since its immediate success in 1813, Pride and Prejudice has remained one of the most popular novels in the English language. Jane Austen called this brilliant work "her own darling child".',
        "rating": 4.6,
        "publication_year": 1813,
        "copies_owned": 3,
        "image": "client/assets/book/book_cover.webp",
        "language": "English",
        "pages": 432,
        "rating_count": 48900,
    },
    {
        "id": "20",
        "title": "The Catcher in the Rye",
        "author": "J.D. Salinger",
        "category_id": "4",
        "description": "The hero-narrator of The Catcher in the Rye is an ancient child of sixteen, a native New Yorker named Holden Caulfield. Through circumstances that tend to preclude adult, secondhand description, he leaves his prep school in Pennsylvania and goes underground in New York City for three days.",
        "rating": 4.0,
        "publication_year": 1951,
        "copies_owned": 2,
        "image": "client/assets/book/book_cover.webp",
        "language": "English",
        "pages": 277,
        "rating_count": 32100,
    },
    {
        "id": "21",
        "title": "Cosmos",
        "author": "Carl Sagan",
        "category_id": "3",
        "description": "Cosmos is one of the bestselling science books of all time. In clear-eyed prose, Sagan reveals a jewel-like blue world inhabited by a life form that is just beginning to discover its own identity and to venture into the vast ocean of space.",
        "rating": 4.8,
        "publication_year": 1980,
        "copies_owned": 4,
        "image": "client/assets/book/book_cover.webp",
        "language": "English",
        "pages": 365,
        "rating_count": 29800,
    },
    {
        "id": "22",
        "title": "The Selfish Gene",
        "author": "Richard Dawkins",
        "category_id": "3",
        "description": "The Selfish Gene caused a wave of excitement among biologists and the general public when it was first published in 1976. Its vivid rendering of a gene’s eye view of life, in lucid and energetic prose, gathered together the strands of thought about the nature of natural selection.",
        "rating": 4.5,
        "publication_year": 1976,
        "copies_owned": 3,
        "image": "client/assets/book/book_cover.webp",
        "language": "English",
        "pages": 544,
        "rating_count": 25600,
    },
    {
        "id": "23",
        "title": "Silent Spring",
        "author": "Rachel Carson",
        "category_id": "3",
        "description": "Rachel Carson’s Silent Spring was first published in three serialized excerpts in the New Yorker in June of 1962. The book appeared in September of that year and the outcry that followed its publication forced the banning of DDT and spurred revolutionary changes in the laws affecting our air, land, and water.",
        "rating": 4.6,
        "publication_year": 1962,
        "copies_owned": 2,
        "image": "client/assets/book/book_cover.webp",
        "language": "English",
        "pages": 400,
        "rating_count": 18400,
    },
    {
        "id": "24",
        "title": "Thinking, Fast and Slow",
        "author": "Daniel Kahneman",
        "category_id": "3",
        "description": "The major New York Times bestseller that has captivated the world. In the international bestseller, Thinking, Fast and Slow, Daniel Kahneman, the renowned psychologist and winner of the Nobel Prize in Economics, takes us on a groundbreaking tour of the mind.",
        "rating": 4.6,
        "publication_year": 2011,
        "copies_owned": 5,
        "image": "client/assets/book/book_cover.webp",
        "language": "English",
        "pages": 499,
        "rating_count": 42100,
    },
    {
        "id": "25",
        "title": "Guns, Germs, and Steel",
        "author": "Jared Diamond",
        "category_id": "2",
        "description": 'In this "artful, informative, and delightful" (William H. McNeill, New York Review of Books) book, Jared Diamond convincingly argues that geographical and environmental factors shaped the modern world.',
        "rating": 4.4,
        "publication_year": 1997,
        "copies_owned": 3,
        "image": "client/assets/book/book_cover.webp",
        "language": "English",
        "pages": 528,
        "rating_count": 35700,
    },
    {
        "id": "26",
        "title": "The Silk Roads",
        "author": "Peter Frankopan",
        "category_id": "2",
        "description": "Far more than a history of the Silk Roads, this book is truly a revelatory new history of the world, promising to destabilize notions of where we come from and where we are headed next.",
        "rating": 4.7,
        "publication_year": 2015,
        "copies_owned": 4,
        "image": "client/assets/book/book_cover.webp",
        "language": "English",
        "pages": 636,
        "rating_count": 19200,
    },
    {
        "id": "27",
        "title": "1491",
        "author": "Charles C. Mann",
        "category_id": "2",
        "description": "In this groundbreaking work of science, history, and archaeology, Charles C. Mann radically alters our understanding of the Americas before the arrival of Columbus in 1492.",
        "rating": 4.6,
        "publication_year": 2005,
        "copies_owned": 2,
        "image": "client/assets/book/book_cover.webp",
        "language": "English",
        "pages": 541,
        "rating_count": 12800,
    },
    {
        "id": "28",
        "title": "Steve Jobs",
        "author": "Walter Isaacson",
        "category_id": "5",
        "description": "Based on more than forty interviews with Jobs conducted over two years—as well as interviews with more than a hundred family members, friends, adversaries, competitors, and colleagues—Walter Isaacson has written a riveting story of the roller-coaster life and searingly intense personality of a creative entrepreneur.",
        "rating": 4.8,
        "publication_year": 2011,
        "copies_owned": 5,
        "image": "client/assets/book/book_cover.webp",
        "language": "English",
        "pages": 656,
        "rating_count": 56400,
    },
    {
        "id": "29",
        "title": "Einstein",
        "author": "Walter Isaacson",
        "category_id": "5",
        "description": "By the author of the acclaimed bestsellers Benjamin Franklin and Steve Jobs, this is the definitive biography of Albert Einstein. How did his mind work? What made him a genius? Isaacson’s biography shows how his scientific imagination sprang from the rebellious nature of his personality.",
        "rating": 4.7,
        "publicationYear": 2007,
        "copies_owned": 3,
        "image": "client/assets/book/book_cover.webp",
        "language": "English",
        "pages": 704,
        "rating_count": 38900,
    },
    {
        "id": "30",
        "title": "The Diary of a Young Girl",
        "author": "Anne Frank",
        "category_id": "5",
        "description": "Discovered in the attic in which she spent the last years of her life, Anne Frank’s remarkable diary has since become a world classic—a powerful reminder of the horrors of war and an eloquent testament to the human spirit.",
        "rating": 4.8,
        "publication_year": 1947,
        "copies_owned": 6,
        "image": "client/assets/book/book_cover.webp",
        "language": "Dutch",
        "pages": 283,
        "rating_count": 72300,
    },
    {
        "id": "31",
        "title": "Long Walk to Freedom",
        "author": "Nelson Mandela",
        "category_id": "5",
        "description": "The riveting memoirs of the outstanding moral and political leader of our time, Long Walk to Freedom brilliantly re-creates the drama of the experiences that helped shape Nelson Mandela's destiny.",
        "rating": 4.9,
        "publication_year": 1994,
        "copies_owned": 4,
        "image": "client/assets/book/book_cover.webp",
        "language": "English",
        "pages": 656,
        "rating_count": 31500,
    },
    {
        "id": "32",
        "title": "Dune",
        "author": "Frank Herbert",
        "category_id": "6",
        "description": 'Set on the desert planet Arrakis, Dune is the story of the boy Paul Atreides, heir to a noble family tasked with ruling an inhospitable world where the only thing of value is the "spice" melange.',
        "rating": 4.7,
        "publication_year": 1965,
        "copies_owned": 5,
        "image": "client/assets/book/book_cover.webp",
        "language": "English",
        "pages": 688,
        "rating_count": 87600,
    },
    {
        "id": "33",
        "title": "Neuromancer",
        "author": "William Gibson",
        "category_id": "6",
        "description": "The Matrix is a world within the world, a global consensus-hallucination, the representation of every byte of data in cyberspace... Henry Dorsett Case was the sharpest data-thief in the business, until vengeful former employees crippled his nervous system.",
        "rating": 4.5,
        "publication_year": 1984,
        "copies_owned": 3,
        "image": "client/assets/book/book_cover.webp",
        "language": "English",
        "pages": 271,
        "rating_count": 23400,
    },
    {
        "id": "34",
        "title": "Foundation",
        "author": "Isaac Asimov",
        "category_id": "6",
        "description": "For twelve thousand years the Galactic Empire has ruled supreme. Now it is dying. But only Hari Seldon, creator of the revolutionary science of psychohistory, can see into the future--to a dark age of ignorance, barbarism, and warfare that will last thirty thousand years.",
        "rating": 4.6,
        "publication_year": 1951,
        "copies_owned": 4,
        "image": "client/assets/book/book_cover.webp",
        "language": "English",
        "pages": 244,
        "rating_count": 45800,
    },
    {
        "id": "35",
        "title": "Ender's Game",
        "author": "Orson Scott Card",
        "category_id": "6",
        "description": 'In order to develop a secure defense against a hostile alien race\'s next attack, government agencies breed child geniuses and train them as soldiers. A brilliant young boy, Andrew "Ender" Wiggin lives with his kind but distant parents, his sadistic brother Peter, and the person he loves more than anyone else, his sister Valentine.',
        "rating": 4.7,
        "publication_year": 1985,
        "copies_owned": 5,
        "image": "client/assets/book/book_cover.webp",
        "language": "English",
        "pages": 324,
        "rating_count": 62100,
    },
    {
        "id": "36",
        "title": "The Hobbit",
        "author": "J.R.R. Tolkien",
        "category_id": "7",
        "description": "Bilbo Baggins is a hobbit who enjoys a comfortable, unambitious life, rarely traveling further than his pantry or cellar. But his contentment is disturbed when the wizard Gandalf and a company of dwarves arrive on his doorstep one day to whisk him away on an adventure.",
        "rating": 4.8,
        "publication_year": 1937,
        "copies_owned": 6,
        "image": "client/assets/book/book_cover.webp",
        "language": "English",
        "pages": 310,
        "rating_count": 115000,
    },
    {
        "id": "37",
        "title": "Harry Potter and the Sorcerer's Stone",
        "author": "J.K. Rowling",
        "category_id": "7",
        "description": "Harry Potter has never even heard of Hogwarts when the letters start dropping on the doormat at number four, Privet Drive. Addressed in green ink on yellowish parchment with a purple seal, they are swiftly confiscated by his grisly aunt and uncle.",
        "rating": 4.9,
        "publication_year": 1997,
        "copies_owned": 8,
        "image": "client/assets/book/book_cover.webp",
        "language": "English",
        "pages": 309,
        "rating_count": 145000,
    },
    {
        "id": "38",
        "title": "The Lord of the Rings",
        "author": "J.R.R. Tolkien",
        "category_id": "7",
        "description": "One Ring to rule them all, One Ring to find them, One Ring to bring them all and in the darkness bind them. In ancient times the Rings of Power were crafted by the Elven-smiths, and Sauron, the Dark Lord, forged the One Ring, filling it with his own power so that he could rule all others.",
        "rating": 4.9,
        "publication_year": 1954,
        "copies_owned": 7,
        "image": "client/assets/book/book_cover.webp",
        "language": "English",
        "pages": 1178,
        "rating_count": 98700,
    },
    {
        "id": "39",
        "title": "The Da Vinci Code",
        "author": "Dan Brown",
        "category_id": "8",
        "description": "While in Paris, Harvard symbologist Robert Langdon is awakened by a phone call in the dead of the night. The elderly curator of the Louvre has been murdered inside the museum, his body covered in baffling symbols.",
        "rating": 4.1,
        "publication_year": 2003,
        "copiesOwned": 4,
        "image": "client/assets/book/book_cover.webp",
        "language": "English",
        "pages": 489,
        "rating_count": 68400,
    },
    {
        "id": "40",
        "title": "Gone Girl",
        "author": "Gillian Flynn",
        "category_id": "8",
        "description": "On a warm summer morning in North Carthage, Missouri, it is Nick and Amy Dunne’s fifth wedding anniversary. Presents are being wrapped and reservations are being made when Nick’s clever and beautiful wife disappears from their rented McMansion on the Mississippi River.",
        "rating": 4.3,
        "publication_year": 2012,
        "copies_owned": 3,
        "image": "client/assets/book/book_cover.webp",
        "language": "English",
        "pages": 415,
        "rating_count": 52300,
    },
]

# Categories list (id, name) - used to seed categories table
categories_data = [
    {
        "id": "1",
        "name": "Programming",
        "image_url": "/assets/book/book_cover.webp",
    },
    {
        "id": "2",
        "name": "History",
        "image_url": "/assets/book/book_cover.webp",
    },
    {
        "id": "3",
        "name": "Science",
        "image_url": "/assets/book/book_cover.webp",
    },
    {
        "id": "4",
        "name": "Fiction",
        "image_url": "/assets/book/book_cover.webp",
    },
    {
        "id": "5",
        "name": "Biography",
        "image_url": "/assets/book/book_cover.webp",
    },
    {
        "id": "6",
        "name": "Sci-Fi",
        "image_url": "/assets/book/book_cover.webp",
    },
    {
        "id": "7",
        "name": "Fantasy",
        "image_url": "/assets/book/book_cover.webp",
    },
    {
        "id": "8",
        "name": "Thriller",
        "image_url": "/assets/book/book_cover.webp",
    },
]

users_data = [
    {
        "id": "m1",
        "member_id": "M8392102",
        "name": "Jane Doe",
        "email": "jane.doe@example.com",
    },
    {
        "id": "m2",
        "member_id": "M8392103",
        "name": "John Smith",
        "email": "john.smith@example.com",
    },
    {
        "id": "m3",
        "member_id": "M8392104",
        "name": "Alice Johnson",
        "email": "alice.johnson@example.com",
    },
    {
        "id": "m4",
        "member_id": "M8392105",
        "name": "Bob Lee",
        "email": "bob.lee@example.com",
    },
    {
        "id": "m5",
        "member_id": "M8392106",
        "name": "Maria Garcia",
        "email": "maria.garcia@example.com",
    },
]

def seed():
    # Drop tables (use CASCADE for dependent objects) then re-create metadata
    print("Dropping and recreating tables (using CASCADE for dependents)...")
    with engine.begin() as conn:
        # drop known dependent tables first to avoid FK dependency errors
        conn.exec_driver_sql("DROP TABLE IF EXISTS interactions CASCADE")
        conn.exec_driver_sql("DROP TABLE IF EXISTS loans CASCADE")
        conn.exec_driver_sql("DROP TABLE IF EXISTS books CASCADE")
        conn.exec_driver_sql("DROP TABLE IF EXISTS categories CASCADE")
        conn.exec_driver_sql("DROP TABLE IF EXISTS users CASCADE")
    Base.metadata.create_all(bind=engine)

    db = SessionLocal()
    try:
        # Insert categories first
        print(f"Seeding {len(categories_data)} categories...")
        name_to_id = {}
        for c in categories_data:
            cid = c.get("id")
            cname = c.get("name")
            cimage = c.get("image_url")
            if cid and cname:
                db.add(Category(id=cid, name=cname, image_url=cimage))
                name_to_id[cname.strip().lower()] = cid

        # flush to ensure categories exist for FK references
        db.flush()

        print(f"Seeding {len(books_data)} books...")
        for book_data in books_data:
            # Handle potential case mismatches or missing fields
            # Fix keys if needed (e.g. publicationYear -> publication_year)
            # The data above is already cleaned up manually in this scripts list.

            # Note: id 29 has publicationYear instead of publication_year in the list above let me fix it in logic just in case
            if "publicationYear" in book_data:
                book_data["publication_year"] = book_data.pop("publicationYear")
            if "copiesOwned" in book_data:
                book_data["copies_owned"] = book_data.pop("copiesOwned")

            # Map category name to category_id if needed
            if "category_id" not in book_data or not book_data["category_id"]:
                if "category" in book_data and book_data["category"]:
                    cat_name = str(book_data.pop("category")).strip().lower()
                    cid = name_to_id.get(cat_name)
                    if cid is None:
                        # fallback: create a new category id by slugifying the name
                        cid = cat_name.replace(" ", "-").replace("/", "-")
                        name_to_id[cat_name] = cid
                        # normalize fallback image paths to the mounted /assets path when possible
                        fallback_img = book_data.get("image")
                        if (
                            isinstance(fallback_img, str)
                            and "client/assets/" in fallback_img
                        ):
                            fallback_img = fallback_img.split("client/assets/")[-1]
                            fallback_img = "/assets/" + fallback_img
                        db.add(Category(id=cid, name=cat_name, image_url=fallback_img))
                    book_data["category_id"] = cid

            book = Book(**book_data)
            db.add(book)

        # Seed Users
        

        print(f"Seeding {len(users_data)} users...")
        for u in users_data:
            # password left empty for seeded users (set via auth flow in production)
            user = User(
                id=u.get("id"),
                member_id=u.get("member_id"),
                name=u.get("name"),
                email=u.get("email"),
                password=None,
            )
            db.add(user)

        # Seed Loans
        print(f"Seeding {len(loans_data)} loans...")
        for loan_data in loans_data:
            loan = Loan(**loan_data)
            db.add(loan)

        db.commit()
        print("Seeded successfully!")
    except Exception as e:
        print(f"Error seeding data: {e}")
        db.rollback()
    finally:
        db.close()


if __name__ == "__main__":
    seed()
