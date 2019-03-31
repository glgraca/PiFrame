#!/usr/bin/env perl
use strict;
use warnings;
use WWW::Telegram::BotAPI;
use LWP::UserAgent;
use URI::Escape;
use Try::Tiny;
use open ':std', ':encoding(utf8)';

my $path=$ENV{bot_image_dir};
my $token=$ENV{bot_token};
my $pass=$ENV{bot_pass};

my $api=WWW::Telegram::BotAPI->new (
    token => $token
);

my @after_confirmation=();

sub verify_user {
  my $u=shift;
  my $id=$u->{message}{from}{id};

  my $r=`grep -c $id pizframebot.txt`;
  return int($r);
}

# Bump up the timeout when Mojo::UserAgent is used (LWP::UserAgent uses 180s by default)
$api->agent->can ("inactivity_timeout") and $api->agent->inactivity_timeout (45);

my $me = $api->getMe or die;
my ($offset, $updates) = 0;

# The commands that this bot supports.
my $commands = {
  'help' => 'Use these commands: help (this message); uptime; shutdown; reboot; pass.',
  'uptime' => sub {
    `uptime`;
  },
  'shutdown' => sub {
    my $u=shift;
    my $id=$u->{message}{from}{id};
    push @after_confirmation, sub {`sudo shutdown -h now`};
    return 'Bye, bye.'
  },
  'reboot' => sub {
    my $u=shift;
    my $id=$u->{message}{from}{id};
    push @after_confirmation, sub {`sudo reboot`};
    return 'Ok.';
  },
  'pass' => sub {
    my $u=shift;
    my $id=$u->{message}{from}{id};
    my $userpass=shift;

    if($userpass ne $pass) {
      return 'Wrong password';
    } else {
      if(verify_user($u)) {
        return 'Already registered';
      } else {
        try {
          open(my $passfile, '>>', 'pizframebot.txt');
          print $passfile "$id\n";
          close($passfile);
          return 'Registered';
        } catch {
          return 'System error';
        };
      }
    }
  }
};

printf "%s Starting...\n", $me->{result}{username};

while (1) {
  try {
    $updates = $api->getUpdates ({
      timeout => 30, # Use long polling
      $offset ? (offset => $offset) : ()
    });
  } catch {
    warn $_;
  };
  while(my $sub=pop @after_confirmation) {
    &$sub;
  }
  unless ($updates and ref $updates eq "HASH" and $updates->{ok}) {
    warn "WARNING: getUpdates returned a false value - trying again...";
    next;
  }
  for my $u (@{$updates->{result}}) {
    my $res=undef();
    my $update_id=$u->{update_id};
    $offset = $update_id + 1 if $update_id >= $offset;
    my $auth=verify_user($u);

    if($auth) {
      my $caption=$u->{message}{caption};
      if(my $photos = $u->{message}{photo}) {
        my $photo=$photos->[0];
        for my $p (@$photos) {
          $photo=$p if $p->{file_size}>$photo->{file_size};
        }
        try {
          my $file_desc=$api->getFile({file_id=>$photo->{file_id}});
          my $file_path=$file_desc->{result}->{file_path};
          `curl -s -k -o ${path}/${update_id}.jpg https://api.telegram.org/file/bot$token/$file_path`;
          if($caption) {
            open(my $caption_file, '>', "${path}/${update_id}.txt");
            print $caption_file $caption;
            close($caption_file);
          }
          $res="Image saved as ${path}/${update_id}.jpg";
        } catch {
          $res="Error: $_";
        }
      }
    }
    if (my $text=$u->{message}{text}) { # Text message
      my ($cmd, @params) = split / /, $text;
      $cmd=lc($cmd);
      if(!$auth && $cmd ne 'pass') {
        $res='Send password, '.$u->{message}{from}{id};
      } else {
        $res = $commands->{$cmd} || $commands->{help};
        # Pass to the subroutine the message object, and the parameters passed to the cmd.
        try {
          $res=$res->($u, @params) if ref $res eq "CODE";
        } catch {
          $res="Error: $_";
        }
      }
    }
    next unless $res;
    my $method = ref $res && $res->{method} ? delete $res->{method} : "sendMessage";
    $api->$method ({
       chat_id => $u->{message}{chat}{id},
       ref $res ? %$res : ( text => $res )
    });
  }
}

sub _sendTextMessage {
  $api->sendMessage ({
      chat_id => shift->{message}{chat}{id},
      %{+shift}
  })
}
