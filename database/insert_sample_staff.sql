-- Insert sample staff data for testing staff authentication
-- Run this in Supabase SQL editor after creating the tables

-- Insert a sample school if it doesn't exist
INSERT INTO schools (id, name, unique_id, address, phone, email, principal_name, is_active, created_at, updated_at)
VALUES (
  'SCH001',
  'Demo High School',
  'DEMO001',
  '123 Education Street, City, State',
  '+1-555-123-4567',
  'admin@demoschool.edu',
  'Dr. Principal Name',
  true,
  NOW(),
  NOW()
) ON CONFLICT (id) DO NOTHING;

-- Insert sample staff members for testing
INSERT INTO staff (
  id,
  staff_id,
  school_id,
  name,
  email,
  phone,
  role,
  assigned_classes,
  rfid_tag,
  is_active,
  is_first_login,
  password,
  created_at,
  updated_at
) VALUES 
-- Staff member 1: Teacher with default password
(
  'staff-001',
  'TCH001',
  'SCH001',
  'John Smith',
  'john.smith@demoschool.edu',
  '+1-555-111-0001',
  'Teacher',
  '["Math Grade 10", "Math Grade 11"]',
  'RFID001',
  true,
  true,
  'staff123',
  NOW(),
  NOW()
),
-- Staff member 2: Another teacher
(
  'staff-002',
  'TCH002',
  'SCH001',
  'Sarah Johnson',
  'sarah.johnson@demoschool.edu',
  '+1-555-111-0002',
  'Teacher',
  '["English Grade 9", "English Grade 10"]',
  'RFID002',
  true,
  true,
  'staff123',
  NOW(),
  NOW()
),
-- Staff member 3: Principal/Admin staff
(
  'staff-003',
  'ADM001',
  'SCH001',
  'Dr. Principal Name',
  'principal@demoschool.edu',
  '+1-555-111-0003',
  'Principal',
  '[]',
  'RFID003',
  true,
  true,
  'staff123',
  NOW(),
  NOW()
),
-- Staff member 4: Subject Head
(
  'staff-004',
  'HOD001',
  'SCH001',
  'Michael Brown',
  'michael.brown@demoschool.edu',
  '+1-555-111-0004',
  'Head of Science',
  '["Physics Grade 11", "Physics Grade 12"]',
  'RFID004',
  true,
  true,
  'staff123',
  NOW(),
  NOW()
),
-- Staff member 5: Librarian
(
  'staff-005',
  'LIB001',
  'SCH001',
  'Emma Wilson',
  'emma.wilson@demoschool.edu',
  '+1-555-111-0005',
  'Librarian',
  '[]',
  'RFID005',
  true,
  true,
  'staff123',
  NOW(),
  NOW()
) ON CONFLICT (staff_id) DO UPDATE SET
  name = EXCLUDED.name,
  email = EXCLUDED.email,
  phone = EXCLUDED.phone,
  role = EXCLUDED.role,
  assigned_classes = EXCLUDED.assigned_classes,
  updated_at = NOW();

-- Verify the data was inserted
SELECT 
  staff_id,
  name,
  email,
  role,
  password,
  is_first_login,
  is_active
FROM staff 
WHERE school_id = 'SCH001'
ORDER BY staff_id;

-- Show usage instructions
SELECT '=== STAFF LOGIN CREDENTIALS ===' as instruction
UNION ALL
SELECT 'Staff ID: TCH001, Password: staff123 (John Smith - Teacher)'
UNION ALL
SELECT 'Staff ID: TCH002, Password: staff123 (Sarah Johnson - Teacher)'
UNION ALL
SELECT 'Staff ID: ADM001, Password: staff123 (Dr. Principal Name - Principal)'
UNION ALL
SELECT 'Staff ID: HOD001, Password: staff123 (Michael Brown - Head of Science)'
UNION ALL
SELECT 'Staff ID: LIB001, Password: staff123 (Emma Wilson - Librarian)'
UNION ALL
SELECT '=== USAGE ===' 
UNION ALL
SELECT 'In the app, select "Staff" login and use Staff ID (not email) with password staff123'
UNION ALL
SELECT 'On first login, staff will be prompted to change their password';