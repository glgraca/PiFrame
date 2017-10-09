#!/usr/bin/perl
use Tk;
use Tk::JPEG;
use Tk::Photo;
use Tk::HideCursor;
use Imager;
use Imager::ExifOrientation;
use File::Find;
use File::Random qw/:all/;
use POSIX 'strftime';
use Data::Dumper;
use File::Basename;
use File::Slurp;
use strict;
use utf8;
use open ':std', ':encoding(utf8)';

my @file_list;
my $tmp='/home/pi/tmp/tmp.jpg';
my $root=$ARGV[0].'/';
my $telegram_root='/data01/tmp/';

my $main = MainWindow->new (
  -title => 'PiFrame',
  -background => 'black'
);

my $w=$main->screenwidth();
my $h=$main->screenheight();
$main->overrideredirect(1);
$main->MoveToplevelWindow(0,0);
$main->geometry(join('x',$w,$h));
$main->hideCursor();

my $photo_width=int($w*3/4);
my $photo_height=$h;
my $thumb_width=$w-$photo_width;
my $thumb_height=int($h/3);

my $canvas=$main->Canvas(
  -width=>$photo_width,
  -height=>$h,
  -background=>'black',
  -highlightthickness => 0);
$canvas->pack(-side=>'left');

my $small_canvas=$main->Canvas(
  -width=>$thumb_width,
  -height=>$thumb_height,
  -background=>'black',
  -highlightthickness => 0);
$small_canvas->pack(-side=>'bottom');

my $time;
my $caption;

my $clock=$main->Label(
  -textvariable=>\$time,
  -wraplength=>$thumb_width,
  -width=>100,
  -height=>100,
  -background=>'black',
  -foreground=>'white',
  -highlightthickness => 0,
  -font=>'courier 40 bold');
$clock->pack(-side=>'top');

my $photo=$canvas->Photo();
$canvas->createImage(0,0,-image=>$photo,-anchor=>'nw');
my $thumb=$small_canvas->Photo();
$small_canvas->createImage(0,0,-image=>$thumb,-anchor=>'nw');

sub scale {
  my ($width, $height, $image)=@_;
  my $scaled=$image->scale(xpixels=>$width,ypixels=>$height,type=>'min');
  $scaled->write(file=>$tmp, type=>'jpeg');
}

sub next_photo {
  $caption='';
  my $filename;
  if(int(rand(2))==1) {
    $filename=$telegram_root.random_file(-dir=>$telegram_root, -check=>qr/\.jpg$/i, -recursive=>1);
    my ($name, $path, $suffix) = fileparse($filename, '\.[^\.]*');
    my $caption_file="${path}${name}.txt";
    if(-e $caption_file) {
      $caption=read_file($caption_file,binmode=>':utf8');
    }
  } else {
    $filename=$root.random_file(-dir=>$root, -check=>qr/\.jpg$/i, -recursive=>1);
  }
  my $image = Imager::ExifOrientation->rotate(path => $filename);
  scale($photo_width, $photo_height, $image);
  $photo->configure(-file=>$tmp);

  $filename=$root.random_file(-dir=>$root, -check=>qr/\.jpg$/i, -recursive=>1);

  $image = Imager::ExifOrientation->rotate(path => $filename);
  scale($thumb_width, $thumb_height, $image);
  $thumb->configure(-file=>$tmp);

  $main->update();
}

$canvas->repeat(120000, sub {eval {next_photo()}});
$canvas->repeat(3000, sub {$time=strftime("%H:%M\n%A\n%d/%m", localtime)."\n\n$caption"});

next_photo();

MainLoop;
