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
use MIME::Base64;


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

    my $list = 'mode:auto,area,edge,zigzag stop:noArg run:noArg dock:noArg start:noArg';

    readingsSingleUpdate($hash, 'last_clean', time(), 1) if($cmd eq 'start' || $cmd eq 'mode');

    return Proscenic_Send($hash, DOCK) if($cmd eq 'dock');
    return Proscenic_Send($hash, STOP) if($cmd eq 'stop');
    return Proscenic_Send($hash, RUN) if($cmd eq 'start');

    if($cmd eq 'mode') {
        readingsSingleUpdate($hash, 'mode', $args[0], 1);
        return Proscenic_Send($hash, MODE_AUTO)  if($args[0] eq 'auto');
        return Proscenic_Send($hash, MODE_AREA) if($args[0] eq 'area');
        return Proscenic_Send($hash, MODE_EDGE) if($args[0] eq 'edge');
        return Proscenic_Send($hash, MODE_ZIGZAG) if($args[0] eq 'zigzag');
    }

    return "Unknown argument $cmd, choose one of $list";
}


sub Proscenic_Get($$@) {
    my ($hash, $name, $cmd, @args) = @_;

    my $list = "";

    return "Unknown argument $cmd, choose one of $list";
}


sub Proscenic_Send($$) {
    my ($hash, $command)  = @_;
    my $sock = IO::Socket::INET->new(
        Proto    => 'udp',
        PeerPort => 10684,
        PeerAddr => '255.255.255.255',
        Broadcast => 1
    ) or die "Could not create socket: $!\n";

    $sock->send(Proscenic_Build($hash, $command)) or die "Send error: $!\n";

    return undef;
}


sub Proscenic_Build($$) {
    my ($hash, $command) = @_;
    my $name = $hash->{NAME};

    my $packet = {
        HEADER => {
            MsgType => 'MSG_TRANSIT_SHAS_REQ',
            MsgSeq => 1,
            From => '020000000000000000',
            To => $attr{$name}{serial},
            Keep => 0
        },
        MESSAGE => {
            Version => '1.0',
                BODY => {
                    content => encode_base64('<TRANSIT_INFO><COMMAND>ROBOT_CMD</COMMAND><RTU>' . $command . '</RTU></TRANSIT_INFO>')
                }
            }
    };

    return XMLout($packet, KeyAttr => { }, RootName => 'xml', NoIndent => 1, XMLDecl => 1);
}


1;