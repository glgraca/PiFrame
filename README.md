# PiFrame

This is perl code for a digital picture frame based on a Raspberry Pi Zero W running Raspbian.

It includes a Telegram Bot so that you can send pictures from your phone straight to the picture frame. If you include a caption, it will be shown along with the image.

You need to install a few packages:

```sh
sudo apt-get install curl
sudo curl -L http://cpanmin.us | perl - --sudo App::cpanminus
sudo apt-get install libwww-perl
sudo apt-get install perl-tk
sudo cpanm Tk::HideCursor
sudo apt-get install libjpeg-dev
sudo cpanm Imager
sudo cpanm Imager::File::JPEG
sudo cpanm Imager::ExifOrientation
sudo apt-get install libnet-ssleay-perl libio-socket-ssl-perl --fix-missing
sudo cpanm WWW::Telegram::BotAPI
sudo cpanm File::Random
sudo cpanm File::Slurp
```

The services file has a few variables that you must edit:
1. bot_image_dir (where to store the images sent through Telegram);
2. bot_token (the Telegram authentication token);
3. bot_pass (the password users must use to gain access).

Then, you have to copy the service file to /etc/systemd/system and issue a couple of commands:

```sh
sudo systemctl enable piframebot
sudo systemctl start piframebot
```
In order to start the script automatically, you must add a line to   /home/pi/.config/lxsession/LXDE-pi/autostart:

```sh
@perl /home/pi/piframe.pl <main-image-dir> <telegram-image-dir>
```

The value of telegram-image-dir should be the same value used in the bot_image_dir environment variable set in the service file.

The frame has two areas:
1. A calendar occupies the top 20% of the screen;
2. The bottom 80% shows one image if the screen ratio is less than 1.5 and two otherwise.

You must also add a line to /etc/fstab

```sh
tmpfs  	/home/pi/tmp  	tmpfs  	nodev,nosuid,size=1M 0 0
```

This will setup a 1MB RAM disk where the images will be resized before being displayed. This will avoid wearing down your SD card. You must also create the mount point for this RAM disk:

```sh
mkdir /home/pi/tmp
```

You should also disable the screen saver:

```sh
Change two settings if you have /etc/kbd/config
BLANK_TIME=0
POWERDOWN_TIME=0

or execute this (as root) if you have /etc/default/keyboard
TERM=linux setterm -blank 0 >> /etc/issue

Add these lines to /etc/xdg/lxsession/LXDE-pi/autostart or /home/pi/.config/lxsession/LXDE-pi/autostart
@xset s noblank 
@xset s off 
@xset -dpms
```
It's a good ideia to disable logging, as it will fill your SD card eventually:

```sh
sudo systemctl stop rsyslog
sudo systemctl disable rsyslog
```

Also, disable swap:

```sh
sudo dphys-swapfile swapoff
sudo dphys-swapfile uninstall
sudo update-rc.d dphys-swapfile remove
```

The commands serviced by the bot are:
1. help (prints a list of commands);
2. uptime (prints uptime for the system);
3. reboot (reboots the system);
4. shutdown (shuts down the system);
5. pass (sends the password so that the user may gain access).

The user ids for those users that have sent the correct password are stored in a text file.

## Bonus for extra stability

Edit your /etc/crontab and add these two lines:

```sh
*/20 * * * * root /home/pi/wifi.sh
0 2 * * 1 root /sbin/reboot
```

The first one will verify the Wifi connection every 20 minutes (I found that Wifi would stop working if the Pi stayed on for more than a few weeks).

The second line will reboot the Pi every monday at 2am. Again, I found that leaving it on for many weeks would result in some failure (maybe a memory leak).

With these two precautions, it will work without a glitch for months, maybe years.
