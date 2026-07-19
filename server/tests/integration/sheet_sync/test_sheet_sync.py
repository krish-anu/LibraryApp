from app.services.sheet_sync.service import (
    _sheet_csv_url,
    env_sheet_tab,
    env_spreadsheet_id,
    normalize_spreadsheet_id,
)


SPREADSHEET_ID = "1omFft7rHys_XZY6a670vTkOOErcA3TMatu30hvwvps4"
SPREADSHEET_URL = (
    "https://docs.google.com/spreadsheets/d/"
    f"{SPREADSHEET_ID}/edit?usp=sharing"
)


def test_normalize_spreadsheet_id_accepts_google_sheet_url():
    assert normalize_spreadsheet_id(SPREADSHEET_URL) == SPREADSHEET_ID


def test_sheet_csv_url_uses_normalized_spreadsheet_id():
    normalized_id = normalize_spreadsheet_id(SPREADSHEET_URL)

    assert _sheet_csv_url(normalized_id, "Books") == (
        "https://docs.google.com/spreadsheets/d/"
        f"{SPREADSHEET_ID}/gviz/tq?tqx=out:csv&sheet=Books"
    )


def test_env_spreadsheet_id_normalizes_google_sheet_url(monkeypatch):
    monkeypatch.setenv("GOOGLE_SHEET_SPREADSHEET_ID", SPREADSHEET_URL)

    assert env_spreadsheet_id() == SPREADSHEET_ID


def test_env_sheet_tab_defaults_to_standard_tab_names(monkeypatch):
    monkeypatch.delenv("GOOGLE_SHEET_BOOKS_TAB", raising=False)

    assert env_sheet_tab("books") == "Books"


def test_env_sheet_tab_uses_env_override(monkeypatch):
    monkeypatch.setenv("GOOGLE_SHEET_VIDEOS_TAB", "Library Videos")

    assert env_sheet_tab("videos") == "Library Videos"
