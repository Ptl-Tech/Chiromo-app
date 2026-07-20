-- Drop existing tables to ensure clean migration (for dev environment)
drop table if exists public.invoices cascade;
drop table if exists public.queues cascade;

-- Queues table
create table if not exists public.queues (
  id uuid default uuid_generate_v4() primary key,
  patient_id uuid references public.profiles(id) on delete cascade not null,
  appointment_id uuid references public.appointments(id) on delete set null,
  branch_id uuid references public.branches(id) on delete set null,
  assigned_doctor_id uuid references public.doctors(id) on delete set null,
  status text not null default 'waiting', -- waiting, triage, with_doctor, completed
  check_in_time timestamp with time zone default timezone('utc'::text, now()) not null,
  notes text,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

alter table public.queues enable row level security;
create policy "Queues are viewable by authenticated users" on queues for select using (auth.role() = 'authenticated');
create policy "Staff can manage queues" on queues for all using (
  auth.uid() in (select id from profiles where role::text in ('receptionist', 'nurse', 'super_admin', 'hospital_admin', 'branch_manager', 'psychiatrist', 'psychologist', 'therapist'))
);

-- Invoices table
create table if not exists public.invoices (
  id uuid default uuid_generate_v4() primary key,
  patient_id uuid references public.profiles(id) on delete cascade not null,
  appointment_id uuid references public.appointments(id) on delete set null,
  amount numeric not null default 0.0,
  status text not null default 'pending', -- pending, paid, cancelled
  payment_method text, -- cash, mpesa, card, insurance
  issued_at timestamp with time zone default timezone('utc'::text, now()) not null,
  paid_at timestamp with time zone,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

alter table public.invoices enable row level security;
create policy "Patients can view their own invoices" on invoices for select using (auth.uid() = patient_id);
create policy "Staff can manage invoices" on invoices for all using (
  auth.uid() in (select id from profiles where role::text in ('cashier', 'super_admin', 'hospital_admin', 'branch_manager'))
);

-- Triggers for updated_at
create trigger handle_queues_updated_at before update on public.queues
  for each row execute procedure public.handle_updated_at();

create trigger handle_invoices_updated_at before update on public.invoices
  for each row execute procedure public.handle_updated_at();
