#!/usr/bin/env perl
use strict;
use warnings;
use threads;
use threads::shared;
use HTTP::Daemon;
use HTTP::Request;
use HTTP::Status;
use WWW::Telegram::BotAPI;
use LWP::UserAgent;
use Data::Dumper;
use URI::Escape;
use Try::Tiny;

#This is where images will be stored
my $path=$ARGV[0];

#Users who may use this bot
my $user_id={'Derpina'=>123,'Me'=>321};

my $token='<insert token here>';

my $api=WWW::Telegram::BotAPI->new (
    token => $token
);

#Verify is user has permission to use this bot
sub verify_user {
  my $u=shift;
  my $id=$u->{message}{from}{id};

  for my $user (keys %$user_id) {
    return 1 if $id==$user_id->{$user};
  }
  return 0;
}

# Bump up the timeout when Mojo::UserAgent is used (LWP::UserAgent uses 180s by default)
$api->agent->can ("inactivity_timeout") and $api->agent->inactivity_timeout (45);

my $me = $api->getMe or die;
my ($offset, $updates) = 0;

# The commands that this bot supports.
my $commands = {};

printf "%s starting...\n", $me->{result}{username};

while (1) {
  eval {
    $updates = $api->getUpdates ({
      timeout => 30, # Use long polling
      $offset ? (offset => $offset) : ()
    });
  };
  warn $@ if $@;
  unless ($updates and ref $updates eq "HASH" and $updates->{ok}) {
    warn "WARNING: getUpdates returned a false value - trying again...";
    next;
  }
  for my $u (@{$updates->{result}}) {
    my $res=undef();
    my $update_id=$u->{update_id};
    $offset = $update_id + 1 if $update_id >= $offset;
    #print Dumper($u);
    if(!verify_user($u)) {
      #If you are not allowed, you get your id back, so you may ask for permission
      $api->sendMessage({chat_id=>$u->{message}{from}{id}, text=>'Hello, '.$u->{message}{from}{id}});
    }
    if(my $photos = $u->{message}{photo}) {
      my $photo=$photos->[0];
      for my $p (@$photos) {
        $photo=$p if $p->{file_size}>$photo->{file_size};
      }
      eval {
        my $file_desc=$api->getFile({file_id=>$photo->{file_id}});
        my $file_path=$file_desc->{result}->{file_path};
        `curl -s -k -o ${path}/${update_id}.jpg https://api.telegram.org/file/bot$token/$file_path`;
        $res="Image was saved as ${path}/${update_id}.jpg";
      };
      $res="Error: $@" if $@;
    }
    if (my $text = $u->{message}{text}) { # Text message
      next if $text !~ m!^/!; # Not a command
      my ($cmd, @params) = split / /, $text;
      $res = $commands->{substr ($cmd, 1)} || $commands->{_unknown};
      # Pass to the subroutine the message object, and the parameters passed to the cmd.
      try {
        $res=$res->($u->{message}, @params) if ref $res eq "CODE";
      } catch {
        $res="Failed: $_";
      };
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
