﻿<?php
include_once("consts.php");
include_once("db.php");
include_once("serverlib.php");

global $STATS_PERIOD;
$STATS_PERIOD = 600; //seconds between stat records

function AddStatsRecord($con, $rev) {
	date_default_timezone_set("UTC");
	$time = date("Y-m-d H:i:s");
	$data = $con->query("SELECT SUM(Players) AS PlayerSum, COUNT(IP) AS ServerCount FROM Servers WHERE Rev='$rev'");
	$data = $data->fetch_array();
	$players = $data["PlayerSum"];
	$servers = $data["ServerCount"];
	$con->query("INSERT INTO Stats (Rev, Timestamp, Players, Servers) VALUES ('$rev', '$time', $players, $servers)");
	//Also update the player time
	global $STATS_PERIOD;
	$playersMinutes = round($players*$STATS_PERIOD / 60);
	$con->query("INSERT INTO PlayerTime (Rev, PlayerMinutes) VALUES ('$rev', $playersMinutes) ON DUPLICATE KEY UPDATE PlayerMinutes = PlayerMinutes + $playersMinutes");
}

//Currently unused, it could be used in future to avoid needing cron to update stats
function StatsUpdate($con, $rev) {
	date_default_timezone_set("UTC");
	$TenMinsAgo = time() - $STATS_PERIOD;
	//Are there any rows where the timestamp is sooner than 10 minutes ago?
	$data = $con->query("SELECT Timestamp FROM Stats WHERE Rev='$rev' AND Timestamp > '$TenMinsAgo'");
	//No timestamp within the last 10 minutes, so we need to record stats
	if($data->num_rows() == 0) {
		AddStatsRecord($con, $rev);
	}
}

function GetServerGraph($con, $rev, $size = array(500, 200), $timespan = array(0, 0), $numperiods = 0, $Format='') {
	global $STATS_PERIOD;
	
	date_default_timezone_set("UTC");

	$tsince = ($timespan[0] > 0) ? $timespan[0] : 0;
	$tto    = ($timespan[1] > 0) ? $timespan[1] : time();
	$sqlsince = date("Y-m-d H:i:s", $tsince);
	$sqlto = date("Y-m-d H:i:s", $tto);
	$showdates = intval($tto - $tsince > 2 * 60*60*24);
	$width  = $size[0];
	$height = $size[1];
	if($numperiods == 0) {
		$numperiods = $width / 28;
	}
	
	$ServerLine = "";
	$PlayerLine = "";
	$Timestamps = "";
	
	$CountMax = 0;

	$data = $con->query("SELECT Timestamp, Players, Servers FROM Stats WHERE Rev = '$rev' AND Timestamp >= '$sqlsince' AND Timestamp <= '$sqlto ORDER BY Timestamp ASC'");
	$period = round($data->num_rows / ($numperiods-2));
	$p = $period;
	while($row = $data->fetch_array()) {
		if (!($p++ % $period)) {
			$Timestamps .= 't('.strtotime($row["Timestamp"]).",$showdates),";
			$p = 1;
		}
		$LastTimestamp = $row["Timestamp"];
		$ServerLine .= "'".$row["Servers"]."',";
		$PlayerLine .= "'".$row["Players"]."',";

		$CountMax = ($row["Servers"] > $CountMax) ? $row["Servers"] : $CountMax;
		$CountMax = ($row["Players"] > $CountMax) ? $row["Players"] : $CountMax;
	}
	
	$ServerLine = rtrim($ServerLine, ",");
	$PlayerLine = rtrim($PlayerLine, ",");
	$Timestamps.= 't('.strtotime($LastTimestamp).",$showdates)";
	//$Timestamps.= 't('.strtok($Stats[count($Stats) - 1], ',').')';

	$xticks = ($tto - $tsince) / $STATS_PERIOD / $period;
	
	if($Format == 'kamclub') {
		$ServersTitle = 'Сервера';
		$PlayersTitle = 'Игроки';
	} else {
		$ServersTitle = 'Servers';
		$PlayersTitle = 'Players';
	}
	
	return 
	'<canvas id="Stats" width="'.$width.'" height="'.$height.'">[No canvas support]</canvas><script>
		function t(ts,d) {
			var date = new Date(ts * 1000);
			if(d) {
				var day = (date.getDate()<=9 ? "0" + date.getDate() : date.getDate());
				var month = ((date.getMonth()+1)<=9 ? "0" + (date.getMonth()+1) : (date.getMonth()+1));
				return day+"/"+month;
			} else {
				var hours = (date.getHours() < 10) ? String(0)+date.getHours() : date.getHours();
				var minutes = (date.getMinutes() < 10) ? String(0)+date.getMinutes() : date.getMinutes();
				return hours+":"+minutes;
			}
		}
        window.onload = function () {
            var line = new RGraph.Line("Stats", ['.$ServerLine.'], ['.$PlayerLine.']);
            line.Set("chart.linewidth", 2);
            line.Set("chart.colors", ["red", "black"]);
            //line.Set("chart.title", "Statistics");
            line.Set("chart.labels", ['.$Timestamps.']);
			line.Set("chart.key", ["'.$ServersTitle.'", "'.$PlayersTitle.'"]);
			line.Set("chart.text.angle", 45);
			line.Set("chart.gutter.bottom", 50);
			line.Set("chart.gutter.left", 40);
			line.Set("chart.gutter.top", 10);
			line.Set("chart.gutter.right", 10);
			line.Set("chart.xticks", '.$xticks.');
			line.Set("chart.key.position.y", 15);
			line.Set("chart.key.position.x", '.($width - 82).');
			line.Set("chart.ymax", '.(($CountMax + 5) * 1.2).');
			line.Set("chart.text.font", "Calibri, MS Sans Serif, Arial, sans-serif");
            line.Draw();
        }
    </script>';	
}

$con = db_connect();
$format = "";
if(isset($_REQUEST['format'])) $format = $con->real_escape_string($_REQUEST['format']);

if ( basename(__FILE__) == basename($_SERVER["SCRIPT_FILENAME"]) ) { //if we have been called directly
	global $MAIN_VERSION;
	if (
		isset($_REQUEST["since"]) &&
		isset($_REQUEST["to"]) && 
		isset($_REQUEST["width"]) && 
		isset($_REQUEST["height"]) && 
		isset($_REQUEST["period"])
	) {
		if (isset($_REQUEST["html"]))
			echo '<!doctype html><html><head><META HTTP-EQUIV="Content-Type" CONTENT="text/html; charset=UTF-8">
			<script src="RGraph/libraries/RGraph.common.core.js" ></script><script src="RGraph/libraries/RGraph.line.js">
			</script><!--[if IE 8]><script src="RGraph/excanvas/excanvas.original.js"></script><![endif]--></head><body>';
		echo GetServerGraph($con, $MAIN_VERSION, array($con->real_escape_string($_REQUEST["width"]), $con->real_escape_string($_REQUEST["height"])), 
			array($con->real_escape_string($_REQUEST["since"]), $con->real_escape_string($_REQUEST["to"])), $con->real_escape_string($_REQUEST["period"]), $format);
		if (isset($_REQUEST["html"])) echo '</body></html>';
	} 
	else if (isset($_REQUEST["default"])) {
		echo '<!doctype html><html><head><META HTTP-EQUIV="Content-Type" CONTENT="text/html; charset=UTF-8">
		<script src="RGraph/libraries/RGraph.common.core.js" ></script><script src="RGraph/libraries/RGraph.line.js">
		</script><!--[if IE 8]><script src="RGraph/excanvas/excanvas.original.js"></script><![endif]--></head><body>';
		echo GetServerGraph($con, $MAIN_VERSION, array(512,256), array(time() - 24*60*60, time()), 28, $format);
		echo '</body></html>';
	} 
	else echo '<!doctype html><html><head></head><body><form><p>All textfields are mandatory!</p>
		<label>since (timestamp): </label><input name="since" type="text" value="0"><br>
		<label>to (timestamp): </label><input name="to" type="text" value="0"><br>
		<label>width (pixel): </label><input name="width" type="text" value="512"><br>
		<label>height (pixel): </label><input name="height" type="text" value="256"><br>
		<label>period: </label><input name="period" type="text" value="28"><br>
		<input type="checkbox" name="html" value="true" checked><label>include HTML-header and footer</label><br>
		<input type="submit" value="Submit"></form></body></html>';
}
$con->close();

?>
