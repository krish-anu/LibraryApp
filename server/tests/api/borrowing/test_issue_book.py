import pytest

pytestmark = pytest.mark.skip(reason="Direct business-rule coverage lives in integration/critical_flows/test_qa_critical_flows.py.")


def test_issue_book_decrements_inventory():
    pass
