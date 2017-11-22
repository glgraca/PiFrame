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

my @tmp=();
my $root=$ARGV[0].'/';
my $telegram_root=$ARGV[1].'/';
my $main = MainWindow->new (
  -title => 'PiFrame',
  -background => 'black'
);

my $w=$main->screenwidth();
my $h=$main->screenheight();
my $ratio=$w/$h;
my $photos=1;

if($ratio>1.5) {
  $photos=2;
}

$main->overrideredirect(1);
$main->MoveToplevelWindow(0,0);
$main->geometry(join('x',$w,$h));
$main->hideCursor();

my $photo_width=int($w/2);
my $photo_height=int($h*0.8);

my @photo=();
my @canvas=();

for my $i (1..$photos) {
  my $canvas=$main->Canvas(
    -width=>$photo_width,
    -height=>$photo_height,
    -background=>'black',
    -bd=>2,
    -highlightthickness => 0);

  my $photo=$canvas->Photo();
  $canvas->createImage(0,0,-image=>$photo,-anchor=>'nw');

  push(@canvas, $canvas);
  push(@photo, $photo);
  push(@tmp, sprintf('/home/pi/tmp/tmp%1d.jpg', $i));
}

my $time;
my $caption;

my $clock=$main->Label(
  -textvariable=>\$time,
  -wraplength=>$w,
  -width=>80,
  -height=>2,
  -background=>'black',
  -foreground=>'white',
  -highlightthickness => 0,
  -font=>'courier 24 bold');
$clock->pack();

for my $canvas (@canvas) {
  $canvas->pack(-side=>'left');
}

sub scale {
  my ($index, $width, $height, $image)=@_;
  my $scaled=$image->scale(xpixels=>$width,ypixels=>$height,type=>'min');
  $scaled->write(file=>$tmp[$index], type=>'jpeg');
}

sub next_photo {
  my $index=shift;
  my $photo=shift;
  $caption='';
  my $filename;
  if(int(rand(2))==1) {
    $filename=$telegram_root.random_file(-dir=>$telegram_root, -check=>qr/\.jpg$/i, -recursive=>1, -follow=>1);
  } else {
    $filename=$root.random_file(-dir=>$root, -check=>qr/\.jpg$/i, -recursive=>1);
  }
  my ($name, $path, $suffix) = fileparse($filename, '\.[^\.]*');
  my $caption_file="${path}${name}.txt";
  if(-e $caption_file) {
    $caption=read_file($caption_file,binmode=>':utf8');
  }

  my $image=Imager::ExifOrientation->rotate(path => $filename);
  scale($index, $photo_width, $photo_height, $image);
  $photo->configure(-file=>$tmp[$index]);

  $main->update();
}

my @intervals=(3,5);
for my $i (0..$#canvas) {
  next_photo($i, $photo[$i]);
  $canvas[$i]->repeat($intervals[$i]*60*1000, sub {eval {next_photo($i, $photo[$i])}});
}
$clock->repeat(3000, sub {$time=strftime("%H:%M %A %d/%m", localtime)."\n$caption"});

MainLoop;
