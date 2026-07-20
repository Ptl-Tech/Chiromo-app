-- Seed script to push realistic notifications to all existing users

DO $$
DECLARE
    u RECORD;
BEGIN
    FOR u IN SELECT id FROM auth.users LOOP
        INSERT INTO public.notifications (user_id, title, body, type, is_read, created_at)
        VALUES 
            (u.id, 'Appointment Confirmed', 'Your session with Dr. Angela Wambui tomorrow at 10:00 AM has been confirmed. Please arrive 15 minutes early.', 'appointment_confirmed', false, now() - interval '12 minutes'),
            (u.id, 'Dr. David Omondi', 'Hi there! I''ve reviewed your mood logs from this week. Your progress is encouraging - let''s discuss during our next session.', 'doctor_message', false, now() - interval '2 hours'),
            (u.id, 'Thought Record Reviewed', 'Dr. Njeri has left feedback on your thought record from earlier this week. Tap to view her notes and suggestions.', 'cbt_feedback', false, now() - interval '4 hours'),
            (u.id, 'Daily Check-in Reminder', 'Don''t forget to log your mood today! Consistent tracking helps your care team provide better support.', 'system', false, now() - interval '8 hours'),
            (u.id, 'Upcoming Session', 'Reminder: You have a therapy session with Dr. Sarah Chen tomorrow at 2:00 PM. Prepare any topics you''d like to discuss.', 'appointment_reminder', true, now() - interval '1 day'),
            (u.id, 'New CBT Exercise Available', 'A new behavioral activation worksheet has been assigned to you. Complete it before your next session for best results.', 'cbt_feedback', true, now() - interval '1 day 8 hours'),
            (u.id, 'Welcome to Chiromo!', 'Thank you for joining Chiromo Hospital Group. Start by booking your first appointment or exploring our CBT self-help tools.', 'system', true, now() - interval '3 days');
    END LOOP;
END $$;
