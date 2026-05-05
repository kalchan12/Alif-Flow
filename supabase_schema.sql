-- ============================================================
-- Alif-Flow Supabase Schema
-- Run this in your Supabase SQL Editor
-- ============================================================

-- ────────────────────────────────────────────────────────────
-- 1. PRODUCTS — Master product catalog (dynamic, not hardcoded)
-- ────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS products (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  product_name TEXT NOT NULL,
  category TEXT NOT NULL,          -- e.g. 'soap', 'special', 'paint'
  unit_price NUMERIC(12,2) NOT NULL DEFAULT 0.00,
  is_active BOOLEAN NOT NULL DEFAULT true,
  sort_order INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Unique constraint: no duplicate product names within a category
ALTER TABLE products
  ADD CONSTRAINT uq_products_name_category UNIQUE (product_name, category);

-- ────────────────────────────────────────────────────────────
-- 2. PRICE CHANGE REQUESTS — Seller-proposed price changes
--    Sellers can propose, but admin must approve before it
--    takes effect on the master products table.
-- ────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS price_change_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  requested_by UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  old_price NUMERIC(12,2) NOT NULL,
  new_price NUMERIC(12,2) NOT NULL,
  status TEXT NOT NULL DEFAULT 'pending',   -- 'pending', 'approved', 'rejected'
  reviewed_by UUID REFERENCES auth.users(id),
  reviewed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ────────────────────────────────────────────────────────────
-- 3. WEEKLY REPORTS — One per seller per submission
-- ────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS weekly_reports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  seller_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  total_sales NUMERIC(12,2) NOT NULL DEFAULT 0.00,
  total_received NUMERIC(12,2) NOT NULL DEFAULT 0.00,
  balance_due NUMERIC(12,2) NOT NULL DEFAULT 0.00,
  last_week_moved INTEGER NOT NULL DEFAULT 0,
  new_arrivals INTEGER NOT NULL DEFAULT 0,
  currently_available INTEGER NOT NULL DEFAULT 0,
  status TEXT NOT NULL DEFAULT 'submitted',  -- 'submitted', 'approved', 'rejected'
  approved_by UUID REFERENCES auth.users(id),
  approved_at TIMESTAMPTZ,
  rejection_reason TEXT,           -- reason if admin rejects the report
  week_start DATE,           -- Monday of the report week
  week_end DATE,             -- Sunday of the report week
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ────────────────────────────────────────────────────────────
-- 4. SALES ENTRIES — Individual product sales lines per report
-- ────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS sales_entries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  report_id UUID NOT NULL REFERENCES weekly_reports(id) ON DELETE CASCADE,
  product_id UUID REFERENCES products(id),   -- link to master product
  product_name TEXT NOT NULL,
  category TEXT NOT NULL DEFAULT '',
  quantity_sold INTEGER NOT NULL DEFAULT 0,
  unit_price NUMERIC(12,2) NOT NULL DEFAULT 0.00,
  total_price NUMERIC(12,2) NOT NULL DEFAULT 0.00,
  amount_received NUMERIC(12,2) NOT NULL DEFAULT 0.00,
  balance_due NUMERIC(12,2) NOT NULL DEFAULT 0.00,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ────────────────────────────────────────────────────────────
-- 5. PRODUCT MOVEMENTS — Inventory movement lines per report
-- ────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS product_movements (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  report_id UUID NOT NULL REFERENCES weekly_reports(id) ON DELETE CASCADE,
  product_id UUID REFERENCES products(id),   -- link to master product
  product_name TEXT NOT NULL,
  previous_stock INTEGER NOT NULL DEFAULT 0,
  products_moved INTEGER NOT NULL DEFAULT 0,
  new_stock_added INTEGER NOT NULL DEFAULT 0,
  current_stock INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ────────────────────────────────────────────────────────────
-- 6. AUTO-UPDATE updated_at TRIGGER
-- ────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_products_updated_at
  BEFORE UPDATE ON products
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ────────────────────────────────────────────────────────────
-- 7. ROW LEVEL SECURITY (RLS)
-- ────────────────────────────────────────────────────────────

-- Enable RLS on all tables
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
ALTER TABLE price_change_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE weekly_reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE sales_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE product_movements ENABLE ROW LEVEL SECURITY;

-- ── Products ──
-- All authenticated users can read products
CREATE POLICY "Authenticated users can read products"
  ON products FOR SELECT
  TO authenticated
  USING (true);

-- Admins can insert/update/delete products
CREATE POLICY "Admins can manage products"
  ON products FOR ALL
  TO authenticated
  USING (
    (SELECT raw_user_meta_data->>'role' FROM auth.users WHERE id = auth.uid()) = 'Admin'
  )
  WITH CHECK (
    (SELECT raw_user_meta_data->>'role' FROM auth.users WHERE id = auth.uid()) = 'Admin'
  );

-- ── Price Change Requests ──
-- Users can read their own requests
CREATE POLICY "Users can read own price requests"
  ON price_change_requests FOR SELECT
  TO authenticated
  USING (requested_by = auth.uid());

-- Admins can read all requests
CREATE POLICY "Admins can read all price requests"
  ON price_change_requests FOR SELECT
  TO authenticated
  USING (
    (SELECT raw_user_meta_data->>'role' FROM auth.users WHERE id = auth.uid()) = 'Admin'
  );

-- Any authenticated user can insert a price change request
CREATE POLICY "Authenticated users can create price requests"
  ON price_change_requests FOR INSERT
  TO authenticated
  WITH CHECK (requested_by = auth.uid());

-- Admins can update (approve/reject) price change requests
CREATE POLICY "Admins can update price requests"
  ON price_change_requests FOR UPDATE
  TO authenticated
  USING (
    (SELECT raw_user_meta_data->>'role' FROM auth.users WHERE id = auth.uid()) = 'Admin'
  );

-- ── Weekly Reports ──
-- Sellers can read their own reports
CREATE POLICY "Sellers can read own reports"
  ON weekly_reports FOR SELECT
  TO authenticated
  USING (seller_id = auth.uid());

-- Admins can read all reports
CREATE POLICY "Admins can read all reports"
  ON weekly_reports FOR SELECT
  TO authenticated
  USING (
    (SELECT raw_user_meta_data->>'role' FROM auth.users WHERE id = auth.uid()) = 'Admin'
  );

-- Sellers can insert their own reports
CREATE POLICY "Sellers can insert own reports"
  ON weekly_reports FOR INSERT
  TO authenticated
  WITH CHECK (seller_id = auth.uid());

-- Admins can update report status (approve/reject)
CREATE POLICY "Admins can update reports"
  ON weekly_reports FOR UPDATE
  TO authenticated
  USING (
    (SELECT raw_user_meta_data->>'role' FROM auth.users WHERE id = auth.uid()) = 'Admin'
  );

-- ── Sales Entries ──
-- Users can read entries for reports they own
CREATE POLICY "Users can read own sales entries"
  ON sales_entries FOR SELECT
  TO authenticated
  USING (
    report_id IN (SELECT id FROM weekly_reports WHERE seller_id = auth.uid())
  );

-- Admins can read all sales entries
CREATE POLICY "Admins can read all sales entries"
  ON sales_entries FOR SELECT
  TO authenticated
  USING (
    (SELECT raw_user_meta_data->>'role' FROM auth.users WHERE id = auth.uid()) = 'Admin'
  );

-- Sellers can insert sales entries for their own reports
CREATE POLICY "Sellers can insert sales entries"
  ON sales_entries FOR INSERT
  TO authenticated
  WITH CHECK (
    report_id IN (SELECT id FROM weekly_reports WHERE seller_id = auth.uid())
  );

-- ── Product Movements ──
-- Users can read movements for reports they own
CREATE POLICY "Users can read own movements"
  ON product_movements FOR SELECT
  TO authenticated
  USING (
    report_id IN (SELECT id FROM weekly_reports WHERE seller_id = auth.uid())
  );

-- Admins can read all movements
CREATE POLICY "Admins can read all movements"
  ON product_movements FOR SELECT
  TO authenticated
  USING (
    (SELECT raw_user_meta_data->>'role' FROM auth.users WHERE id = auth.uid()) = 'Admin'
  );

-- Sellers can insert movements for their own reports
CREATE POLICY "Sellers can insert movements"
  ON product_movements FOR INSERT
  TO authenticated
  WITH CHECK (
    report_id IN (SELECT id FROM weekly_reports WHERE seller_id = auth.uid())
  );

-- ────────────────────────────────────────────────────────────
-- 8. SEED DATA — Initial product catalog
--    These are the products currently hardcoded in the app.
--    New products can be added via the admin UI or SQL.
-- ────────────────────────────────────────────────────────────
INSERT INTO products (product_name, category, unit_price, sort_order) VALUES
  -- Soap Products
  ('5 Litre Soap',      'soap',    0.00, 1),
  ('2 Litre Soap',      'soap',    0.00, 2),
  ('1 Litre Soap',      'soap',    0.00, 3),
  ('Unbottled Soap',    'soap',    0.00, 4),
  -- Special Products
  ('5 Litre Detergent', 'special', 0.00, 1),
  ('2 Litre Detergent', 'special', 0.00, 2),
  ('1 Litre Detergent', 'special', 0.00, 3),
  ('Unbottled Detergent','special', 0.00, 4),
  ('Varnish 1 Litre',   'special', 0.00, 5),
  ('Kola 3.5',          'special', 0.00, 6),
  ('16kg Kola',         'special', 0.00, 7),
  -- Paint Products
  ('Wubet 3.5 L unit',  'paint',   0.00, 1),
  ('Wubet 2.5 L Packed','paint',   0.00, 2),
  ('Super 3.5 unit',    'paint',   0.00, 3),
  ('Super 3.5 packed',  'paint',   0.00, 4),
  ('Super 20kg',        'paint',   0.00, 5),
  ('200 ml bar soap',   'paint',   0.00, 6)
ON CONFLICT (product_name, category) DO NOTHING;
