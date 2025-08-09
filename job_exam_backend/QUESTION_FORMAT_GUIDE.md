# Question Format Guide

## Overview

This guide explains how questions are structured in the Job Exam System, including the database schema, API responses, and bulk upload format.

## Database Structure

### Questions Table
```sql
CREATE TABLE questions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    exam_id INT NOT NULL,
    question_text TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (exam_id) REFERENCES exams(id) ON DELETE CASCADE
);
```

### Choices Table
```sql
CREATE TABLE choices (
    id INT AUTO_INCREMENT PRIMARY KEY,
    question_id INT NOT NULL,
    choice_text TEXT NOT NULL,
    is_correct BOOLEAN DEFAULT FALSE,
    FOREIGN KEY (question_id) REFERENCES questions(id) ON DELETE CASCADE
);
```

## Question Format

### 1. Database Storage
- Each question has multiple choices (typically 4-5)
- Only ONE choice per question has `is_correct = 1`
- All other choices have `is_correct = 0`

### 2. Mobile App Response Format
**Important**: Correct answers are NEVER sent to the mobile app for security reasons.

```json
[
  {
    "id": 1,
    "question_text": "What is the capital of Rwanda?",
    "choices": [
      {
        "id": 11,
        "choice_text": "Kigali"
      },
      {
        "id": 12,
        "choice_text": "Musanze"
      },
      {
        "id": 13,
        "choice_text": "Huye"
      },
      {
        "id": 14,
        "choice_text": "Rubavu"
      }
    ]
  }
]
```

### 3. Correct Answer Handling
- Correct answers are stored in the database with `is_correct = 1`
- They are used server-side for scoring when users submit exam results
- The mobile app only receives the question text and choices (without correct answer indicators)

## Option Labeling (A, B, C, D, E)

### Frontend Responsibility
- Option labels (A, B, C, D, E) are managed by the frontend/mobile app
- The backend provides choice IDs and text only
- The frontend can assign labels in any order or format

### Example Frontend Implementation
```javascript
// Frontend can map choices to labels like this:
const choices = question.choices;
const labels = ['A', 'B', 'C', 'D', 'E'];

choices.forEach((choice, index) => {
    choice.label = labels[index]; // A, B, C, D, E
});
```

## Bulk Upload Format

### CSV Structure
The bulk upload expects a CSV file with the following columns:

| Column | Description | Example |
|--------|-------------|---------|
| exam_id | The exam ID this question belongs to | 1 |
| question_text | The question text | "What is the capital of Rwanda?" |
| choice_a | First choice option | "Kigali" |
| choice_b | Second choice option | "Musanze" |
| choice_c | Third choice option | "Huye" |
| choice_d | Fourth choice option | "Rubavu" |
| choice_e | Fifth choice option (optional) | "" |
| correct_answer | Correct answer letter (A, B, C, D, E) | "A" |

### Sample CSV File
```csv
exam_id,question_text,choice_a,choice_b,choice_c,choice_d,choice_e,correct_answer
1,What is the capital of Rwanda?,Kigali,Musanze,Huye,Rubavu,,A
1,Which programming language is known as the language of the web?,JavaScript,Python,Java,C++,,A
1,What does HTML stand for?,HyperText Markup Language,High Tech Modern Language,Home Tool Markup Language,Hyperlink and Text Markup Language,,A
```

### Important Notes for Bulk Upload
1. **Correct Answer Format**: Use letters A, B, C, D, E (case-insensitive)
2. **Optional Choice E**: Leave empty if you only want 4 choices
3. **Exam ID**: Must be a valid exam ID that exists in the database
4. **No Empty Questions**: Question text cannot be empty
5. **Valid Choices**: At least 2 choices must be provided per question

## API Endpoints

### Get Questions for Mobile App
```
GET /api/questions.php?exam_id=1
```

**Response**: Questions without correct answers (for security)

### Submit Exam Results
```
POST /api/submit_results.php
```

**Request Body**:
```json
{
  "exam_id": 1,
  "answers": {
    "1": 11,  // question_id: choice_id
    "2": 15,
    "3": 19
  }
}
```

**Response**: Score and results with correct/incorrect answers

## Security Considerations

1. **No Correct Answers in Mobile API**: The mobile app never receives correct answers to prevent cheating
2. **Server-Side Scoring**: All scoring is done server-side using the correct answers stored in the database
3. **Token Authentication**: Paid exams require valid API tokens
4. **Purchase Verification**: Users must purchase paid exams before accessing questions

## Example Workflow

1. **Admin Uploads Questions**: Uses bulk upload with CSV format
2. **Database Storage**: Questions and choices stored with correct answer flags
3. **Mobile App Requests**: Gets questions without correct answers
4. **User Takes Exam**: Selects choices (frontend assigns A, B, C, D, E labels)
5. **Submit Results**: Sends choice IDs to server
6. **Server Scoring**: Compares user choices with correct answers in database
7. **Return Results**: Provides score and review information

## Testing

Use the sample files provided:
- `sample_questions.csv` - Example bulk upload file
- `sample_question_format.json` - Detailed format specification

## Support

For questions about the question format or implementation, refer to:
- Database schema in `job_exam_system.sql`
- API documentation in `index.php`
- Helper functions in `includes/helpers.php`
