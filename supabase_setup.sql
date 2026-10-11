-- Viswasai Junior College: run this ONCE in Supabase > SQL Editor > New query > Run

create table if not exists students(
  id bigint generated always as identity primary key,
  name text not null,
  phone text,
  roll text
);

create table if not exists marks(
  id bigint generated always as identity primary key,
  sid bigint not null references students(id) on delete cascade,
  exam text not null,
  subject text not null,
  max_marks numeric(6,2) not null,
  scored numeric(6,2),
  unique(sid, exam, subject)
);

create table if not exists attendance(
  id bigint generated always as identity primary key,
  sid bigint not null references students(id) on delete cascade,
  ym char(7) not null,
  working int not null,
  present int not null,
  unique(sid, ym)
);

-- SECURITY: only logged-in teachers can read/write. Visitors get nothing.
alter table students   enable row level security;
alter table marks      enable row level security;
alter table attendance enable row level security;

create policy "teachers only" on students   for all to authenticated using (true) with check (true);
create policy "teachers only" on marks      for all to authenticated using (true) with check (true);
create policy "teachers only" on attendance for all to authenticated using (true) with check (true);

-- Saves one exam's marks in a single all-or-nothing step (replaces the old PHP transaction)
create or replace function save_marks(p_exam text, p_rows jsonb)
returns void language plpgsql security invoker set search_path = public as $$
begin
  delete from marks where exam = p_exam;
  insert into marks(sid, exam, subject, max_marks, scored)
  select (r->>'sid')::bigint, p_exam, r->>'subject', (r->>'max')::numeric, nullif(r->>'scored','')::numeric
  from jsonb_array_elements(p_rows) r;
end $$;

revoke execute on function save_marks(text, jsonb) from public, anon;
grant  execute on function save_marks(text, jsonb) to authenticated;
