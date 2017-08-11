# PiFrame

This is perl code for a digital picture frame based on a Raspberry Pi Zero W.

It includes a Telegram Bot so that you can send pictures from your phone straight to the picture frame.

You need to install a few packages:

```sh
sudo apt-get install perl-tk
sudo apt-get install libjpeg-devel
sudo cpanm Imager
sudo cpanm Imager::File::JPEG
sudo apt-get install libnet-ssleay-perl libio-socket-ssl-perl --fix-missing
sudo cpanm WWW::Telegram::BotAPI
```

Then, you have to copy the service file to /etc/systemd/system and issue a couple of commands:

```sh
sudo systemctl enable piframebot
sudo systemctl start piframebot
```
In order to start the script automatically, you must add a line to   /home/pi/.config/lxsession/LXDE-pi/autostart:

```sh
@perl /home/pi/piframe.pl <main-image-dir> <telegram-image-dir>
```

The frame has three areas:
1. One large image (with a 50% chance of showing an image from either directory)
2. One small image (only shows images from main directory
3. One small area with time,day of the week, and date

You must also add a line to /etc/fstab

```sh
tmpfs  	/home/pi/tmp  	tmpfs  	nodev,nosuid,size=1M 0 0
```

This will setup a 1MB RAM disk where the images will be resized before being displayed. This will avoid wearing down your SD card. You must also create the mount point for this RAM disk:

```sh
mkdir /home/pi/tmp
```
