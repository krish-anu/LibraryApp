import pytest

pytestmark = pytest.mark.skip(reason="Permission coverage lives in integration/critical_flows/test_qa_critical_flows.py and security tests; scaffold for expanded API checks.")


def test_missing_scope_returns_forbidden():
    pass
