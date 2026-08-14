-- Emergency Hotlines Table
CREATE TABLE IF NOT EXISTS public.emergency_hotlines (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title TEXT NOT NULL,
    subtitle TEXT NOT NULL,
    phone_number TEXT NOT NULL,
    icon_name TEXT DEFAULT 'phone_in_talk',
    color_hex TEXT DEFAULT '#4A8D8B',
    is_active BOOLEAN DEFAULT true,
    sort_order INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL
);

ALTER TABLE public.emergency_hotlines ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
    CREATE POLICY "Anyone can view active emergency hotlines"
        ON public.emergency_hotlines FOR SELECT
        USING (is_active = true);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- Only super_admin can manage hotlines (assuming you have profiles.role, if not adjust accordingly)
DO $$ BEGIN
    CREATE POLICY "Admins can manage hotlines"
        ON public.emergency_hotlines FOR ALL
        USING (
            EXISTS (
                SELECT 1 FROM public.profiles
                WHERE profiles.id = auth.uid() AND profiles.role::text = 'super_admin'
            )
        );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
