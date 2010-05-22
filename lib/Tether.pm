#
#===============================================================================
#
#         FILE:  Tether.pm
#
#  DESCRIPTION:  
#
#        FILES:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  YOUR NAME (), 
#      COMPANY:  
#      VERSION:  1.0
#      CREATED:  05/16/2010 04:55:29 PM
#     REVISION:  ---
#===============================================================================

use strict;
use warnings;

package Tether;
use MooseX::POE;
use Tether::Ui::Gtk;
use Tether::Ui::Web;
use Tether::Photo::Rotate;
use Tether::Photo::Convert;
use Tether::Photo::Capture;

use FindBin;

sub START {
  my ($self,  $kernel,  $session, $heap) = @_[OBJECT,  KERNEL,  SESSION, HEAP];

  warn "Master session id - " . $session->ID;
  Tether::Ui::Gtk->new(parent => $session, alias => 'gtkui');
  Tether::Ui::Web->new(
    parent => $session, 
    root => $FindBin::Bin . "/www/",
    images => $FindBin::Bin . "/images/", 
    alias => 'webui', 
    );
}

event ev_uiaction => sub {
  my ($self,  $kernel,  $session, $heap) = @_[OBJECT,  KERNEL,  SESSION, HEAP];

  warn "Got Ui action";

  Tether::Photo::Capture->new(
    parent => $session, 
    capDir => $FindBin::Bin . '/images/full/',
  );
};

event ev_captured => sub {
  my ($self,  $kernel,  $session, $heap, $file) = @_[OBJECT,  KERNEL,  SESSION, HEAP, ARG0];

  Tether::Photo::Rotate->new(
    parent => $session, 
    file => $file, 
  );

  };

event ev_rotated => sub {
  my ($self,  $kernel,  $session, $heap, $file) = @_[OBJECT,  KERNEL,  SESSION, HEAP, ARG0];

  my $baseFile = $file;
  $baseFile =~ s/.*\///;

  Tether::Photo::Convert->new(
    parent => $session, 
    inFile => $file, 
    outFile => $FindBin::Bin . "/images/phone/$baseFile", 
    dimensions => '480x', 
    type => 'phone', 
  );

  Tether::Photo::Convert->new(
    parent => $session, 
    inFile => $file, 
    outFile => $FindBin::Bin . "/images/screen/$baseFile", 
    dimensions => 'x600', 
    type => 'screen', 
  );

};

event ev_converted => sub {
  my ($self,  $kernel,  $session, $heap, $file, $type) = @_[OBJECT,  KERNEL,  SESSION, HEAP, ARG0, ARG1];

  warn "Got converted of $type";

  if ($type eq 'screen') {
    $kernel->post('gtkui', 'ev_updatephoto', $file);
  }
  if ($type eq 'phone') {
    $file =~ s/$FindBin::Bin//;
    $kernel->post('webui', 'ev_updatephoto', $file);
  }
};

event ev_shutdown => sub {
  my ($self,  $kernel,  $session, $heap, $file, $type) = @_[OBJECT,  KERNEL,  SESSION, HEAP, ARG0, ARG1];

  $kernel->post('gtkui', 'ev_shutdown');
  $kernel->post('webui', 'ev_shutdown');
};

sub STOP {}

1;
