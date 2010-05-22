package Tether::Photo::Rotate;
use MooseX::POE;
use POE qw( Wheel::Run Filter::Line );
use FindBin;

has file => (
    is      => 'rw',
    isa     => 'Str',
);

has parent => (
    is      => 'rw',
    isa     => 'Ref',
);

sub START {
  my ($self,  $kernel,  $session, $heap) = @_[OBJECT,  KERNEL,  SESSION, HEAP];

  $heap->{child} = POE::Wheel::Run->new(
    Program => ["exiftran", "-a", "-i", $self->file],    # Program to run.
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

sub STOP { }

event got_sigchild => sub { 
  my ($self,  $kernel,  $session, $heap) = @_[OBJECT,  KERNEL,  SESSION, HEAP];

  my ($pid, $status) = @_[ARG1, ARG2];
  
  $kernel->post($self->parent, 'ev_rotated', $self->file);
  delete $heap->{child};

  print "pid $pid exited with status $status.\n";
  my $child = delete $_[HEAP]{children_by_pid}{$pid};

  # May have been reaped by on_child_close().
  return unless defined $child;

  delete $_[HEAP]{children_by_wid}{$child->ID};
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
