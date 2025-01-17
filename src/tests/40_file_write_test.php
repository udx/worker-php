<?php
$testFile = "/var/www/test_write.txt";
if (file_put_contents($testFile, "Testing file write permissions") !== false) {
    echo "File write test successful!";
    unlink($testFile); // Cleanup
} else {
    echo "Failed to write file. Check permissions.";
}
?>
