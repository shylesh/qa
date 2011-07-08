#/usr/bin/php
<?

$fh = fopen('gluster.test', 'ab+');
echo('Opened.'."\n");
sleep(2);
echo('Shared lock attempt.'."\n");
flock($fh, LOCK_SH);
echo('Locked as shared.'."\n");
sleep(10);
echo('Exclusive lock attempt.'."\n");
flock($fh, LOCK_EX);
echo('Locked exclusively.'."\n");
sleep(10);
flock($fh, LOCK_UN);
echo('Unlocked.'."\n");
sleep(2);
fclose($fh);
echo('Closed.'."\n");
sleep(1);

?>
