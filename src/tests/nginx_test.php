<?php
$response = file_get_contents("http://localhost/test.html");
if (strpos($response, "Nginx is working correctly!") !== false) {
    echo "Nginx status test successful!";
} else {
    echo "Failed to retrieve the test page.";
}
?>
