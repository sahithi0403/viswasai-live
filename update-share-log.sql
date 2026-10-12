create table share_log(id bigint generated always as identity primary key, sid bigint not null references students(id) on delete cascade, kind text not null, period text not null, shared_at timestamptz default now());
alter table share_log enable row level security;
create policy "logged in only" on share_log for all to authenticated using (true) with check (true);
