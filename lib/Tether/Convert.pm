package Tether::Convert;
use MooseX::POE;
use POE qw( Wheel::Run Filter::Line );
use Tether::Convert::Child;

sub START {
  my ($self,  $kernel,  $session, $heap) = @_[OBJECT,  KERNEL,  SESSION, HEAP];

}

event ev_rotatedphoto => sub {
  my ($self,  $kernel,  $session, $heap, $file) = @_[OBJECT,  KERNEL,  SESSION, HEAP, ARG0];

  warn "Got photo ready for scaling: $file";

  Tether::Convert::Child->new(
    file       => $file, 
    dimensions => "x600", 
    type       => 'screen', 
  );

  Tether::Convert::Child->new(
    file       => $file, 
    dimensions => "480x", 
    type       => 'phone', 
  );
};

sub STOP { }

1;
