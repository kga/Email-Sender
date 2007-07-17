package Email::Sender;

use warnings;
use strict;

use Email::Simple;
use Scalar::Util ();
use Sub::Install;

=head1 NAME

Email::Sender - it sends mail

=head1 VERSION

version 0.001

 $Id$

=cut

our $VERSION = '0.001';

=head1 SYNOPSIS

  package Email::Sender::STDOUT;
  use base qw(Email::Sender);

  sub send {
    my ($self, $email, $arg) = @_;
    print $email->as_string;
    return $self->success;
  }

  ...

  my $sender = Email::Sender::STDOUT->new;
  $sender->send($email, { to => [ $recipient, ... ], from => $from });

=head1 DESCRIPTION

This module provides an extended API for maielrs used by Email::Sender.

=head1 METHODS

=head1 new

=cut

# this should return the class name, croak on args, etc, for singletonian
# mailers..?
sub new {
  my ($class, $arg) = @_;
  $arg ||= {};
  return bless $arg => $class;
}

=head2 send

=cut

sub send {
  my ($self, $email, $arg) = @_;

  Carp::croak "invalid argument to send; first argument must be an email"
    unless my $email = $self->_objectify_email($email);

  $self->setup_envelope($email, $arg);
  $self->validate_send_args($email, $arg);

  # $self->preprocess_email($email);

  return $self->send_email($email, $arg);
}

=head2 setup_envelope

=cut

sub setup_envelope {
  my ($self, $email, $arg) = @_;
  $arg ||= {};

  $arg->{to} = $arg->{to} ? [ $arg->{to} ] : [ ] if not ref $arg->{to};

  $arg->{to} = [ map { $email->get_header($_) } qw(to cc) ]
    if not @{ $arg->{to} };

  # XXX: This needs to get the address out, instead of just whole field.
  $arg->{from} ||= $email->get_header('from');
}

=head2 validate_send_args

=cut

sub validate_send_args {
  return $_[2];
}

=head2 send_email

=cut

for my $method (qw(send_email)) {
  Sub::Install::install_sub({
    code => sub {
      my $class = ref $_[0] ? ref $_[0] : $_[0];
      die "virtual method $method not implemented on $class";
    },
    as => $method
  });
}

sub _objectify_email {
  my ($self, $email) = @_;

  return unless defined $email;

  return $email if ref $email and eval { $email->isa('Email::Abstract') };

  return Email::Abstract->new($email);
}

# send args:
#   email
#   to
#   from

sub success {
  my ($self, $arg) = @_;
  $arg ||= {};

  return bless $arg => 'Email::Sender::Success';
}

sub failure {
  my ($self, $arg) = @_;
  die bless $arg => 'Email::Sender::Failure';
}

{
  package Email::Sender::Success;
  sub failures { $_[0]->{failures} }
}

{
  package Email::Sender::Failure;
}

=head1 AUTHOR

Ricardo SIGNES, C<< <rjbs@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll automatically be
notified of progress on your bug as I make changes.

=head1 COPYRIGHT

Copyright 2006-2007, Ricardo SIGNES.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;