use strict;
use Test::More tests=>6;
use IO::AIO::Util qw(aio_mkpath);
use File::Temp qw(tempdir tempfile);
use File::Spec::Functions qw(catdir);

# Copied from IO::AIO tests
sub pcb {
    while (IO::AIO::nreqs) {
        vec (my $rfd="", IO::AIO::poll_fileno, 1) = 1;
        select $rfd, undef, undef, undef;
        IO::AIO::poll_cb;
    }
}

# CLEANUP doens't work, so do it manually in an END block.
my $tmp = tempdir();
END {
    IO::AIO::aio_rmtree $tmp, sub {
        $_[0] and diag "Failed to remove test directory: $tmp";
    };
}

{
    my $dir = catdir( $tmp, qw(dir1 dir2) );

    aio_mkpath $dir, 0777, sub {
        is( $_[0], 0, 'return status: $_[0]' );
        is( -d $dir, 1, "-d $dir" );
    };

    pcb;

    aio_mkpath $dir, 0777, sub {
        is( $_[0], 0, "directory already exists");
    };

    pcb;
}

{
    my (undef, $file) = tempfile( DIR => $tmp );

    aio_mkpath $file, 0777, sub {
        is( $_[0], -1, "file already exists" );
    };

    pcb;
}

{
    my $dir = catdir( $tmp, qw(dir1 dir2) );
    chmod 0000, $dir or die "$!\n";
    my $subdir = catdir($dir, 'dir3');

    aio_mkpath $subdir, 0777, sub {
        is( $_[0], -1, "bad permissions" );
    };

    pcb;

    chmod 0777, $dir or die "$dir: $!\n";
}

{
    my $dir = catdir( $tmp, qw(dir4 dir5) );

    aio_mkpath $dir, 0111, sub {
        is( $_[0], -1, "mkpath 0111, $dir" );
    };

    pcb;

    $dir = catdir( $tmp, qw(dir4) );
    chmod 0777, $dir or die "$dir: $!\n";
}
