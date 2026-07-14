from datetime import date

from app.models.fine import Fine


def test_unpaid_fine_boundary_fixture_shape():
    fine = Fine(
        id="fine-boundary",
        member_id="member-1",
        fine_date=date.today(),
        fine_amount=10.0,
        status="unpaid",
    )

    assert fine.status == "unpaid"
    assert float(fine.fine_amount) == 10.0
