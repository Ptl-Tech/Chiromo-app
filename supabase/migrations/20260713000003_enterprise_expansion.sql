-- Phase 1 Enterprise Expansion: Database Schema
-- ════════════════════════════════════════════════════════════════════════════

-- 1. Organizational Structure
-- ────────────────────────────────────────────────────────────────────────────

-- Departments
create table if not exists public.departments (
  id uuid default uuid_generate_v4() primary key,
  branch_id uuid references public.branches(id) on delete cascade not null,
  name text not null,
  description text,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

alter table public.departments enable row level security;
create policy "Departments are viewable by everyone" on departments for select using (true);
create policy "Staff can manage departments" on departments for all using (
  auth.uid() in (select id from profiles where role::text in ('super_admin', 'hospital_admin', 'branch_manager'))
);

create trigger handle_departments_updated_at before update on public.departments
  for each row execute procedure public.handle_updated_at();


-- Services (billable procedures/consultations)
create table if not exists public.services (
  id uuid default uuid_generate_v4() primary key,
  department_id uuid references public.departments(id) on delete cascade not null,
  name text not null,
  description text,
  price numeric not null default 0.0,
  duration_minutes int not null default 30,
  is_active boolean not null default true,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

alter table public.services enable row level security;
create policy "Services are viewable by everyone" on services for select using (true);
create policy "Staff can manage services" on services for all using (
  auth.uid() in (select id from profiles where role::text in ('super_admin', 'hospital_admin', 'branch_manager'))
);

create trigger handle_services_updated_at before update on public.services
  for each row execute procedure public.handle_updated_at();


-- Rooms
create table if not exists public.rooms (
  id uuid default uuid_generate_v4() primary key,
  branch_id uuid references public.branches(id) on delete cascade not null,
  name text not null, -- e.g., "Consultation Room 1", "Therapy Room A"
  type text not null, -- consultation, therapy, ward, laboratory
  is_available boolean not null default true,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

alter table public.rooms enable row level security;
create policy "Rooms are viewable by staff" on rooms for select using (
  auth.uid() in (select id from profiles where role::text != 'patient')
);
create policy "Staff can manage rooms" on rooms for all using (
  auth.uid() in (select id from profiles where role::text in ('super_admin', 'hospital_admin', 'branch_manager'))
);

create trigger handle_rooms_updated_at before update on public.rooms
  for each row execute procedure public.handle_updated_at();


-- 2. Scheduling & Availability
-- ────────────────────────────────────────────────────────────────────────────

-- Doctor Schedules (recurring weekly availability)
create table if not exists public.doctor_schedules (
  id uuid default uuid_generate_v4() primary key,
  doctor_id uuid references public.doctors(id) on delete cascade not null,
  branch_id uuid references public.branches(id) on delete cascade not null,
  day_of_week int not null, -- 0 (Sunday) to 6 (Saturday)
  start_time time not null,
  end_time time not null,
  is_active boolean not null default true,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

alter table public.doctor_schedules enable row level security;
create policy "Doctor schedules are viewable by everyone" on doctor_schedules for select using (true);
create policy "Doctors can manage own schedules" on doctor_schedules for all using (
  auth.uid() in (select user_id from doctors where id = doctor_schedules.doctor_id)
);

create trigger handle_doctor_schedules_updated_at before update on public.doctor_schedules
  for each row execute procedure public.handle_updated_at();


-- Time Slots (generated available slots)
create table if not exists public.time_slots (
  id uuid default uuid_generate_v4() primary key,
  doctor_id uuid references public.doctors(id) on delete cascade not null,
  branch_id uuid references public.branches(id) on delete cascade not null,
  start_datetime timestamp with time zone not null,
  end_datetime timestamp with time zone not null,
  is_booked boolean not null default false,
  appointment_id uuid references public.appointments(id) on delete set null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

alter table public.time_slots enable row level security;
create policy "Time slots viewable by everyone" on time_slots for select using (true);
create policy "Doctors can manage own slots" on time_slots for all using (
  auth.uid() in (select user_id from doctors where id = time_slots.doctor_id)
);

create trigger handle_time_slots_updated_at before update on public.time_slots
  for each row execute procedure public.handle_updated_at();


-- 3. Medical & Clinical
-- ────────────────────────────────────────────────────────────────────────────

-- Medical Records
create table if not exists public.medical_records (
  id uuid default uuid_generate_v4() primary key,
  patient_id uuid references public.profiles(id) on delete cascade not null,
  doctor_id uuid references public.doctors(id) on delete cascade not null,
  appointment_id uuid references public.appointments(id) on delete set null,
  chief_complaint text,
  clinical_notes text,
  blood_pressure text,
  heart_rate int,
  temperature numeric,
  weight numeric,
  height numeric,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

alter table public.medical_records enable row level security;
create policy "Patients view own medical records" on medical_records for select using (auth.uid() = patient_id);
create policy "Doctors view records of their patients" on medical_records for select using (
  auth.uid() in (
    select d.user_id from doctors d
    join appointments a on a.doctor_id = d.id
    where a.patient_id = medical_records.patient_id
  )
);
create policy "Doctors insert medical records" on medical_records for insert with check (
  auth.uid() in (select user_id from doctors where id = doctor_id)
);

create trigger handle_medical_records_updated_at before update on public.medical_records
  for each row execute procedure public.handle_updated_at();


-- Diagnoses
create table if not exists public.diagnoses (
  id uuid default uuid_generate_v4() primary key,
  medical_record_id uuid references public.medical_records(id) on delete cascade not null,
  icd_10_code text,
  description text not null,
  notes text,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

alter table public.diagnoses enable row level security;
create policy "Patients view own diagnoses" on diagnoses for select using (
  auth.uid() in (select patient_id from medical_records where id = diagnoses.medical_record_id)
);
create policy "Doctors view/manage diagnoses" on diagnoses for all using (
  auth.uid() in (select user_id from doctors)
);

create trigger handle_diagnoses_updated_at before update on public.diagnoses
  for each row execute procedure public.handle_updated_at();


-- Prescriptions
create table if not exists public.prescriptions (
  id uuid default uuid_generate_v4() primary key,
  medical_record_id uuid references public.medical_records(id) on delete cascade not null,
  medication_name text not null,
  dosage text not null,
  frequency text not null,
  duration_days int not null,
  instructions text,
  is_dispensed boolean not null default false,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

alter table public.prescriptions enable row level security;
create policy "Patients view own prescriptions" on prescriptions for select using (
  auth.uid() in (select patient_id from medical_records where id = prescriptions.medical_record_id)
);
create policy "Doctors view/manage prescriptions" on prescriptions for all using (
  auth.uid() in (select user_id from doctors)
);
create policy "Pharmacy views prescriptions" on prescriptions for select using (
  auth.uid() in (select id from profiles where role::text in ('receptionist', 'nurse', 'super_admin'))
);

create trigger handle_prescriptions_updated_at before update on public.prescriptions
  for each row execute procedure public.handle_updated_at();


-- 4. Billing, Insurance & Corporate
-- ────────────────────────────────────────────────────────────────────────────

-- Insurance Providers
create table if not exists public.insurance_providers (
  id uuid default uuid_generate_v4() primary key,
  name text not null,
  contact_email text,
  contact_phone text,
  is_active boolean not null default true,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

alter table public.insurance_providers enable row level security;
create policy "Insurance providers viewable by all" on insurance_providers for select using (true);

create trigger handle_insurance_providers_updated_at before update on public.insurance_providers
  for each row execute procedure public.handle_updated_at();


-- Corporate Accounts
create table if not exists public.corporate_accounts (
  id uuid default uuid_generate_v4() primary key,
  company_name text not null,
  contact_person text,
  contact_email text,
  is_active boolean not null default true,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

alter table public.corporate_accounts enable row level security;
create policy "Corporate accounts viewable by all" on corporate_accounts for select using (true);

create trigger handle_corporate_accounts_updated_at before update on public.corporate_accounts
  for each row execute procedure public.handle_updated_at();


-- Insurance Claims
create table if not exists public.insurance_claims (
  id uuid default uuid_generate_v4() primary key,
  invoice_id uuid references public.invoices(id) on delete cascade not null,
  insurance_provider_id uuid references public.insurance_providers(id) on delete cascade not null,
  patient_id uuid references public.profiles(id) on delete cascade not null,
  member_number text not null,
  claim_amount numeric not null,
  approved_amount numeric,
  status text not null default 'pending', -- pending, approved, rejected, partially_approved
  rejection_reason text,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

alter table public.insurance_claims enable row level security;
create policy "Patients view own claims" on insurance_claims for select using (auth.uid() = patient_id);
create policy "Staff manage claims" on insurance_claims for all using (
  auth.uid() in (select id from profiles where role::text in ('cashier', 'super_admin', 'hospital_admin'))
);

create trigger handle_insurance_claims_updated_at before update on public.insurance_claims
  for each row execute procedure public.handle_updated_at();


-- Payments
create table if not exists public.payments (
  id uuid default uuid_generate_v4() primary key,
  invoice_id uuid references public.invoices(id) on delete cascade not null,
  patient_id uuid references public.profiles(id) on delete cascade not null,
  amount numeric not null,
  payment_method text not null, -- cash, mpesa, card, insurance, corporate
  transaction_reference text, -- e.g., M-Pesa receipt number
  status text not null default 'completed', -- pending, completed, failed, refunded
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

alter table public.payments enable row level security;
create policy "Patients view own payments" on payments for select using (auth.uid() = patient_id);
create policy "Staff manage payments" on payments for all using (
  auth.uid() in (select id from profiles where role::text in ('cashier', 'super_admin', 'hospital_admin'))
);

create trigger handle_payments_updated_at before update on public.payments
  for each row execute procedure public.handle_updated_at();


-- 5. System & Auditing
-- ────────────────────────────────────────────────────────────────────────────

-- Notifications
create table if not exists public.notifications (
  id uuid default uuid_generate_v4() primary key,
  user_id uuid references public.profiles(id) on delete cascade not null,
  title text not null,
  body text not null,
  type text not null, -- appointment, payment, system
  is_read boolean not null default false,
  data jsonb,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

alter table public.notifications enable row level security;
create policy "Users view own notifications" on notifications for select using (auth.uid() = user_id);
create policy "Users update own notifications (mark read)" on notifications for update using (auth.uid() = user_id);


-- Audit Logs
create table if not exists public.audit_logs (
  id uuid default uuid_generate_v4() primary key,
  user_id uuid references public.profiles(id) on delete set null,
  action text not null, -- e.g., "CREATED_INVOICE", "CANCELLED_APPOINTMENT"
  entity_type text not null, -- e.g., "invoices", "appointments"
  entity_id uuid,
  details jsonb,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

alter table public.audit_logs enable row level security;
create policy "Only super admin views audit logs" on audit_logs for select using (
  auth.uid() in (select id from profiles where role::text = 'super_admin')
);


-- Chat Messages (for Telemedicine prep / secure messaging)
create table if not exists public.chat_messages (
  id uuid default uuid_generate_v4() primary key,
  appointment_id uuid references public.appointments(id) on delete cascade not null,
  sender_id uuid references public.profiles(id) on delete cascade not null,
  receiver_id uuid references public.profiles(id) on delete cascade not null,
  content text not null,
  is_read boolean not null default false,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

alter table public.chat_messages enable row level security;
create policy "Users view chats they are part of" on chat_messages for select using (
  auth.uid() = sender_id or auth.uid() = receiver_id
);
create policy "Users can send messages" on chat_messages for insert with check (
  auth.uid() = sender_id
);


-- 6. Storage Buckets (Optional helper, usually configured in dashboard)
-- ────────────────────────────────────────────────────────────────────────────
-- Note: Supabase storage buckets are stored in `storage.buckets`.
-- We insert them here if they don't exist.

insert into storage.buckets (id, name, public) 
values ('avatars', 'avatars', true) 
on conflict (id) do nothing;

insert into storage.buckets (id, name, public) 
values ('medical_documents', 'medical_documents', false) 
on conflict (id) do nothing;

insert into storage.buckets (id, name, public) 
values ('prescriptions', 'prescriptions', false) 
on conflict (id) do nothing;
