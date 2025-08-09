<?php
require_once '../../includes/auth.php';
require_once '../../includes/helpers.php';

// Check if user is logged in and is admin (supports both session and API token)
$current_user = getCurrentUserOrToken();
if (!$current_user || !isAdmin($current_user)) {
    sendErrorResponse('Unauthorized access', 403);
}

// Only allow POST method
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    sendErrorResponse('Method not allowed', 405);
}

// Check if file was uploaded
if (!isset($_FILES['file']) || $_FILES['file']['error'] !== UPLOAD_ERR_OK) {
    sendErrorResponse('No file uploaded or upload error');
}

$file = $_FILES['file'];
$exam_id = isset($_POST['exam_id']) ? (int)$_POST['exam_id'] : 0;

if ($exam_id <= 0) {
    sendErrorResponse('Invalid exam ID');
}

// Check if exam exists
$exam_check = "SELECT id, title FROM exams WHERE id = $exam_id";
$exam_result = mysqli_query($conn, $exam_check);

if (mysqli_num_rows($exam_result) == 0) {
    sendErrorResponse('Exam not found', 404);
}

$exam = mysqli_fetch_assoc($exam_result);

// Validate file type by extension (CSV only)
$allowed_extensions = ['csv'];

// Upload file
$upload_dir = '../../uploads/questions_bulk/';
if (!is_dir($upload_dir)) {
    mkdir($upload_dir, 0755, true);
}

$filepath = uploadFile($file, $upload_dir, $allowed_extensions);
if (!$filepath) {
    sendErrorResponse('Failed to upload file');
}

// Process CSV file
$questions_added = 0;
$questions_failed = 0;

if (($handle = fopen($filepath, 'r')) !== false) {
    // Skip header row
    fgetcsv($handle);

    while (($data = fgetcsv($handle)) !== false) {
        // Expecting: exam_id, question_text, choice_a, choice_b, choice_c, choice_d, choice_e, correct_answer
        if (count($data) >= 8) {
            $question_text = sanitizeInput($data[1]);
            $choice_a = sanitizeInput($data[2]);
            $choice_b = sanitizeInput($data[3]);
            $choice_c = sanitizeInput($data[4]);
            $choice_d = sanitizeInput($data[5]);
            $choice_e = sanitizeInput($data[6]);
            $correct_answer = strtoupper(trim($data[7]));

            // Validate correct answer (A, B, C, D, E)
            $valid_answers = ['A', 'B', 'C', 'D', 'E'];
            if (!in_array($correct_answer, $valid_answers, true)) {
                $questions_failed++;
                continue;
            }

            // Insert question
            $question_query = "INSERT INTO questions (exam_id, question_text) VALUES ($exam_id, '$question_text')";

            if (mysqli_query($conn, $question_query)) {
                $question_id = mysqli_insert_id($conn);

                // Insert choices
                $choices = [
                    'A' => $choice_a,
                    'B' => $choice_b,
                    'C' => $choice_c,
                    'D' => $choice_d,
                    'E' => $choice_e,
                ];
                $success = true;

                foreach ($choices as $letter => $choice_text) {
                    if (!empty(trim($choice_text))) { // Only insert non-empty choices
                        $is_correct = ($letter === $correct_answer) ? 1 : 0;
                        $choice_text = sanitizeInput($choice_text);
                        $choice_query = "INSERT INTO choices (question_id, choice_text, is_correct) VALUES ($question_id, '$choice_text', $is_correct)";

                        if (!mysqli_query($conn, $choice_query)) {
                            $success = false;
                            break;
                        }
                    }
                }

                if ($success) {
                    $questions_added++;
                } else {
                    $questions_failed++;
                }
            } else {
                $questions_failed++;
            }
        } else {
            $questions_failed++;
        }
    }
    fclose($handle);
}

// Delete uploaded file
unlink($filepath);

// Log activity
logActivity($current_user['id'], 'bulk_upload_questions', "Uploaded $questions_added questions for exam: " . $exam['title']);

sendSuccessResponse([
    'questions_added' => $questions_added,
    'questions_failed' => $questions_failed,
    'exam_title' => $exam['title']
], "Bulk upload completed. $questions_added questions added, $questions_failed failed.");
?>
