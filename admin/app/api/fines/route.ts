import { NextRequest, NextResponse } from 'next/server';
import { createAdminSupabaseClient } from '@/lib/supabase/server';

// GET all fines with pagination and filtering
export async function GET(request: NextRequest) {
  try {
    const supabase = await createAdminSupabaseClient();
    const { searchParams } = new URL(request.url);
    
    const page = parseInt(searchParams.get('page') || '1');
    const limit = parseInt(searchParams.get('limit') || '10');
    const status = searchParams.get('status');

    const offset = (page - 1) * limit;

    let query = supabase
      .from('fines')
      .select(`
        *,
        users:user_id (id, name, email, membership_id),
        books:book_id (id, title, author)
      `, { count: 'exact' });

    if (status && status !== 'all') {
      query = query.eq('status', status);
    }

    query = query
      .order('created_at', { ascending: false })
      .range(offset, offset + limit - 1);

    const { data, error, count } = await query;

    if (error) {
      return NextResponse.json({ error: error.message }, { status: 500 });
    }

    return NextResponse.json({
      data,
      pagination: {
        page,
        limit,
        total: count || 0,
        totalPages: Math.ceil((count || 0) / limit),
      },
    });
  } catch (error) {
    console.error('Error fetching fines:', error);
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 });
  }
}

// POST create new fine
export async function POST(request: NextRequest) {
  try {
    const supabase = await createAdminSupabaseClient();
    const body = await request.json();

    const { data, error } = await supabase
      .from('fines')
      .insert({
        user_id: body.user_id,
        book_id: body.book_id,
        loan_id: body.loan_id,
        amount: body.amount,
        reason: body.reason,
        status: body.status || 'unpaid',
        due_date: body.due_date,
      })
      .select()
      .single();

    if (error) {
      return NextResponse.json({ error: error.message }, { status: 400 });
    }

    return NextResponse.json({ data }, { status: 201 });
  } catch (error) {
    console.error('Error creating fine:', error);
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 });
  }
}
