package Tether::Photo::Capture;
use MooseX::POE;
use POE qw( Wheel::Run Filter::Line );
use DateTime;

has parent => (
    is      => 'rw',
    isa     => 'Ref',
);

has capDir => (
    is      => 'rw',
    isa     => 'Str',
);

sub STOP {}

sub START {
  my ($self,  $kernel,  $session, $heap, $args) = @_[OBJECT,  KERNEL,  SESSION, HEAP, ARG0];

  chdir $self->capDir;

  $heap->{child} = POE::Wheel::Run->new(
    Program => [ "gphoto2", "--capture-image-and-download" ],
    StdioFilter  => POE::Filter::Line->new(),    # Child speaks in lines.
    StderrFilter => POE::Filter::Line->new(),    # Child speaks in lines.
    StdoutEvent  => "got_child_stdout",          # Child wrote to STDOUT.
    StderrEvent  => "got_child_stderr",          # Child wrote to STDERR.
    CloseEvent   => "got_child_close",           # Child stopped writing.
  );

  $kernel->sig_child($heap->{child}->PID, "got_sigchild");

  # Wheel events include the wheel's ID.
  $heap->{children_by_wid}{$heap->{child}->ID} = $heap->{child};

  # Signal events include the process ID.
  $heap->{children_by_pid}{$heap->{child}->PID} = $heap->{child};

  print(
    "Child pid ", $heap->{child}->PID,
    " started as wheel ", $heap->{child}->ID, ".\n"
  );

}

event got_sigchild => sub {
    my ($self,  $kernel,  $session, $heap, $args) = @_[OBJECT,  KERNEL,  SESSION, HEAP, ARG0];
    print "pid $_[ARG1] exited with status $_[ARG2].\n";

    delete $_[HEAP]{children_by_pid}{$heap->{child}->PID};
    delete $heap->{child};

    my $dt = DateTime->now;
    my $filename = $self->capDir . $dt->ymd('-') . "_" . $dt->hms('-') . '.jpg';
    rename $self->capDir . 'capt0000.jpg', $filename;
    # May have been reaped by on_child_close().

    $kernel->post($self->parent, 'ev_captured', $filename);

    delete $_[HEAP]{children_by_pid};

    delete $_[HEAP]{children_by_wid};
  };

event got_child_stdout => sub {
    my ($stdout_line, $wheel_id) = @_[ARG0, ARG1];
    my $child = $_[HEAP]{children_by_wid}{$wheel_id};
    print "pid ", $child->PID, " STDOUT: $stdout_line\n";
  };

event got_child_stderr => sub { 
    my ($stderr_line, $wheel_id) = @_[ARG0, ARG1];
    my $child = $_[HEAP]{children_by_wid}{$wheel_id};
    print "pid ", $child->PID, " STDERR: $stderr_line\n";
  
  };

event got_child_close => sub {  
    my $wheel_id = $_[ARG0];
    my $child = delete $_[HEAP]{children_by_wid}{$wheel_id};

    # May have been reaped by on_child_signal().
    unless (defined $child) {
      print "wid $wheel_id closed all pipes.\n";
      return;
    }

    print "pid ", $child->PID, " closed all pipes.\n";
    delete $_[HEAP]{children_by_pid}{$child->PID};
  };

1;
