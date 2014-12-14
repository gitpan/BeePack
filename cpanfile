
requires 'Data::MessagePack', '0';
requires 'Data::MessagePack::Stream', '0';
requires 'Path::Tiny', '0';
requires 'Data::Coloured', '0';

on test => sub {
  requires 'Test::More', '0.96';
};
