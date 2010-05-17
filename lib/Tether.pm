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
use Tether::Gtk2Ui;

sub START {
  my ($self,  $kernel,  $session, $heap) = @_[OBJECT,  KERNEL,  SESSION, HEAP];

  $heap->{ui}      = Tether::Gtk2Ui->new();

  $kernel->sig('shutdown', 'ev_shutdown');
}

event ev_shutdown => sub {
  my ($self, $kernel,  $session,  $heap,  $args) = @_[OBJECT, KERNEL,  SESSION,  HEAP,  ARG1];

  return 1;
  };

sub STOP {}

1;
