##############################################################################
#
#  42_Proscenic.pm
#
#  2017 Oskar Neumann
#  oskar.neumann@me.com
#
##############################################################################

# sudo apt-get install libxml-simple-perl

package main;

use strict;
use warnings;

use XML::Simple qw(:strict);

use constant {
    MODE_AUTO => 'AA55A55A09FDE20906000100020500000000',
    MODE_AREA => 'AA55A55A0AFDE20906000100020400000000',
    MODE_EDGE => 'AA55A55A0BFDE20906000100020300000000',
    MODE_ZIGZAG => 'AA55A55A0CFDE20906000100020200000000',

    STOP => 'AA55A55A0DFDE20906000100030000000000',
    RUN => 'AA55A55A0DFDE20906000100020000000100',
    DOCK => 'AA55A55A0FFDE20906000100010000000000'
};


sub Proscenic_Initialize($) {
    my ($hash) = @_;

    $hash->{DefFn}    = 'Proscenic_Define';
    #$hash->{NotifyFn} = 'Proscenic_Notify';
    $hash->{UndefFn}  = 'Proscenic_Undefine';
    $hash->{SetFn}    = 'Proscenic_Set';
    $hash->{GetFn}    = 'Proscenic_Get';
    $hash->{AttrList} = 'serial ';
    $hash->{AttrList} .= $readingFnAttributes;
    $hash->{NOTIFYDEV} = "global";
}


sub Proscenic_Define($) {
    my ($hash, $def) = @_;
    my $name = $hash->{NAME};
    my @a = split("[ \t][ \t]*", $def);

    return undef;
}


sub Proscenic_Undefine($$) {                     
    my ($hash, $name) = @_;               
    RemoveInternalTimer($hash);    
    return undef;                  
}


sub Proscenic_Set($$@) {
    my ($hash, $name, $cmd, @args) = @_;

    return "\"set $name\" needs at least one argument" unless(defined($cmd));

    my $list = 'mode stop:noArg run:noArg dock:noArg start:noArg';

    return "Unknown argument $cmd, choose one of $list";
}


sub Proscenic_Send($$) {
    my ($dest, $cmd)  = @_;
    my $sock = IO::Socket::INET->new(
        Proto    => 'udp',
        PeerPort => 10684,
        PeerAddr => '255.255.255.255',
        Broadcast => 1
    ) or die "Could not create socket: $!\n";
    $sock->send($cmd) or die "Send error: $!\n";
    return "send $cmd";
}


sub Proscenic_Build($$) {
    my ($hash, $command) = @_;
    my $xml = XMLout(KeyAttr => { server => 'name' }, ForceArray => [ 'server', 'address' ]);
    return $xml;
}

