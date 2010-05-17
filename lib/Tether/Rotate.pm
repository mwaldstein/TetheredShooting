#
#===============================================================================
#
#         FILE:  Rotate.pm
#
#  DESCRIPTION:  
#
#        FILES:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  YOUR NAME (), 
#      COMPANY:  
#      VERSION:  1.0
#      CREATED:  05/16/2010 06:48:25 PM
#     REVISION:  ---
#===============================================================================

use strict;
use warnings;

package Tether::Rotate;
use MooseX::POE;
use Tether::Rotate::Child;

sub START {
     $_[KERNEL]->sig("phototaken", "ev_phototaken" );  
}

sub STOP {}

event ev_phototaken => sub {
  my ($self,  $kernel,  $session, $heap, $file) = @_[OBJECT,  KERNEL,  SESSION, HEAP, ARG0];
   
  warn "Going to rotate $file";

  Tether::Rotate::Child->new(
    file => $file, 
  );

};

1;
