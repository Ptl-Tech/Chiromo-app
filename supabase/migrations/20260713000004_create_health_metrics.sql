-- Health Metrics table for patient vitals
create table if not exists public.health_metrics (
  id uuid default uuid_generate_v4() primary key,
  patient_id uuid references public.profiles(id) on delete cascade not null,
  type text not null,                 -- e.g., 'steps', 'blood_pressure', 'heart_rate'
  value numeric not null,
  recorded_at timestamp with time zone default timezone('utc'::text, now()) not null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

alter table public.health_metrics enable row level security;

-- Patients can view their own metrics
create policy "Patients can view own health_metrics"
  on health_metrics for select using (auth.uid() = patient_id);

-- Patients can insert their own metrics
create policy "Patients can insert own health_metrics"
  on health_metrics for insert with check (auth.uid() = patient_id);

-- Patients can update their own metrics
create policy "Patients can update own health_metrics"
  on health_metrics for update using (auth.uid() = patient_id);

-- Trigger for updated_at
create trigger handle_health_metrics_updated_at
  before update on public.health_metrics
  for each row execute procedure public.handle_updated_at();
