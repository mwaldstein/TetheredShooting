#
#===============================================================================
#
#         FILE:  Web.pm
#
#  DESCRIPTION:  
#
#        FILES:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  YOUR NAME (), 
#      COMPANY:  
#      VERSION:  1.0
#      CREATED:  05/21/2010 08:09:12 PM
#     REVISION:  ---
#===============================================================================

use strict;
use warnings;

package Tether::Ui::Web;
use MooseX::POE;
use POE qw(Component::Server::SimpleHTTP Component::Server::SimpleContent);

with qw(MooseX::POE::Aliased);

has parent => (
    is      => 'rw',
    isa     => 'Ref',
);

has root => (
    is      => 'rw',
    isa     => 'Str',
);

has images => (
    is      => 'rw',
    isa     => 'Str',
);

has latest => (
    is      => 'rw',
    isa     => 'Str',
    default => 'tether.jpg', 
);

sub START {
  my ($self,  $kernel,  $session, $heap) = @_[OBJECT,  KERNEL,  SESSION, HEAP];

  # A simple web server 

  $heap->{web} = POE::Component::Server::SimpleContent->spawn( root_dir => $self->root );
  $heap->{images} = POE::Component::Server::SimpleContent->spawn( 
    root_dir => $self->images, 
    alias_path => '/images/', 
    );

  $heap->{server} = POE::Component::Server::SimpleHTTP->new(
        ALIAS => 'httpd',
        PORT => 8080,
        'LOGHANDLER' => { 'SESSION' => $session->ID,
                          'EVENT'   => 'GOT_LOG',
                },
        HANDLERS => [
                {
                  DIR => '^/data/latest$',
                  EVENT => 'ev_latest',
                  SESSION => $session->ID,
                },
                {
                  DIR => '^/data/action$',
                  EVENT => 'ev_uiaction',
                  SESSION => $session->ID,
                },
                {
                  DIR => '^/images/phone',
                  EVENT => 'request',
                  SESSION => $heap->{images}->session_id(),
                },
                {
                  DIR => '.*',
                  EVENT => 'request',
                  SESSION => $heap->{web}->session_id(),
                },
        ],
  );

}

sub STOP {}

event ev_uiaction => sub {
  my ($self,  $kernel,  $session, $heap) = @_[OBJECT,  KERNEL,  SESSION, HEAP];
  # ARG0 = HTTP::Request object, ARG1 = HTTP::Response object, ARG2 = the DIR that matched
  my( $request, $response, $dirmatch ) = @_[ ARG0 .. ARG2 ];

  $kernel->post($self->parent, 'ev_uiaction');

  # Do our stuff to HTTP::Response
  $response->code( 200 );
  $response->content( '{ message: "OK" }' );

  # We are done!
  # For speed, you could use $_[KERNEL]->call( ... )
  $kernel->post( 'httpd', 'DONE', $response );
  };

event ev_updatephoto => sub {
  my ($self, $kernel,  $session,  $heap,  $args) = @_[OBJECT, KERNEL,  SESSION,  HEAP,  ARG0];

  $self->latest($args);
};

event ev_latest => sub {
  my ($self,  $kernel,  $session, $heap) = @_[OBJECT,  KERNEL,  SESSION, HEAP];

  # ARG0 = HTTP::Request object, ARG1 = HTTP::Response object, ARG2 = the DIR that matched
  my( $request, $response, $dirmatch ) = @_[ ARG0 .. ARG2 ];

  # Do our stuff to HTTP::Response
  $response->code( 200 );
  $response->content( '{ image: "' . $self->latest . '" }' );

  # We are done!
  # For speed, you could use $_[KERNEL]->call( ... )
  $kernel->post( 'httpd', 'DONE', $response );
  };

event ev_shutdown => sub {
  my ($self,  $kernel,  $session, $heap) = @_[OBJECT,  KERNEL,  SESSION, HEAP];

  $kernel->post($heap->{server}, "SHUTDOWN");
  $$heap->{web}->shutdown();
  $$heap->{images}->shutdown();
  return 1;
};

1;
