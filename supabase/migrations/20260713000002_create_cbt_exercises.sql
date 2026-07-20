-- CBT Exercises table for patient self-help tools
-- Types: thought_record, behavioral_activation, exposure_ladder, daily_checkin

create table if not exists public.cbt_exercises (
  id uuid default uuid_generate_v4() primary key,
  patient_id uuid references public.profiles(id) on delete cascade not null,
  type text not null, -- thought_record, behavioral_activation, exposure_ladder, daily_checkin
  title text,
  data jsonb not null default '{}'::jsonb,
  is_shared boolean not null default false,
  has_doctor_feedback boolean not null default false,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

alter table public.cbt_exercises enable row level security;

-- Patients can view their own exercises
create policy "Patients can view own cbt_exercises"
  on cbt_exercises for select
  using (auth.uid() = patient_id);

-- Patients can insert their own exercises
create policy "Patients can create own cbt_exercises"
  on cbt_exercises for insert
  with check (auth.uid() = patient_id);

-- Patients can update their own exercises
create policy "Patients can update own cbt_exercises"
  on cbt_exercises for update
  using (auth.uid() = patient_id);

-- Patients can delete their own exercises
create policy "Patients can delete own cbt_exercises"
  on cbt_exercises for delete
  using (auth.uid() = patient_id);

-- Doctors can view shared exercises of their patients
create policy "Doctors can view shared cbt_exercises"
  on cbt_exercises for select
  using (
    is_shared = true
    and auth.uid() in (
      select d.id from doctors d
      join appointments a on a.doctor_id = d.id
      where a.patient_id = cbt_exercises.patient_id
    )
  );

-- Trigger for updated_at
create trigger handle_cbt_exercises_updated_at before update on public.cbt_exercises
  for each row execute procedure public.handle_updated_at();
