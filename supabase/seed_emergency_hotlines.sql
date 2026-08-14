-- Seed file for Chiromo Emergency Hotlines
INSERT INTO public.emergency_hotlines (title, subtitle, phone_number, icon_name, color_hex, sort_order)
VALUES 
('Kenya Crisis Helpline', 'Befrienders Kenya (24/7 Support)', '+254722178177', 'phone_in_talk', '#4A8D8B', 1),
('Chiromo Hospital Group', 'Toll-Free Emergency Line', '0800220000', 'local_hospital', '#D32F2F', 2),
('Chiromo Hospital Group', 'Alternative Emergency Line', '+254718781404', 'local_hospital', '#D32F2F', 3)
ON CONFLICT DO NOTHING;
