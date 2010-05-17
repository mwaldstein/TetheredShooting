package Tether::Capture;
use MooseX::POE;
use POE qw( Wheel::Run Filter::Line );
use FindBin;

sub START {}

sub STOP {}

event ev_takeaction => sub {
  my ($self,  $kernel,  $session, $heap, $args) = @_[OBJECT,  KERNEL,  SESSION, HEAP, ARG0];

  chdir "$FindBin/images/full";

  my $child = POE::Wheel::Run->new(
    Program => [ "gphoto2", "--folder /store_00010001/", "-1", "/" ],
    StdioFilter  => POE::Filter::Line->new(),    # Child speaks in lines.
    StderrFilter => POE::Filter::Line->new(),    # Child speaks in lines.
    StdoutEvent  => "got_child_stdout",
    StderrEvent  => "got_child_stderr",
    CloseEvent   => "got_child_close",
  );

  $kernel->sig_child($child->PID, "got_child_signal");

  # Wheel events include the wheel's ID.
  $heap->{children_by_wid}{$child->ID} = $child;

  # Signal events include the process ID.
  $heap->{children_by_pid}{$child->PID} = $child;

};

  # Wheel event, including the wheel's ID.
  sub on_child_stdout {
    my ($stdout_line, $wheel_id) = @_[ARG0, ARG1];
    my $child = $_[HEAP]{children_by_wid}{$wheel_id};
    print "pid ", $child->PID, " STDOUT: $stdout_line\n";
  }

  # Wheel event, including the wheel's ID.
  sub on_child_stderr {
    my ($stderr_line, $wheel_id) = @_[ARG0, ARG1];
    my $child = $_[HEAP]{children_by_wid}{$wheel_id};
    print "pid ", $child->PID, " STDERR: $stderr_line\n";
  }

  # Wheel event, including the wheel's ID.
  sub on_child_close {
    my $wheel_id = $_[ARG0];
    my $child = delete $_[HEAP]{children_by_wid}{$wheel_id};

    # May have been reaped by on_child_signal().
    unless (defined $child) {
      print "wid $wheel_id closed all pipes.\n";
      return;
    }

    print "pid ", $child->PID, " closed all pipes.\n";
    delete $_[HEAP]{children_by_pid}{$child->PID};
  }

  sub on_child_signal {
    print "pid $_[ARG1] exited with status $_[ARG2].\n";
    my $child = delete $_[HEAP]{children_by_pid}{$_[ARG1]};

    # May have been reaped by on_child_close().
    return unless defined $child;

    delete $_[HEAP]{children_by_wid}{$child->ID};
  }

1;
