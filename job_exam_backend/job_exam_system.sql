-- Job Exam System Database Schema
-- Create database
CREATE DATABASE IF NOT EXISTS job_exam_system;
USE job_exam_system;

-- Users table
CREATE TABLE users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(150) NOT NULL,
    email VARCHAR(150) UNIQUE NOT NULL,
    phone VARCHAR(20),
    password VARCHAR(255) NOT NULL,
    role ENUM('admin', 'user') DEFAULT 'user',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Positions (e.g., Bank Teller, Developer)
CREATE TABLE positions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(150) NOT NULL,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Exams (linked to positions)
CREATE TABLE exams (
    id INT AUTO_INCREMENT PRIMARY KEY,
    position_id INT NOT NULL,
    title VARCHAR(150) NOT NULL,
    is_paid BOOLEAN DEFAULT FALSE,
    price DECIMAL(10,2) DEFAULT 0.00,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (position_id) REFERENCES positions(id) ON DELETE CASCADE
);

-- Questions
CREATE TABLE questions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    exam_id INT NOT NULL,
    question_text TEXT NOT NULL,
    question_marks INT DEFAULT 1,
    questionImageUrl VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (exam_id) REFERENCES exams(id) ON DELETE CASCADE
);

-- Choices (MCQs)
CREATE TABLE choices (
    id INT AUTO_INCREMENT PRIMARY KEY,
    question_id INT NOT NULL,
    choice_text TEXT NOT NULL,
    is_correct BOOLEAN DEFAULT FALSE,
    FOREIGN KEY (question_id) REFERENCES questions(id) ON DELETE CASCADE
);

-- Resources
CREATE TABLE resources (
    id INT AUTO_INCREMENT PRIMARY KEY,
    position_id INT NOT NULL,
    title VARCHAR(150) NOT NULL,
    file_path VARCHAR(255),
    type ENUM('pdf', 'video', 'text') DEFAULT 'pdf',
    url TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (position_id) REFERENCES positions(id) ON DELETE CASCADE
);

-- Payments
CREATE TABLE payments (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    exam_id INT NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    status ENUM('pending', 'completed', 'failed') DEFAULT 'pending',
    payment_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (exam_id) REFERENCES exams(id) ON DELETE CASCADE
);

-- Results
CREATE TABLE results (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    exam_id INT NOT NULL,
    score INT NOT NULL,
    total_questions INT NOT NULL,
    taken_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (exam_id) REFERENCES exams(id) ON DELETE CASCADE
);

-- For caching (optional JSON storage of questions per exam)
CREATE TABLE question_cache (
    id INT AUTO_INCREMENT PRIMARY KEY,
    exam_id INT NOT NULL,
    cache_json LONGTEXT NOT NULL,
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (exam_id) REFERENCES exams(id) ON DELETE CASCADE,
    UNIQUE KEY unique_exam_cache (exam_id)
);

-- API Tokens for mobile app authentication
CREATE TABLE api_tokens (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    token VARCHAR(64) UNIQUE NOT NULL,
    expires_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Activity logs for admin tracking
CREATE TABLE activity_logs (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT,
    action VARCHAR(100) NOT NULL,
    details TEXT,
    ip_address VARCHAR(45),
    user_agent TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL
);

-- Insert default admin user
-- Password: admin123 (hashed with password_hash)
INSERT INTO users (name, email, phone, password, role) VALUES 
('Admin User', 'admin@jobexam.com', '+1234567890', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'admin');

-- Insert sample positions
INSERT INTO positions (title, description) VALUES 
('Bank Teller', 'Customer service role in banking sector with cash handling and customer interaction'),
('Software Developer', 'Programming and software development positions'),
('Customer Service Agent', 'Customer support and service roles'),
('Data Entry Clerk', 'Administrative data entry and processing positions'),
('Sales Representative', 'Sales and business development roles');

-- Insert sample exams
INSERT INTO exams (position_id, title, is_paid, price) VALUES 
(1, 'Bank Teller Basic Skills', FALSE, 0.00),
(1, 'Bank Teller Advanced', TRUE, 19.99),
(2, 'Programming Fundamentals', FALSE, 0.00),
(2, 'Full Stack Development', TRUE, 29.99),
(3, 'Customer Service Basics', FALSE, 0.00),
(4, 'Data Entry Skills', FALSE, 0.00),
(5, 'Sales Techniques', TRUE, 15.99);

-- Insert sample questions for Bank Teller Basic Skills
INSERT INTO questions (exam_id, question_text, questionImageUrl) VALUES 
(1, 'What is the primary responsibility of a bank teller?', NULL),
(1, 'Which document is required for opening a savings account?', NULL),
(1, 'What should you do if you suspect counterfeit money?', NULL),
(1, 'What is the maximum amount for a cash withdrawal without manager approval?', NULL),
(1, 'How should you greet a customer at the counter?', NULL);

-- Insert choices for the questions
INSERT INTO choices (question_id, choice_text, is_correct) VALUES 
-- Question 1
(1, 'Process customer transactions', TRUE),
(1, 'Manage the entire bank', FALSE),
(1, 'Only handle deposits', FALSE),
(1, 'Only handle withdrawals', FALSE),

-- Question 2
(2, 'Valid government ID', TRUE),
(2, 'Credit card', FALSE),
(2, 'Utility bill only', FALSE),
(2, 'No documents needed', FALSE),

-- Question 3
(3, 'Accept it and process normally', FALSE),
(3, 'Refuse it and call security', TRUE),
(3, 'Give it back to customer', FALSE),
(3, 'Ignore the suspicion', FALSE),

-- Question 4
(4, '$500', FALSE),
(4, '$1000', FALSE),
(4, '$2500', TRUE),
(4, 'No limit', FALSE),

-- Question 5
(5, 'Hello, how can I help you today?', TRUE),
(5, 'What do you want?', FALSE),
(5, 'Next!', FALSE),
(5, 'Hurry up', FALSE);

-- Insert sample resources
INSERT INTO resources (position_id, title, type, url) VALUES 
(1, 'Bank Teller Training Guide', 'pdf', 'https://example.com/bank-teller-guide.pdf'),
(1, 'Cash Handling Best Practices', 'video', 'https://youtube.com/watch?v=example1'),
(2, 'Programming Fundamentals Course', 'video', 'https://youtube.com/watch?v=example2'),
(3, 'Customer Service Handbook', 'pdf', 'https://example.com/customer-service.pdf');

-- Create indexes for better performance
CREATE INDEX idx_exams_position ON exams(position_id);
CREATE INDEX idx_questions_exam ON questions(exam_id);
CREATE INDEX idx_choices_question ON choices(question_id);
CREATE INDEX idx_results_user ON results(user_id);
CREATE INDEX idx_results_exam ON results(exam_id);
CREATE INDEX idx_payments_user ON payments(user_id);
CREATE INDEX idx_payments_exam ON payments(exam_id);
CREATE INDEX idx_resources_position ON resources(position_id);
CREATE INDEX idx_api_tokens_user ON api_tokens(user_id);
CREATE INDEX idx_api_tokens_expires ON api_tokens(expires_at);
CREATE INDEX idx_activity_logs_user ON activity_logs(user_id);
CREATE INDEX idx_activity_logs_created ON activity_logs(created_at);
