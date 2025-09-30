-- Smart Attendance System Database Schema for Supabase
-- Run this script in your Supabase SQL Editor to create the necessary tables

-- Enable RLS (Row Level Security)
-- This will be handled by Supabase automatically, but we'll set up basic policies

-- Schools Table
CREATE TABLE IF NOT EXISTS schools (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    address TEXT NOT NULL,
    phone VARCHAR(20) NOT NULL,
    email VARCHAR(255) NOT NULL,
    school_type VARCHAR(100) NOT NULL DEFAULT 'Primary School',
    unique_id VARCHAR(20) NOT NULL UNIQUE,
    is_active BOOLEAN DEFAULT true,
    total_students INTEGER DEFAULT 0,
    total_staff INTEGER DEFAULT 0,
    classes TEXT[] DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Staff Table
CREATE TABLE IF NOT EXISTS staff (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    staff_id VARCHAR(20) NOT NULL UNIQUE,
    school_id UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    phone VARCHAR(20) NOT NULL,
    role VARCHAR(50) NOT NULL,
    assigned_classes TEXT[] DEFAULT '{}',
    rfid_tag VARCHAR(50) DEFAULT '',
    is_active BOOLEAN DEFAULT true,
    is_first_login BOOLEAN DEFAULT true,
    password VARCHAR(255) DEFAULT 'staff123',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Students Table
CREATE TABLE IF NOT EXISTS students (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    student_id VARCHAR(20) NOT NULL,
    school_id UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    class_name VARCHAR(50) NOT NULL,
    section VARCHAR(10) NOT NULL,
    roll_number VARCHAR(20) NOT NULL,
    rfid_tag VARCHAR(50) DEFAULT '',
    parent_name VARCHAR(255) NOT NULL,
    parent_phone VARCHAR(20) NOT NULL,
    parent_email VARCHAR(255) DEFAULT '',
    date_of_birth DATE NOT NULL,
    address TEXT NOT NULL,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(school_id, student_id),
    UNIQUE(school_id, class_name, section, roll_number)
);

-- Attendance Table
CREATE TABLE IF NOT EXISTS attendance (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    student_id UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
    school_id UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
    class_name VARCHAR(50) NOT NULL,
    section VARCHAR(10) NOT NULL,
    date DATE NOT NULL,
    check_in_time TIMESTAMP WITH TIME ZONE,
    check_out_time TIMESTAMP WITH TIME ZONE,
    status VARCHAR(20) DEFAULT 'Absent',
    marked_by UUID REFERENCES staff(id),
    method VARCHAR(20) DEFAULT 'Manual',
    remarks TEXT,
    is_synced BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(student_id, date)
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_schools_unique_id ON schools(unique_id);
CREATE INDEX IF NOT EXISTS idx_staff_school_id ON staff(school_id);
CREATE INDEX IF NOT EXISTS idx_staff_email ON staff(email);
CREATE INDEX IF NOT EXISTS idx_students_school_id ON students(school_id);
CREATE INDEX IF NOT EXISTS idx_students_class ON students(school_id, class_name, section);
CREATE INDEX IF NOT EXISTS idx_attendance_date ON attendance(date);
CREATE INDEX IF NOT EXISTS idx_attendance_school_date ON attendance(school_id, date);
CREATE INDEX IF NOT EXISTS idx_attendance_student_date ON attendance(student_id, date);

-- Create updated_at trigger function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Add updated_at triggers to all tables
CREATE TRIGGER update_schools_updated_at BEFORE UPDATE ON schools FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_staff_updated_at BEFORE UPDATE ON staff FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_students_updated_at BEFORE UPDATE ON students FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_attendance_updated_at BEFORE UPDATE ON attendance FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Enable Row Level Security (RLS)
ALTER TABLE schools ENABLE ROW LEVEL SECURITY;
ALTER TABLE staff ENABLE ROW LEVEL SECURITY;
ALTER TABLE students ENABLE ROW LEVEL SECURITY;
ALTER TABLE attendance ENABLE ROW LEVEL SECURITY;

-- Create RLS Policies (basic policies - you may want to customize these)

-- Schools policies
CREATE POLICY "Schools are viewable by authenticated users" ON schools
    FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Schools can be inserted by authenticated users" ON schools
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Schools can be updated by authenticated users" ON schools
    FOR UPDATE USING (auth.role() = 'authenticated');

-- Staff policies
CREATE POLICY "Staff are viewable by authenticated users" ON staff
    FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Staff can be inserted by authenticated users" ON staff
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Staff can be updated by authenticated users" ON staff
    FOR UPDATE USING (auth.role() = 'authenticated');

-- Students policies
CREATE POLICY "Students are viewable by authenticated users" ON students
    FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Students can be inserted by authenticated users" ON students
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Students can be updated by authenticated users" ON students
    FOR UPDATE USING (auth.role() = 'authenticated');

-- Attendance policies
CREATE POLICY "Attendance is viewable by authenticated users" ON attendance
    FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Attendance can be inserted by authenticated users" ON attendance
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Attendance can be updated by authenticated users" ON attendance
    FOR UPDATE USING (auth.role() = 'authenticated');

-- Insert some sample data (optional)
INSERT INTO schools (name, address, phone, email, school_type, unique_id) VALUES 
('Demo Primary School', '123 Education Street, Demo City', '+1-234-567-8900', 'admin@demoprimary.edu', 'Primary School', 'DPS001'),
('Demo High School', '456 Learning Avenue, Demo City', '+1-234-567-8901', 'admin@demohigh.edu', 'High School', 'DHS001')
ON CONFLICT (unique_id) DO NOTHING;

-- Insert sample admin staff
INSERT INTO staff (staff_id, school_id, name, email, phone, role, password) 
SELECT 'DPS001001', id, 'Admin User', 'admin@demoprimary.edu', '+1-234-567-8900', 'Admin', 'admin123'
FROM schools WHERE unique_id = 'DPS001'
ON CONFLICT (staff_id) DO NOTHING;

INSERT INTO staff (staff_id, school_id, name, email, phone, role, password) 
SELECT 'DHS001001', id, 'Admin User', 'admin@demohigh.edu', '+1-234-567-8901', 'Admin', 'admin123'
FROM schools WHERE unique_id = 'DHS001'
ON CONFLICT (staff_id) DO NOTHING;