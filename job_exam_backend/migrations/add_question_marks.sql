-- Migration: Add question_marks field to questions table
-- Run this script to add the question_marks field to existing databases

USE job_exam_system;

-- Add question_marks column with default value of 1
ALTER TABLE questions ADD COLUMN question_marks INT DEFAULT 1 AFTER question_text;

-- Update existing questions to have default marks of 1
UPDATE questions SET question_marks = 1 WHERE question_marks IS NULL;

-- Make sure the column is not null after setting defaults
ALTER TABLE questions MODIFY COLUMN question_marks INT NOT NULL DEFAULT 1;
