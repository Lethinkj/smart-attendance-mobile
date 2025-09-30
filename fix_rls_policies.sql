-- Fix RLS Policies for Smart Attendance System
-- Run this script in your Supabase SQL Editor to fix the school creation issue

-- Drop existing policies
DROP POLICY IF EXISTS "Schools are viewable by authenticated users" ON schools;
DROP POLICY IF EXISTS "Schools can be inserted by authenticated users" ON schools;
DROP POLICY IF EXISTS "Schools can be updated by authenticated users" ON schools;

DROP POLICY IF EXISTS "Staff are viewable by authenticated users" ON staff;
DROP POLICY IF EXISTS "Staff can be inserted by authenticated users" ON staff;
DROP POLICY IF EXISTS "Staff can be updated by authenticated users" ON staff;

DROP POLICY IF EXISTS "Students are viewable by authenticated users" ON students;
DROP POLICY IF EXISTS "Students can be inserted by authenticated users" ON students;
DROP POLICY IF EXISTS "Students can be updated by authenticated users" ON students;

DROP POLICY IF EXISTS "Attendance is viewable by authenticated users" ON attendance;
DROP POLICY IF EXISTS "Attendance can be inserted by authenticated users" ON attendance;
DROP POLICY IF EXISTS "Attendance can be updated by authenticated users" ON attendance;

-- Create permissive policies that allow all operations for now
-- (In production, you'll want to implement proper authentication)

-- Schools policies
CREATE POLICY "Allow all operations on schools" ON schools
    FOR ALL USING (true) WITH CHECK (true);

-- Staff policies  
CREATE POLICY "Allow all operations on staff" ON staff
    FOR ALL USING (true) WITH CHECK (true);

-- Students policies
CREATE POLICY "Allow all operations on students" ON students
    FOR ALL USING (true) WITH CHECK (true);

-- Attendance policies
CREATE POLICY "Allow all operations on attendance" ON attendance
    FOR ALL USING (true) WITH CHECK (true);

-- Optional: Disable RLS temporarily for development
-- Uncomment these lines if you want to completely disable RLS for now
-- ALTER TABLE schools DISABLE ROW LEVEL SECURITY;
-- ALTER TABLE staff DISABLE ROW LEVEL SECURITY; 
-- ALTER TABLE students DISABLE ROW LEVEL SECURITY;
-- ALTER TABLE attendance DISABLE ROW LEVEL SECURITY;