#!/usr/bin/perl

use strict ;

BEGIN
{
  push @INC, $ENV{HOME}.'/monitor/lib' ;
}

use Data::Dumper ;
use Time::Piece ;
use xymon ;

my $baseDir = "/var/data/log/" ;
my $flagDir = "/home/mqmon/monitor/flag/mlj/" ;
my $cfgDir = "/home/mqmon/monitor/ini/mlj/" ;

my %lastOnly = ( AMQ7468I => 0 ,
                 AMQ7467I => 0 ,
                 AMQ7490I => 0
               ) ;

################################################################################
#   C O M M A N D   L I N E   A R G U M E N T S   
################################################################################
my @qmgr ;
my $reset = 0 ;

my $opt ;
my $output = 'xymon' ;

while( defined $ARGV[0] )
{
  if( $ARGV[0] =~ s/^-// )
  {
    $opt = $ARGV[0] ;
    shift ;
    if( $opt eq 'reset' )
    {
      $reset = 1 ;
      $output = 'xymon' ;
    }
    next ;
  }

  if( $opt eq 'qmgr' )
  {
    push @qmgr, $ARGV[0] ;
    shift ;
    next  ;
  }

  if( $opt eq 'output' )
  {
    $output = $ARGV[0] ;
    $output eq 'xymon' || $output eq 'stdout' || die ;
    shift ;
    next  ;
  }
}

@qmgr = &getAllQmgr($baseDir) unless scalar @qmgr ;

################################################################################
#
# FUNCTIONS
#
################################################################################

################################################################################
# get all queue manager
################################################################################
sub getAllQmgr 
{
  my $errdir = $_[0];

  my @qmgr ;
  foreach my $qmgr (glob "$errdir/*") 
  {
    next unless -d $qmgr ;
    $qmgr =~ s/^\/.+\/(\w+)/$1/ ;
    push @qmgr, $qmgr ;
  }
  return @qmgr ;
}

################################################################################
# handle one queue manager
################################################################################
sub handleQmgr
{
  my $errdir = $_[0];
  my $qmgr   = $_[1] ;

  my $_qmgr ;

  foreach my $file (glob "$errdir/$qmgr/*.json")
  {
    my $_file = &handleFile( $file );
    unless( ref $_qmgr eq 'HASH' )   
    {
      $_qmgr = $_file ;
      next ;
    } 
    next unless( ref $_file eq 'HASH' ) ;
    $_qmgr = {%$_qmgr, %$_file } ; 
    next ;
  }
  return $_qmgr ;
}

################################################################################
# handle file
################################################################################
sub handleFile
{
  my $file = $_[0] ;

  my $_log ;
  my $age = time() - (stat $file)[9] ;
  if( $age > 1800 )
  {
    $_log->{'9999999999_999999999'}{'ibm_messageId'} = "TIMEOUT" ;
    $_log->{'9999999999_999999999'}{loglevel} = 'ERROR' ;
    $_log->{'9999999999_999999999'}{'ibm_datetime'} = 0 ;
    $_log->{'9999999999_999999999'}{'message'} = "scp not working, check connectivity" ;
    return $_log ;
  }
  open JSON, $file ;


  foreach my $line (<JSON>)
  {
    my $_line ;
    chomp $line ;
    $line =~ s/^\{(.+)\}$/$1/ ;
    foreach my $item (split ",", $line )
    {
      $item =~ /^\"(\w+)\":(.+)/ ;
      my $key = $1;
      my $val = $2 ;
      $val =~ s/\"//g;
      if( $key eq 'ibm_sequence' )
      {
        $_log->{$val} = $_line ;
      }
      $_line->{$key} = $val ;
    }
  }

  close JSON ;

  return $_log ;
}

################################################################################
# ibm to local time
################################################################################
sub ibm2localTime
{
  my $ibmTime = $_[0] ;
 
  my $localTime ; 

  $ibmTime =~ s/
               ^(\d{4})-(\d{2})-(\d{2})T
                (\d{2}):(\d{2}):(\d{2})\.
                (\d{3})Z$
               /$1-$2-$3 $4:$5:$6/x ;

  my $utcTime = Time::Piece->strptime($ibmTime, "%Y-%m-%d %H:%M:%S");
  my $locEpoch = localtime($utcTime->epoch) ;

  ($localTime = $locEpoch->datetime) =~ s/T/ / ;

  return $localTime ;
}

################################################################################
# print to standard output
################################################################################
sub printSTD
{
  my $_log = $_[0] ; 
  my $qmgr = $_[1] ; 

  foreach my $id (sort keys %{$_log})
  {
    print "$id\t" ;
    print $_log->{$id}{loglevel}."\t" ;
    print &ibm2localTime( $_log->{$id}{ibm_datetime} ) ;
    print "\t".$_log->{$id}{message}."\n" ;
  }
}

################################################################################
# print to xymon
################################################################################
sub printXym
{
  my $_log = $_[0] ; 
  my $qmgr = $_[1] ; 
  my $resetId = $_[2] ;
  my $_cfg    = $_[3] ;
  
  my $msg = "reset via: <br>mlj.pl -reset -qmgr <QMGR><br><br>" ;

  my $war = 0  ;
  my $err = 0  ;

  foreach my $id ( reverse sort keys %$_log )
  {
    last if $id eq $resetId ;
    my $color = "&clear" ;
    my $msgId = $_log->{$id}{ibm_messageId} ;

    if( exists $_cfg->{global}{$msgId} )
    {
      $_log->{$id}{loglevel} = $_cfg->{global}{$msgId} ;
    }

    if( exists $_cfg->{$qmgr}         &&
        exists $_cfg->{$qmgr}{$msgId} )
    {
      $_log->{$id}{loglevel} = $_cfg->{$qmgr}{$msgId} ;
    }

    if( $_log->{$id}{loglevel} eq 'INFO' )
    {
      $color = "&green" ;
    }
    if( $_log->{$id}{loglevel} eq 'WARNING' )
    {
      $color = "&yellow" ;
      $war++ ;
    }
    if( $_log->{$id}{loglevel} eq 'ERROR' )
    {
      $color = "&red" ;
      $err++ ;
    }
    $msg .= $color." " ;
    if( $_log->{$id}{ibm_datetime} eq '0' )
    {
      $msg .= "TIME OUT, FILE TO OLD" ; 
    }
    else
    {
      $msg .= &ibm2localTime( $_log->{$id}{ibm_datetime} ) ;
    }
    $msg .= " ".$_log->{$id}{message}."\n" ;
  }
  my $xymColor = 'green' ;
  $xymColor = 'yellow' if $war > 0 ;
  $xymColor = 'red'    if $err > 0 ;
  writeMsg $msg, $xymColor, $qmgr, 'log' ;
}

################################################################################
# reset xymon
################################################################################
sub resetXym
{
  my $dir  = $_[0] ; 
  my $_log = $_[1] ; 
  my $qmgr = $_[2] ; 

# foreach my $id (sort {$b <=> $a} keys %$_log )
  foreach my $id ( reverse sort keys %$_log )
  {
    next if( $_log->{$id}{loglevel} eq 'INFO' ) ;
    open IGN, ">".$dir."/".$qmgr.".reset" ;
    print IGN $_log->{$id}{ibm_sequence} ;
    close IGN ;
    last ;
  }
}

################################################################################
# get reset id
################################################################################
sub getResetId
{
  my $dir  = $_[0] ; 
  my $qmgr = $_[1] ; 

  open IGN, $dir."/".$qmgr.".reset" ;
  my $id = <IGN> ;
  close IGN ;

  return $id ;
}

################################################################################
# get cfg
################################################################################
sub getCfg
{
  my $file = $_[0] ;

  my $_cfg ;

  open INI, $file ;

  foreach my $line (<INI>)
  {
    chomp $line ;
    $line =~ /^\s*(AMQ\d{4}\w)\s+(\w+)\s+/ ;
    my $amq = $1 ;
    my $lev = $2 ;
    $_cfg->{$amq} = $lev ;
  }

  close INI ;

  return $_cfg ;
}

################################################################################
# merge 
################################################################################
sub lastOnly
{
  my $_data = $_[0] ;
  my $_lastOnly = $_[1] ;

  my @keys = reverse sort keys %{$_data} ;

  foreach my $id ( @keys )
  {
    my $msgId = $_data->{$id}{ibm_messageId} ;
    next unless exists $_lastOnly->{$msgId} ;
    if( $_lastOnly->{$msgId} == 0 )
    {
      $_lastOnly->{$msgId}++ ;
    }
    else
    {
      delete $_data->{$id} ;
    }
  }
}

################################################################################
#
#   M A I N  
#
################################################################################

my $_cfg->{global} = getCfg $cfgDir.'/amq.global.ini' ;

foreach my $qmgr (@qmgr)
{
  if( -f $cfgDir.'/amq.'.$qmgr.'.ini' )
  {
    $_cfg->{$qmgr} = getCfg $cfgDir.'/amq.'.$qmgr.'.ini' ;
  }

  my $_log->{$qmgr} = handleQmgr( $baseDir, $qmgr );
  if( $reset == 1 )
  {
    resetXym $flagDir, $_log->{$qmgr}, $qmgr ;
  }

  printSTD( $_log->{$qmgr}, $qmgr ) if $output eq 'stdout' ;
  if( $output eq 'xymon' )
  {
    my $resetId = getResetId $flagDir, $qmgr ;
    lastOnly $_log->{$qmgr}, \%lastOnly ;
    printXym( $_log->{$qmgr}, $qmgr, $resetId, $_cfg ) ;
  }
}


