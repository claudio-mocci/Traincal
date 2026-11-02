-- Schema per la sincronizzazione di Traincal tra dispositivi.
-- Da eseguire una volta nel SQL editor del progetto Supabase.

create table if not exists public.sync_records (
  user_id uuid not null default auth.uid() references auth.users on delete cascade,
  collection text not null,
  id text not null,
  data jsonb not null,
  -- timestamp (ms) dell'ultima modifica sul dispositivo: decide i conflitti
  updated_at bigint not null,
  deleted boolean not null default false,
  -- timestamp del server: cursore per il pull incrementale
  server_updated_at timestamptz not null default now(),
  primary key (user_id, collection, id)
);

create index if not exists sync_records_pull_idx
  on public.sync_records (user_id, server_updated_at);

alter table public.sync_records enable row level security;

drop policy if exists "sync_records_own" on public.sync_records;
create policy "sync_records_own" on public.sync_records
  for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- Last-write-wins: un aggiornamento con updated_at più vecchio viene ignorato;
-- quelli applicati aggiornano il cursore del server.
create or replace function public.sync_records_lww()
returns trigger
language plpgsql
as $$
begin
  if tg_op = 'UPDATE' and new.updated_at < old.updated_at then
    return old;
  end if;
  new.server_updated_at := clock_timestamp();
  return new;
end;
$$;

drop trigger if exists sync_records_lww on public.sync_records;
create trigger sync_records_lww
  before insert or update on public.sync_records
  for each row execute function public.sync_records_lww();
