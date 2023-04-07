<?php                                     
echo "++++++++++++++++++++++++++Сheck time select tblnotes ++++++++++++++++++++++++++++++++++<p>";
$comparevalue=0.9;
$logfile = '/var/logs/status.log';


/////////////////////////////////////////////////////////////////////////////
function LOGSTOFILE ($timevalue, $i, $dbname,$teltextstring){
global $comparevalue;	
global $logfile;

// Open the file to get existing content
$current = file_get_contents($logfile);

echo "</br>";
	if ($timevalue < $comparevalue) {
                echo "</br>SELECT TIME less then $comparevalue";
		// Append a new person to the file
                $current .= "OKKK    $teltextstring\n";

	} else {
                echo "</br>SELECT TIME more $timevalue then $comparevalue";
                // Append a new person to the file
                $current .= "ALARM    $teltextstring\n";
	}
// Write the contents back to the file
file_put_contents($logfile, $current);
}
/////////////////////////////////////////////////////////////////////////////
function TELEGRAMSEND ($timevalue, $i, $dbname,$teltextstring){
global $comparevalue;

if ($timevalue < $comparevalue) {
        	echo "</br>SELECT TIME less then $comparevalue";
	} elseif ($timevalue > $comparevalue) {
        	echo "</br>SELECT TIME more then $comparevalue";
//Send status by telegram bot curl POST
//  $teltextstring = "Total time QUERY of $i in $dbname is $timevalue";
  $apiToken = "xxxxxxxxxxxxxx:xxxxxxxxxxxxxxxxxxxxxxxxxxxx";
  $data = [
      'chat_id' => '-xxxxxxxxxxxxxxxxxxxxxxx',
      'text' =>  $teltextstring
  ];
//'Total time QUERY to $dbname is $time_elapsed_secs'
  echo '<pre>'; print_r($data); echo '</pre>';

   $response = file_get_contents("https://api.telegram.org/bot$apiToken/sendMessage?" . http_build_query($data) );
	} else {
    		echo "OTHER";
	}
}
////////////////////////////////////////////////////////////////////////////
// TEST SQL handshake                                                            
function SQLQUERY($servername, $dbname,$username, $password) {
//  echo "</br>Connect to DB host <b>$servername</b></br>";    
	$i=0;
  $conn = mysqli_connect($servername, $username, $password);

  if(! $conn ) {
	die('Could not connect: ' . mysqli_error($conn));
  }
  echo "Connected successfully to <b>". mysqli_get_host_info($conn) ."</b><p>";

$retval = mysqli_select_db( $conn, $dbname );
if(! $retval ) {
	die('Could not select database: ' . mysqli_error($conn));
}

echo "Database <b>$dbname</b> selected successfully\n";

$sql = "SELECT * from tblnotes"; //tblleads ";// LIMIT 0, 100";

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
echo "TOTAL raws:  $i <br>";
echo "FINISH = ".date_format($date_end, ' H:i:s:u')."<p>";
echo "COUNT total time QUERY  $time_elapsed_secs <p>";
//

$teltextstring = "Total time QUERY of $i in $dbname is $time_elapsed_secs";
echo "</br>$teltextstring";

TELEGRAMSEND ($time_elapsed_secs, $i, $dbname,$teltextstring);
LOGSTOFILE ($time_elapsed_secs, $i, $dbname,$teltextstring);
}

echo "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%<p>";
$servername = "dev_mysql"; 
$username   = getenv("MYSQL_USER"); 
$dbname     = getenv("MYSQL_BASE"); 
$password   = getenv("MYSQL_PASS"); 
echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++<p>";
SQLQUERY($servername, $dbname,$username, $password);
?>
