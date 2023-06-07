<!DOCTYPE html>
<html>
<head>
<title>Welcome to EXP!</title>
<style>
    body {
        width: 35em;
        margin: 0 auto;
        font-family: Tahoma, Verdana, Arial, sans-serif;
    }
</style>
</head>
<body style="background-color:white;">
<h1 style="color:black;">Welcome to EXP!</h1>
</body>
</html>
<?php

// Show all information, defaults to INFO_ALL
phpinfo();

// Show just the module information.
// phpinfo(8) yields identical results.
phpinfo(INFO_MODULES);
?>
