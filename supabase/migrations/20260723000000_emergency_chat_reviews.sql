-- ============================================================================
-- EMERGENCY & CRISIS SUPPORT
-- ============================================================================

-- Emergency Contacts Table
CREATE TABLE IF NOT EXISTS public.emergency_contacts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    patient_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    phone_number TEXT NOT NULL,
    relationship TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL
);

ALTER TABLE public.emergency_contacts ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
    CREATE POLICY "Patients can manage their own emergency contacts"
        ON public.emergency_contacts FOR ALL
        USING (auth.uid() = patient_id);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- Safety Plans Table
CREATE TABLE IF NOT EXISTS public.safety_plans (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    patient_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    warning_signs TEXT,
    coping_strategies TEXT,
    reasons_to_live TEXT,
    professional_contacts TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    UNIQUE(patient_id)
);

ALTER TABLE public.safety_plans ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
    CREATE POLICY "Patients can manage their own safety plan"
        ON public.safety_plans FOR ALL
        USING (auth.uid() = patient_id);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
    CREATE POLICY "Doctors can view patient safety plans"
        ON public.safety_plans FOR SELECT
        USING (EXISTS (SELECT 1 FROM public.appointments WHERE patient_id = safety_plans.patient_id AND doctor_id = auth.uid()));
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- ============================================================================
-- IN-APP CHAT & MESSAGING
-- ============================================================================

-- Chats Table
CREATE TABLE IF NOT EXISTS public.chats (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    patient_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    doctor_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    UNIQUE(patient_id, doctor_id)
);

ALTER TABLE public.chats ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
    CREATE POLICY "Users can view and manage their chats"
        ON public.chats FOR ALL
        USING (auth.uid() = patient_id OR auth.uid() = doctor_id);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- Messages Table
CREATE TABLE IF NOT EXISTS public.messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    chat_id UUID NOT NULL REFERENCES public.chats(id) ON DELETE CASCADE,
    sender_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    attachment_url TEXT,
    is_read BOOLEAN DEFAULT false NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL
);

ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
    CREATE POLICY "Users can view and manage messages in their chats"
        ON public.messages FOR ALL
        USING (
            EXISTS (
                SELECT 1 FROM public.chats c 
                WHERE c.id = messages.chat_id 
                AND (c.patient_id = auth.uid() OR c.doctor_id = auth.uid())
            )
        );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- ============================================================================
-- DOCTOR REVIEWS & RATINGS
-- ============================================================================

-- Doctor Reviews Table
CREATE TABLE IF NOT EXISTS public.doctor_reviews (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    appointment_id UUID NOT NULL REFERENCES public.appointments(id) ON DELETE CASCADE,
    patient_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    doctor_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
    review_text TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    UNIQUE(appointment_id)
);

ALTER TABLE public.doctor_reviews ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
    CREATE POLICY "Patients can create reviews for their appointments"
        ON public.doctor_reviews FOR INSERT
        WITH CHECK (auth.uid() = patient_id);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
    CREATE POLICY "Anyone can view doctor reviews"
        ON public.doctor_reviews FOR SELECT
        USING (true);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
    CREATE POLICY "Patients can update their own reviews"
        ON public.doctor_reviews FOR UPDATE
        USING (auth.uid() = patient_id);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
    CREATE POLICY "Patients can delete their own reviews"
        ON public.doctor_reviews FOR DELETE
        USING (auth.uid() = patient_id);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
