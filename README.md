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
1. One large image (with 50% chance of showing image from either directory)
2. One small image (only shows images from main directory
3. One small area with time,day of the week, and date
