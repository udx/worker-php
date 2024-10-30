<?php
$url = "http://localhost/index.html";
$expectedContent = "Hello from NGINX";  // Update this if needed to match the actual content in index.html
$attempts = 5;
$delayBetweenAttempts = 2;

for ($i = 0; $i < $attempts; $i++) {
    $response = @file_get_contents($url);

    if ($response !== false) {
        if (strpos($response, $expectedContent) !== false) {
            echo "Nginx status test successful!\n";
            exit(0);
        } else {
            echo "Test page content did not match expected output.\n";
            echo "Response: " . $response . "\n";
            exit(1);
        }
    } else {
        echo "Attempt " . ($i + 1) . " of $attempts: Failed to retrieve the index page. Retrying in $delayBetweenAttempts seconds...\n";
        $error = error_get_last();
        echo "Error: " . $error['message'] . "\n";
        sleep($delayBetweenAttempts);
    }
}

echo "Failed to retrieve the index page after $attempts attempts.\n";
exit(1);
?>
