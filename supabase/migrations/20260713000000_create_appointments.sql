-- Create extensions
create extension if not exists "uuid-ossp";

-- Drop existing tables to ensure clean migration (for dev environment)
drop table if exists public.appointments cascade;
drop table if exists public.doctors cascade;
drop table if exists public.branches cascade;

-- Profiles table (extends auth.users)
create table if not exists public.profiles (
  id uuid references auth.users on delete cascade not null primary key,
  first_name text,
  last_name text,
  phone_number text,
  avatar_url text,
  role text default 'patient'::text,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

alter table public.profiles enable row level security;

-- Policies for profiles
create policy "Public profiles are viewable by everyone." on profiles
  for select using (true);

create policy "Users can insert their own profile." on profiles
  for insert with check (auth.uid() = id);

create policy "Users can update own profile." on profiles
  for update using (auth.uid() = id);

-- Branches table
create table if not exists public.branches (
  id uuid default uuid_generate_v4() primary key,
  name text not null,
  address text,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

alter table public.branches enable row level security;
create policy "Branches are viewable by everyone." on branches for select using (true);

-- Doctors table
create table if not exists public.doctors (
  id uuid default uuid_generate_v4() primary key,
  user_id uuid references public.profiles(id) on delete cascade not null,
  specialty text not null,
  qualifications text,
  consultation_fee numeric not null default 0.0,
  is_available boolean not null default true,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null,
  unique(user_id)
);

alter table public.doctors enable row level security;
create policy "Doctors are viewable by everyone." on doctors for select using (true);
create policy "Doctors can update their own profile." on doctors for update using (auth.uid() = user_id);

-- Appointments table
create table if not exists public.appointments (
  id uuid default uuid_generate_v4() primary key,
  patient_id uuid references public.profiles(id) on delete cascade not null,
  doctor_id uuid references public.doctors(id) on delete cascade not null,
  branch_id uuid references public.branches(id) on delete set null,
  scheduled_at timestamp with time zone not null,
  status text not null default 'pending', -- pending, confirmed, cancelled, completed
  type text not null default 'in-person', -- in-person, telemedicine
  notes text,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

alter table public.appointments enable row level security;

-- Policies for appointments
create policy "Patients can view their own appointments" on appointments
  for select using (auth.uid() = patient_id);

create policy "Doctors can view their assigned appointments" on appointments
  for select using (
    auth.uid() in (select user_id from doctors where id = appointments.doctor_id)
  );

create policy "Patients can create appointments" on appointments
  for insert with check (auth.uid() = patient_id);

create policy "Patients can update their own appointments" on appointments
  for update using (auth.uid() = patient_id);

create policy "Doctors can update their assigned appointments" on appointments
  for update using (
    auth.uid() in (select user_id from doctors where id = appointments.doctor_id)
  );

-- Function to handle updating updated_at column
create or replace function public.handle_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

-- Triggers for updated_at
create trigger handle_profiles_updated_at before update on public.profiles
  for each row execute procedure public.handle_updated_at();

create trigger handle_branches_updated_at before update on public.branches
  for each row execute procedure public.handle_updated_at();

create trigger handle_doctors_updated_at before update on public.doctors
  for each row execute procedure public.handle_updated_at();

create trigger handle_appointments_updated_at before update on public.appointments
  for each row execute procedure public.handle_updated_at();
