<?php                                     
// TEST SQL handshake                                                            
function SQLQUERY($servername, $dbname,$username, $password) {
$i=0;
$conn = mysqli_connect($servername, $username, $password);
if(! $conn ) {
die('Could not connect: ' . mysqli_error($conn));
}
echo "Connected successfully ". mysqli_get_host_info($conn) ."<p>";

$retval = mysqli_select_db( $conn, $dbname );
if(! $retval ) {
die('Could not select database: ' . mysqli_error($conn));
}
echo "Database $dbname selected successfully\n";

$sql = "SELECT * from tblleads LIMIT 0, 100";

echo "<p> RAW SLQ >>> $sql <p>";

$date_start = new DateTimeImmutable();
echo "START=".date_format($date_start, ' H:i:s:u'). "<p>";
$start = microtime(true);

$result = $conn->query($sql);

while($row = $result->fetch_assoc()) {
$i+=1;
  }

$time_elapsed_secs = microtime(true) - $start;
$date_end = new DateTimeImmutable();
echo "TOTAL raws:  $i <br>";
echo "FINISH = ".date_format($date_end, ' H:i:s:u')."<p>";
echo "COUNT total time QUERY  $time_elapsed_secs <p>";
}

$servername = "192.168.1.1";
$username = "xxxxxxxxxxx";
$dbname = "xxxxxxxxxxx";
$password = "xxxxxxxxxxxxxxxxxx";
echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++<p>";
SQLQUERY($servername, $dbname,$username, $password);
echo "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%<p>";
$servername = "192.168.1.1";
$username = "xxxxxxxxxxx";
$dbname = "xxxxxxxxxxx";
$password = "xxxxxxxxxxxxxxxxxx";
echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++<p>";
SQLQUERY($servername, $dbname,$username, $password);

?>
