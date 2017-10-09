# PiFrame

This is perl code for a digital picture frame based on a Raspberry Pi Zero W running Raspbian.

It includes a Telegram Bot so that you can send pictures from your phone straight to the picture frame. If you include a caption, it will be shown along with the image.

You need to install a few packages:

```sh
sudo apt-get install perl-tk
sudo apt-get install libjpeg-devel
sudo cpanm Imager
sudo cpanm Imager::File::JPEG
sudo apt-get install libnet-ssleay-perl libio-socket-ssl-perl --fix-missing
sudo cpanm WWW::Telegram::BotAPI
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

The frame has three areas:
1. One large image (with a 50% chance of showing an image from either directory);
2. One small image (only shows images from main directory);
3. One small area with time, day of the week, and date.

You must also add a line to /etc/fstab

```sh
tmpfs  	/home/pi/tmp  	tmpfs  	nodev,nosuid,size=1M 0 0
```

This will setup a 1MB RAM disk where the images will be resized before being displayed. This will avoid wearing down your SD card. You must also create the mount point for this RAM disk:

```sh
mkdir /home/pi/tmp
```

The commands serviced by the bot are:
1. help (prints a list of commands);
2. uptime (prints uptime for the system);
3. reboot (reboots the system after confirmation);
4. shutdown (shuts down the system after confirmation);
5. pass (sends the password so that the user may gain access).

The user ids for those users that have sent the correct password are stored in a text file.
