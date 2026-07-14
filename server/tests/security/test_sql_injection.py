import pytest

pytestmark = pytest.mark.skip(reason="Search injection checks should be implemented against HTTP gateway/client filters.")


def test_search_inputs_do_not_break_queries_or_return_unrelated_rows():
    pass
