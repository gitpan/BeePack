package BeePack;
BEGIN {
  $BeePack::AUTHORITY = 'cpan:GETTY';
}
# ABSTRACT: Primitive MsgPack based key value storage
$BeePack::VERSION = '0.001';
use strict;
use warnings;
use Data::MessagePack;
use Data::MessagePack::Stream;
use Carp qw( croak );
use bytes;
use Exporter 'import';

our @EXPORT_OK = qw( beepack bunpack );

sub beepack {
  my ( %data ) = @_;
  my $header_size = _header_size(%data);
  my @keys = sort { $a cmp $b } keys %data;
  my $pack = '';
  my %startbyte;
  for my $key (@keys) {
    $startbyte{$key} = $header_size + length($pack) + 1;
    $pack .= Data::MessagePack->pack($data{$key});
  }
  my $header = _fixmap_header(%data);
  for my $key (@keys) {
    $header .= _fixstr($key);
    $header .= _uint32($startbyte{$key});
  }
  return $header.$pack;
}

sub _header_size {
  my ( %data ) = @_;
  my $value_length = length(_uint32(0));
  my $header = _fixmap_header(%data);
  my @keys = keys %data;
  my $length = length($header);
  for my $key (@keys) {
    $length += length(_fixstr($key));
    $length += $value_length;
  }
  return $length;
}

sub _fixstr {
  my ( $string ) = @_;
  return Data::MessagePack->pack("$string");
}

sub _uint32 {
  my ( $num ) = @_;
  return pack('CN', 0xce, $num);
}

sub _fixmap_header {
  my ( %data ) = @_;
  my $num = keys %data;
  return 
      $num < 16          ? pack( 'C',  0x80 + $num )
    : $num < 2 ** 16 - 1 ? pack( 'Cn', 0xde,  $num )
    : $num < 2 ** 32 - 1 ? pack( 'CN', 0xdf,  $num )
    : croak("Unexpected key count %d", $num);
}

sub bunpack {
  my ( $pack ) = @_;
  open(my $io,'<',\$pack);
  my $header = _find_msgpack($io);
  return map {
    $_, _find_msgpack($io,$header->{$_})
  } keys %{$header};
}

our $BEEPACK_FIND_BLOCKSIZE = 512;

sub _find_msgpack {
  my ( $io, $start ) = @_;
  $start = 1 unless $start;
  my $pos = $start - 1;
  seek($io,$pos,0);
  my $unpacker = Data::MessagePack::Stream->new;
  until ($unpacker->next) {
    croak("No MsgPack found") unless read($io, my $buf, $BEEPACK_FIND_BLOCKSIZE);
    $unpacker->feed($buf);
  }
  my $data = $unpacker->data;
  return $data;
}

1;

__END__

=pod

=head1 NAME

BeePack - Primitive MsgPack based key value storage

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  use BeePack qw( beepack bunpack );

  my $beepack = beepack( key => 'value', other_key => 23 );

  my %hash = bunpack($beepack); # TODO

=head1 DESCRIPTION

More to come... B<ALPHA>

=head1 SUPPORT

IRC

  Join #vonBienenstock on irc.freenode.net. Highlight Getty for fast reaction :).

Repository

  http://github.com/vonBienenstock/p5-beepack
  Pull request and additional contributors are welcome

Issue Tracker

  http://github.com/vonBienenstock/p5-beepack/issues

=head1 AUTHOR

Torsten Raudssus <torsten@raudss.us>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
