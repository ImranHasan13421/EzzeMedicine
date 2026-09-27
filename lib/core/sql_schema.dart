class SupabaseSqlSchema {
  // Prefix conforming to user convention: EzzeMedicine_<tablename>
  static const String medicinesTable = 'EzzeMedicine_medicines';
  static const String ordersTable = 'EzzeMedicine_orders';
  static const String orderItemsTable = 'EzzeMedicine_order_items';

  static const String fullSqlScript = '''
-- ==============================================================================
-- EzzeMedicine Database Schema for Supabase Project "Ezze Softwares"
-- Table Prefix: EzzeMedicine_*
-- ==============================================================================

-- 1. Create Medicines Table
CREATE TABLE IF NOT EXISTS public."EzzeMedicine_medicines" (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    generic_name TEXT,
    category TEXT NOT NULL DEFAULT 'Tablet',
    manufacturer TEXT,
    strength TEXT,
    unit TEXT NOT NULL DEFAULT 'Strip (10 pcs)',
    price NUMERIC(10, 2) NOT NULL DEFAULT 0.00,
    cost_price NUMERIC(10, 2) DEFAULT 0.00,
    stock_quantity INTEGER NOT NULL DEFAULT 0,
    min_stock_alert INTEGER NOT NULL DEFAULT 10,
    image_url TEXT,
    requires_prescription BOOLEAN NOT NULL DEFAULT false,
    description TEXT,
    dosage_instructions TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 2. Create Orders Table
CREATE TABLE IF NOT EXISTS public."EzzeMedicine_orders" (
    id TEXT PRIMARY KEY,
    customer_name TEXT NOT NULL,
    customer_phone TEXT NOT NULL,
    customer_email TEXT NOT NULL,
    is_home_delivery BOOLEAN NOT NULL DEFAULT false,
    delivery_address TEXT,
    delivery_charge NUMERIC(10, 2) NOT NULL DEFAULT 0.00,
    status TEXT NOT NULL DEFAULT 'pending_call', -- pending_call, confirmed, cancelled, delivered
    subtotal NUMERIC(10, 2) NOT NULL DEFAULT 0.00,
    total_amount NUMERIC(10, 2) NOT NULL DEFAULT 0.00,
    call_notes TEXT,
    call_status TEXT NOT NULL DEFAULT 'not_called', -- not_called, called_confirmed, called_modified, unreachable
    is_email_sent BOOLEAN NOT NULL DEFAULT false,
    email_sent_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    confirmed_at TIMESTAMPTZ
);

-- 3. Create Order Items Table
CREATE TABLE IF NOT EXISTS public."EzzeMedicine_order_items" (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id TEXT NOT NULL REFERENCES public."EzzeMedicine_orders"(id) ON DELETE CASCADE,
    medicine_id TEXT NOT NULL,
    medicine_name TEXT NOT NULL,
    unit TEXT NOT NULL DEFAULT 'Strip',
    unit_price NUMERIC(10, 2) NOT NULL DEFAULT 0.00,
    quantity INTEGER NOT NULL DEFAULT 1,
    item_total NUMERIC(10, 2) NOT NULL DEFAULT 0.00,
    image_url TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 4. Set Unrestricted Access (matching other tables like EzzeStores_items)
ALTER TABLE public."EzzeMedicine_medicines" DISABLE ROW LEVEL SECURITY;
ALTER TABLE public."EzzeMedicine_orders" DISABLE ROW LEVEL SECURITY;
ALTER TABLE public."EzzeMedicine_order_items" DISABLE ROW LEVEL SECURITY;

-- 5. Seed Initial Popular Medicines
INSERT INTO public."EzzeMedicine_medicines" (id, name, generic_name, category, manufacturer, strength, unit, price, cost_price, stock_quantity, min_stock_alert, image_url, requires_prescription, description, dosage_instructions)
VALUES
('00000000-0000-0000-0000-000000000001', 'Napa Extra', 'Paracetamol + Caffeine', 'Tablet', 'Beximco Pharmaceuticals', '500mg + 65mg', 'Strip (10 pcs)', 35.00, 28.00, 140, 20, 'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?w=400&auto=format&fit=crop&q=80', false, 'Fast and effective relief from fever, headache, migraine, toothache, and body pain.', '1-2 tablets every 4 to 6 hours as needed. Maximum 8 tablets daily.'),
('00000000-0000-0000-0000-000000000002', 'Sergel 20mg', 'Esomeprazole Magnesium', 'Capsule', 'Healthcare Pharmaceuticals', '20mg', 'Strip (10 pcs)', 70.00, 58.00, 85, 15, 'https://images.unsplash.com/photo-1471864190281-a93a3070b6de?w=400&auto=format&fit=crop&q=80', false, 'Proton pump inhibitor for hyperacidity, acid reflux, peptic ulcer, and gastritis.', '1 capsule once daily 30 minutes before meal with a full glass of water.'),
('00000000-0000-0000-0000-000000000003', 'Monas 10mg', 'Montelukast Sodium', 'Tablet', 'Acme Laboratories', '10mg', 'Strip (10 pcs)', 160.00, 135.00, 8, 15, 'https://images.unsplash.com/photo-1550572017-edd951aa8f72?w=400&auto=format&fit=crop&q=80', true, 'Preventative treatment for chronic asthma, allergic rhinitis, and bronchospasm.', '1 tablet once daily in the evening at bedtime.'),
('00000000-0000-0000-0000-000000000004', 'Tusca Cold & Cough', 'Dextromethorphan + Pseudoephedrine', 'Syrup', 'Square Pharmaceuticals', '100ml', 'Bottle (100ml)', 95.00, 75.00, 42, 10, 'https://images.unsplash.com/photo-1631549916768-4119b2e5f926?w=400&auto=format&fit=crop&q=80', false, 'Soothes dry cough, clears nasal congestion, and relieves allergic throat irritation.', '10ml (2 teaspoonfuls) 3 times daily after meals.'),
('00000000-0000-0000-0000-000000000005', 'Bextram Gold Multivitamin', 'Multivitamins & Minerals with Zinc', 'Vitamins & Supplements', 'Beximco Pharmaceuticals', '30 Tablets', 'Bottle (200ml)', 320.00, 260.00, 30, 10, 'https://images.unsplash.com/photo-1577401239170-897942555fb3?w=400&auto=format&fit=crop&q=80', false, 'Complete daily nutritional support for immunity, vitality, and physical stamina.', '1 tablet once daily with or after a main meal.')
ON CONFLICT (id) DO NOTHING;

-- 6. Enable Realtime Broadcasting
ALTER PUBLICATION supabase_realtime ADD TABLE public."EzzeMedicine_medicines";
ALTER PUBLICATION supabase_realtime ADD TABLE public."EzzeMedicine_orders";
''';

  static const String rollbackSqlScript = '''
-- ==============================================================================
-- ROLLBACK SCRIPT FOR EzzeMedicine Tables
-- ==============================================================================
DROP TABLE IF EXISTS public."EzzeMedicine_order_items" CASCADE;
DROP TABLE IF EXISTS public."EzzeMedicine_orders" CASCADE;
DROP TABLE IF EXISTS public."EzzeMedicine_medicines" CASCADE;
''';
}
