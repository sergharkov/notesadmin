<?php
$comparevalue = getenv("TIME_MONITOR");#0.9;
$servername = getenv("MYSQL_HOST"); // "dev_mysql";
$username   = getenv("MYSQL_USER"); // "stage_";
$dbname     = getenv("MYSQL_BASE"); // "stage_";
$password   = getenv("MYSQL_PASS"); // "xxxxxxxxxxxx";
$logfile = '/var/logs/status.log';
$telegramapiToken= 'XXXXXXXXXXXXXXXXXX:XXXXXXXXXXXXXXXXXXXXXXXXXXXXX';

echo "++++++++++++++++++++++++++Сheck time select tblnotes than not more then $comparevalue ++++++++++++++++++++++++++++++++++<p>";
/////////////////////////////////////////////////////////////////////////////
function GETVALUEARRAY(){
global $logfile;
//read file with raws like 
// 2023-04-19 12:50:38  OKKK    Total time QUERY of 100000 in silver_group_org is 1.1176810264587
$arr = array();
echo "</br>$logfile";
$userfile= file_get_contents($logfile); 
   // Place each line of $userfile into array
   $users = explode("\n",$userfile);
   foreach ($users as $user) {
      list($date, $time, $s4, $s5, $s6, $s7, $s8, $s9, $s10, $s11, $s12, $s13, $s14, $DB, $s16, $lag) = explode(" ",$user);
      $fulltime = $date."-".$time;
      //$arr[$lag] = $fulltime;
      //array_push($arr, array($lag,$fulltime));
      $arr[] = array ('y' =>$lag, 'label'=>$fulltime);
   }
//print_r($arr[100]);
//print_r(array_key($arr));
//print_r(array_values($arr));
return $arr;
}
/////////////////////////////////////////////////////////////////////////////////
function LOGSTOFILE ($timevalue, $i, $dbname,$teltextstring){
global $comparevalue;	
global $logfile;
$date_start = new DateTimeImmutable();
// Open the file to get existing content
$current = file_get_contents($logfile);
	if ($timevalue < $comparevalue) {
                echo "</br>LOGSTOFILE: SELECT TIME less then $comparevalue";
		// Append a new person to the file
                $current .= date_format($date_start, 'Y-m-d H:i:s')."  OKKK    $teltextstring\n";
	} else {
                echo "</br>LOGSTOFILE: SELECT TIME more $timevalue then $comparevalue";
    // Append a new person to the file
                $current .= date_format($date_start, 'Y-m-d H:i:s')."  ALARM    $teltextstring\n";
	}
// Write the contents back to the file
file_put_contents($logfile, $current);
}
/////////////////////////////////////////////////////////////////////////////
function TELEGRAMSEND ($timevalue, $i, $dbname,$teltextstring){
global $comparevalue;
global $telegramapiToken;
if ($timevalue < $comparevalue) {
        	echo "</br>TELEGRAM: SELECT TIME less then $comparevalue";
	} elseif ($timevalue > $comparevalue) {
        	echo "</br>TELEGRAM: SELECT TIME more then $comparevalue";
//Send status by telegram bot curl POST
  $data = [
      'chat_id' => '-1001520271519',
      'text' =>  $teltextstring
  ];
//'Total time QUERY to $dbname is $time_elapsed_secs'
  echo '<pre>'; print_r($data); echo '</pre>';
   $response = file_get_contents("https://api.telegram.org/bot$telegramapiToken/sendMessage?" . http_build_query($data) );
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
/////////////////////////////// SQL //////////////////////////
$sql ="SELECT * from tblnotes
//       LIMIT 0, 100"; //tblleads ";// LIMIT 0, 100";                                                     
/////////////////////////////// SQL //////////////////////////
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
?>


<!DOCTYPE HTML>
<html>
<head>

<?php SQLQUERY($servername, $dbname,$username, $password);  ?>

</br>
<form method="post">
    <input type="submit" name="show" value="show"/>
    <input type="submit" name="NoShow" value="noshow"/>
</form>

<?php
    if(isset($_POST['show'])){
            echo "Select buttom show";
	    $arrres=GETVALUEARRAY();
	    print_r($arrres);
    } else {
            echo "Select buttom no show";
    }
?>
<!--From https://canvasjs.com/php-charts/chart-zoom-pan/ -->
<?php
    $arrret= GETVALUEARRAY();
?>
<script>
window.onload = function () {
var chart = new CanvasJS.Chart("chartContainer", {
	theme: "light2", // "light1", "light2", "dark1", "dark2"
	animationEnabled: true,
	zoomEnabled: true,
	title: {
		text: "Try Zooming and Panning"
	},
	data: [{
		type: "area",     
		dataPoints: <?php echo json_encode($arrret, JSON_NUMERIC_CHECK); ?>
	}]
});
chart.render();
}
</script>
</head>
<body>
<div id="chartContainer" style="height: 370px; width: 100%;"></div>
<script src="https://canvasjs.com/assets/script/canvasjs.min.js"></script>
</body>
</html> 
