<?php
require 'env/appvars.php';
require 'env/dbvars.php';
require 'sessionstart.php';

$form['redir'] = isset($_GET['redir']) ? $_GET['redir'] : 'home.php';

$query = "SELECT userid FROM users
          WHERE username = 'piper'";
$sth = $dbh->query($query);
if ( $userid = $sth->fetchColumn() )
{
   $_SESSION['userid'] = $userid;
   $liuser = new App_User($_SESSION['userid']);

   header('Location: '.$form['redir']);
   exit;
}