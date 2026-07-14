import pytest

pytestmark = pytest.mark.skip(reason="Authorization direct checks live in integration/critical_flows/test_qa_critical_flows.py and expanded security tests.")


def test_member_cannot_access_another_member_resource():
    pass
