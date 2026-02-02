import { NextRequest, NextResponse } from 'next/server';
import { createAdminSupabaseClient } from '@/lib/supabase/server';

// GET single user with stats
export async function GET(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { id } = await params;
    const supabase = await createAdminSupabaseClient();

    const { data: user, error } = await supabase
      .from('users')
      .select('*')
      .eq('id', id)
      .single();

    if (error) {
      return NextResponse.json({ error: error.message }, { status: 404 });
    }

    // Get user's active loans
    const { count: activeLoans } = await supabase
      .from('loans')
      .select('*', { count: 'exact', head: true })
      .eq('user_id', id)
      .eq('status', 'active');

    // Get user's total fines
    const { data: fines } = await supabase
      .from('fines')
      .select('amount')
      .eq('user_id', id)
      .eq('status', 'unpaid');

    const totalFines = fines?.reduce((sum, fine) => sum + fine.amount, 0) || 0;

    return NextResponse.json({
      data: {
        ...user,
        active_loans: activeLoans || 0,
        total_fines: totalFines,
      },
    });
  } catch (error) {
    console.error('Error fetching user:', error);
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 });
  }
}

// PUT update user
export async function PUT(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { id } = await params;
    const supabase = await createAdminSupabaseClient();
    const body = await request.json();

    const { data, error } = await supabase
      .from('users')
      .update({
        name: body.name,
        email: body.email,
        phone: body.phone,
        status: body.status,
        updated_at: new Date().toISOString(),
      })
      .eq('id', id)
      .select()
      .single();

    if (error) {
      return NextResponse.json({ error: error.message }, { status: 400 });
    }

    return NextResponse.json({ data });
  } catch (error) {
    console.error('Error updating user:', error);
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 });
  }
}

// DELETE user (soft delete - set status to inactive)
export async function DELETE(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { id } = await params;
    const supabase = await createAdminSupabaseClient();

    const { error } = await supabase
      .from('users')
      .update({ status: 'inactive', updated_at: new Date().toISOString() })
      .eq('id', id);

    if (error) {
      return NextResponse.json({ error: error.message }, { status: 400 });
    }

    return NextResponse.json({ success: true });
  } catch (error) {
    console.error('Error deleting user:', error);
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 });
  }
}
