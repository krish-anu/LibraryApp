import pytest

pytestmark = pytest.mark.skip(reason="Direct return idempotency coverage lives in integration/critical_flows/test_qa_critical_flows.py.")


def test_return_book_restores_inventory_once():
    pass
