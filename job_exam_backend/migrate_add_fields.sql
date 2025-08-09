-- Migration script to add phone and questionImageUrl fields
-- Run this script if you have an existing database

USE job_exam_system;

-- Add phone field to users table
ALTER TABLE users ADD COLUMN phone VARCHAR(20) AFTER email;

-- Add questionImageUrl field to questions table
ALTER TABLE questions ADD COLUMN questionImageUrl VARCHAR(255) AFTER question_text;

-- Update existing admin user with phone number (if exists)
UPDATE users SET phone = '+1234567890' WHERE email = 'admin@jobexam.com' AND phone IS NULL;

-- Verify the changes
DESCRIBE users;
DESCRIBE questions;

-- Show sample data
SELECT id, name, email, phone, role FROM users LIMIT 5;
SELECT id, exam_id, question_text, questionImageUrl FROM questions LIMIT 5;
