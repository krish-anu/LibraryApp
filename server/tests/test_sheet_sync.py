from app.pydantic_schemas.settings import SettingsUpdate
from app.services.sheet_sync.service import _sheet_csv_url, normalize_spreadsheet_id


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


def test_settings_update_normalizes_spreadsheet_id_from_url():
    payload = SettingsUpdate(sheet_spreadsheet_id=SPREADSHEET_URL)

    assert payload.sheet_spreadsheet_id == SPREADSHEET_ID
