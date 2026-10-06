-- EVERPOINT HOLDING / SUPABASE SETUP
-- Run this in Supabase Dashboard -> SQL Editor after creating the Auth admin user.
-- NEVER put a service_role/secret key in your website.

create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text not null unique,
  full_name text not null,
  role text not null default 'employee' check (role in ('admin','employee')),
  active boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.progress (
  employee_id uuid primary key references public.profiles(id) on delete cascade,
  application_reviewed boolean not null default false,
  shortlisted boolean not null default false,
  interview boolean not null default false,
  onboarding boolean not null default false,
  device_activation boolean not null default false,
  work_starts boolean not null default false,
  updated_at timestamptz not null default now()
);

create table if not exists public.reimbursements (
  employee_id uuid primary key references public.profiles(id) on delete cascade,
  amount numeric(12,2) not null default 0,
  status text not null default 'none' check (status in ('none','pending','approved','paid')),
  description text default '',
  updated_at timestamptz not null default now()
);

create table if not exists public.employee_documents (
  employee_id uuid references public.profiles(id) on delete cascade,
  doc_id text not null,
  status text not null default 'locked' check (status in ('locked','pending','available')),
  updated_at timestamptz not null default now(),
  primary key (employee_id, doc_id)
);

create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  employee_id uuid not null references public.profiles(id) on delete cascade,
  title text not null,
  body text not null,
  created_at timestamptz not null default now()
);

create table if not exists public.announcements (
  id uuid primary key default gen_random_uuid(),
  employee_id uuid references public.profiles(id) on delete cascade,
  title text not null,
  body text not null,
  created_at timestamptz not null default now()
);

create table if not exists public.applications (
  id uuid primary key default gen_random_uuid(),
  "firstName" text,
  "lastName" text,
  email text,
  phone text,
  dob text,
  role text,
  "employmentType" text,
  "workArrangement" text,
  address text,
  "employmentStatus" text,
  experience text,
  education text,
  skills text,
  history text,
  motivation text,
  availability text,
  teams text,
  submitted_at timestamptz not null default now()
);

create table if not exists public.uploads (
  id uuid primary key default gen_random_uuid(),
  employee_id uuid not null references public.profiles(id) on delete cascade,
  file_path text not null,
  file_name text not null,
  title text,
  related_document text,
  created_at timestamptz not null default now()
);

-- Admin helper. SECURITY DEFINER is intentional so RLS can ask whether the current user is an admin.
create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid() and role = 'admin' and active = true
  );
$$;

alter table public.profiles enable row level security;
alter table public.progress enable row level security;
alter table public.reimbursements enable row level security;
alter table public.employee_documents enable row level security;
alter table public.notifications enable row level security;
alter table public.announcements enable row level security;
alter table public.applications enable row level security;
alter table public.uploads enable row level security;

-- Drop/recreate policies so the script can safely be run again.
do $$ declare r record; begin
  for r in select policyname, tablename from pg_policies where schemaname='public' and tablename in ('profiles','progress','reimbursements','employee_documents','notifications','announcements','applications','uploads') loop
    execute format('drop policy if exists %I on public.%I', r.policyname, r.tablename);
  end loop;
end $$;

create policy profiles_select on public.profiles for select to authenticated using (id=auth.uid() or public.is_admin());
create policy profiles_admin_insert on public.profiles for insert to authenticated with check (public.is_admin());
create policy profiles_admin_update on public.profiles for update to authenticated using (public.is_admin()) with check (public.is_admin());
create policy profiles_admin_delete on public.profiles for delete to authenticated using (public.is_admin());

create policy progress_select on public.progress for select to authenticated using (employee_id=auth.uid() or public.is_admin());
create policy progress_admin_all on public.progress for all to authenticated using (public.is_admin()) with check (public.is_admin());

create policy reimbursement_select on public.reimbursements for select to authenticated using (employee_id=auth.uid() or public.is_admin());
create policy reimbursement_admin_all on public.reimbursements for all to authenticated using (public.is_admin()) with check (public.is_admin());

create policy docs_select on public.employee_documents for select to authenticated using (employee_id=auth.uid() or public.is_admin());
create policy docs_admin_all on public.employee_documents for all to authenticated using (public.is_admin()) with check (public.is_admin());

create policy notifications_select on public.notifications for select to authenticated using (employee_id=auth.uid() or public.is_admin());
create policy notifications_admin_insert on public.notifications for insert to authenticated with check (public.is_admin());
create policy notifications_admin_all on public.notifications for all to authenticated using (public.is_admin()) with check (public.is_admin());

create policy announcements_select on public.announcements for select to authenticated using (employee_id=auth.uid() or employee_id is null or public.is_admin());
create policy announcements_admin_all on public.announcements for all to authenticated using (public.is_admin()) with check (public.is_admin());

create policy applications_public_insert on public.applications for insert to anon, authenticated with check (true);
create policy applications_admin_select on public.applications for select to authenticated using (public.is_admin());

create policy uploads_select on public.uploads for select to authenticated using (employee_id=auth.uid() or public.is_admin());
create policy uploads_insert on public.uploads for insert to authenticated with check (employee_id=auth.uid() or public.is_admin());
create policy uploads_admin_delete on public.uploads for delete to authenticated using (public.is_admin());

-- Storage bucket: private employee PDFs.
insert into storage.buckets (id,name,public,file_size_limit,allowed_mime_types)
values ('employee-documents','employee-documents',false,52428800,array['application/pdf'])
on conflict (id) do update set public=false, file_size_limit=52428800, allowed_mime_types=array['application/pdf'];

drop policy if exists "employee documents read own" on storage.objects;
drop policy if exists "employee documents upload own" on storage.objects;
drop policy if exists "employee documents admin read" on storage.objects;

create policy "employee documents read own" on storage.objects for select to authenticated using (bucket_id='employee-documents' and (name like auth.uid()::text || '/%' or public.is_admin()));
create policy "employee documents upload own" on storage.objects for insert to authenticated with check (bucket_id='employee-documents' and (name like auth.uid()::text || '/%' or public.is_admin()));

-- Create the EverPoint admin Auth user first in Supabase Dashboard.
-- Then run this statement to mark it as the admin profile:
-- insert into public.profiles (id,email,full_name,role,active)
-- select id,email,'EverPoint Administrator','admin',true from auth.users where email='admin@everpointholding.com'
-- on conflict (id) do update set role='admin', active=true, email=excluded.email;
