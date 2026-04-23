from .firestore_store import FirestoreLibraryStore, get_firestore_client


def get_firestore_connection():
    return get_firestore_client()


def get_library_store():
    return FirestoreLibraryStore()
