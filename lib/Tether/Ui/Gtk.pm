package Tether::Ui::Gtk;
use MooseX::POE;

use Gtk2-init;
use Gtk2::Gdk::Keysyms;

with qw(MooseX::POE::Aliased);

has parent => (
    is      => 'rw',
    isa     => 'Ref',
);

sub START {
  my ($self,  $kernel,  $session, $heap) = @_[OBJECT,  KERNEL,  SESSION, HEAP];

  $heap->{main_window} = Gtk2::Window->new("toplevel");
  $kernel->signal_ui_destroy($heap->{main_window});

  $heap->{image} = Gtk2::Image->new();
  $heap->{main_window}->add($heap->{image});

  # key-press-event expects the return value of the signal handler
  # to be a boolean where TRUE means we've handled the keypress,  so
  # Gtk can stop asking other handlers to handle it and FALSE means
  # we didn't handle it; continue trying to handle this key. So we
  # need to use a callback instead of a postback here,  since post
  # doesn't let us return a value.
  #          $entry->signal_connect("key-press-event",  $session->callback('keypress'));
  $heap->{main_window}->signal_connect("key-press-event", $session->callback("ev_keypress"));

  $heap->{main_window}->modify_bg('normal',   Gtk2::Gdk::Color->parse('black'));
  $heap->{main_window}->fullscreen;
  $heap->{main_window}->show_all();

}

event ev_keypress => sub {
  my ($self, $kernel,  $session,  $heap,  $args) = @_[OBJECT, KERNEL,  SESSION,  HEAP,  ARG1];
  my (undef,  $event) = @$args;

  if ($event->keyval == $Gtk2::Gdk::Keysyms{Escape}) {
#    $kernel->yield("ev_shutdown");
    $kernel->post($self->parent, "ev_shutdown");
    return 1;
  }

#  POE::Kernel->yield("ev_takeaction");
#  POE::Kernel->yield("ev_screenphoto", 'images/screen/screen0018.jpg');
#  $kernel->post($self->parent, 'ev_captured', $self->file);
  $kernel->post($self->parent, 'ev_uiaction');
  return 1;
};

# takes the path to the screen-res photo in arg0
# Updates the display with the new image
event ev_updatephoto => sub {
  my ($self, $kernel,  $session,  $heap,  $args) = @_[OBJECT, KERNEL,  SESSION,  HEAP,  ARG0];

  $heap->{image}->set_from_file($args);
};

event ev_test => sub {
  my ($self, $kernel,  $session,  $heap,  $args) = @_[OBJECT, KERNEL,  SESSION,  HEAP,  ARG0];

  warn "Message received: \'$args\'";
};

event ev_shutdown => sub {
  my ($self, $kernel,  $session,  $heap,  $args) = @_[OBJECT, KERNEL,  SESSION,  HEAP,  ARG1];

  $heap->{main_window}->destroy();
  $kernel->alias_remove($heap->{alias});
  return 1;
  };

sub STOP {
  }

1;
