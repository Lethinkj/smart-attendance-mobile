-- Smart Attendance Admin Table Creation Script
-- Run this in Supabase SQL Editor

-- Create admins table
CREATE TABLE IF NOT EXISTS admins (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    username TEXT UNIQUE NOT NULL,
    password TEXT NOT NULL,
    name TEXT NOT NULL,
    email TEXT,
    role TEXT DEFAULT 'Admin',
    school_id TEXT,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    is_active BOOLEAN DEFAULT TRUE
);

-- Insert default admin account
INSERT INTO admins (id, username, password, name, email, role, school_id, is_active)
VALUES (
    'admin-001',
    'admin',
    'admin',
    'System Administrator',
    'admin@smartattendance.com',
    'Admin',
    'default-school',
    true
)
ON CONFLICT (username) DO UPDATE SET
    password = EXCLUDED.password,
    name = EXCLUDED.name,
    email = EXCLUDED.email,
    updated_at = NOW();

-- Create index for faster authentication queries
CREATE INDEX IF NOT EXISTS idx_admins_username_password ON admins(username, password);
CREATE INDEX IF NOT EXISTS idx_admins_active ON admins(is_active);

-- Enable Row Level Security (RLS)
ALTER TABLE admins ENABLE ROW LEVEL SECURITY;

-- Create policy to allow authenticated access
CREATE POLICY "Allow authenticated access to admins" ON admins
    FOR ALL USING (auth.role() = 'authenticated' OR auth.role() = 'anon');

COMMENT ON TABLE admins IS 'Administrator accounts for Smart Attendance system';