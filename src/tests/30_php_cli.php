<?php
// php_cli_test.php

// Run a basic PHP command to verify if PHP CLI is installed and working
echo "PHP CLI Test: ";
if (php_sapi_name() === 'cli') {
    echo "PHP CLI is installed and accessible.\n";
    exit(0);
} else {
    echo "PHP CLI is not available.\n";
    exit(1);
}
?>
