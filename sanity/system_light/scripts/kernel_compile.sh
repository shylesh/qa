#! /bin/bash
## vi: ai si et ts=4 sw=4 sts=4 bs=2 sta sr

ENV_me=$(basename $0);
ENV_medir="$(dirname $0)";
[ "$ENV_medir" = "." ] && ENV_medir="$(pwd)";
ENV_retval=0;

ENV_short_options='cs:m:V';
ENV_long_options='continue,site:,mainline:,verbose,quiet,help,version';

ENV_timestamp_in_log=0;     # 0 = Disabled, 1 = Enabled
ENV_log="/dev/stderr";
ENV_verbosity=2;
ENV_debug=1;
ENV_tmpdir="";              ## Temporary directory. Defined later

ENV_version="0.0";
ENV_copyright_years="2008";

def_mainline="2.6";
def_site="http://www.kernel.org";

function print_help () {
    cat <<-_HERE_
Usage: $ENV_me [OPTION]... [FILE]...
<DESCRIPTION HERE>.

Mandatory arguments to long options are mandatory for short options too.
      --help    display this help and exit
      --version output version information and exit
_HERE_
}

function timestamp () {
    echo "$(date +%F\ %T)";
}

function log () {
    if [ "$ENV_timestamp_in_log" = "1" ]; then
        echo "$ENV_me: $(timestamp): $@" | tee -a $log;
    else
        echo "$ENV_me: $(timestamp): $@";
    fi
}

function debug () {
    if [ "$ENV_debug" = 1 -o "$ENV_verbosity" = 3]; then
        echo "$@";
    fi
}

function error () {
    if [ "$ENV_verbosity" -ge 1 ]; then
        echo "$ENV_me: $@" 1>&2;
        quit 1;
    fi
}

function warn () {
    if [ "$ENV_verbosity" -ge 1 ]; then
        echo "$ENV_me: $@" 1>&2;
    fi
}

function outn () {
    if [ "$ENV_verbosity" -ge 2 ]; then
        echo -n "$@";
    fi
}

function out () {
    if [ "$ENV_verbosity" -ge 2 ]; then
        echo "$@";
    fi
}

function outln () {
    if [ "$ENV_verbosity" -ge 2 ]; then
        echo -n "$@" | tee -a $ENV_log;
    fi
}

function outl () {
    if [ "$ENV_verbosity" -ge 2 ]; then
        echo "$@" | tee -a $ENV_log;
    fi
}

function quit () {
    [ -d "$ENV_tmpdir" ] && rm -rf "$ENV_tmpdir";
    exit $1;
}

function print_version () {
    if [ "$ENV_package" != "" ]; then
        version_str="$ENV_me ($ENV_package) $ENV_version";
    else
        version_str="$ENV_me $ENV_version";
    fi

    cat <<-_version_
		$version_str
		Copyright (C) ${ENV_copyright_years:-$(date +%Y)} Z Research, Inc.
_version_
}

function print_usage () {
    warn "Try \`$ENV_me --help' for more information.";
    if [ "$1" != "0" -a "$1" != "" ]; then
        exit "$1";
    fi
}

function parseargs () {
    unset ${!OPT_@};
    ARGV=($(getopt --shell bash --name $ENV_me \
    --option "$ENV_short_options" \
    --longoptions "$ENV_long_options" \
    -- "$@")) || print_usage 1;

    local index=0;
    while [ "${ARGV[$index]}" != "--" ]; do
        local opt="$(echo ${ARGV[$index]//-/_} | sed 's/^__\?//')";
        eval local arg=${ARGV[$index+1]};   ## eval to get rid of 's

        if [[ "${ARGV[$index+1]}" =~ ^$'\''.* ]]; then # To
##             debug "Setting OPT_$opt = $arg";
            eval OPT_${opt}=$arg;
            index=$((index+1));
        else
##             debug "Incrementing OPT_$opt";
            eval OPT_$opt=$((OPT_$opt+1));
        fi
        index=$((index+1));
    done
    eval ARGV=("${ARGV[@]:$index+1}");
}

function make_tmp_dir () {
    local dirname="$ENV_me.$RANDOM.$RANDOM.$RANDOM.$$";
    ENV_tmpdir="$((umask 077 && \
                   mktemp -d -q ${tmpdir:-/tmp}/$dirname) 2>/dev/null)";
    [ -z "$ENV_tmpdir" ] || [ ! -d "$ENV_tmpdir" ] && {
        warn "Unable to create temporary directory. Exiting ..";
        return 1;
    }
    return 0;
}

function get_tarball () {
    url="$1";
    filename=$(basename $url);
    basedir=$(pwd);

    [ -f "$filename" ] && {
        [ "$OPT_continue" != "1" ] && error "$filename: file exists.";
    }
    wget -c $url;
## out "Updating Timestamps ..";
##   $UPDATE_TIMESTAMP "$filename";

    return 0;
}


function get_latest_tarball () {
    basedir=$(pwd);
    cd $ENV_tmpdir;

    echo -n "Retreiving listing [ $ENV_site ] ... ";
    wget -q "$ENV_site";
    echo "Done";

    latest=$(sed -n '/The latest stable version of the Linux kernel is/,/<\/tr>/p' index.html | \
        sed -n 's/.*"\(.*\)">F<.*/\1/p');
    [ "$latest" = "" ] && error "$ENV_site: No tarball found";

    cd $basedir;
    url="$ENV_site$latest";
    get_tarball "$url";

    return 0;
}

function init () {
    parseargs "$@";
    set -e;

    [ "$OPT_help" = "1" ] && print_help && quit 0;
    [ "$OPT_version" = "1" ] && print_version && quit 0;
    trap 'quit 255' 1 2 3 6 13 15;
    make_tmp_dir || quit 1;    

    OPT_verbosity=$((${OPT_verbose:-0} + ${OPT_v:-0}));

    ENV_mainline=${OPT_mainline:-${OPT_m:-$def_mainline}};
    ENV_site=${OPT_site:-${OPT_s:-$def_site}};

    return 0;
}

function main () {
    filename=;

    if [ ${#ARGV[@]} = 0 ]; then
        out "No input specified. Fetching latest kernel tarball ..";
        get_latest_tarball;
    elif [[ "${ARGV[0]}" =~ ^http|ftp ]]; then
        out "URL detected. Fetching from URL ..";
        get_tarball "$@";
    elif [ -f "${ARGV[0]}" ]; then
        filename=$(basename ${ARGV[0]});
        if [[ ("${ARGV[0]}" =~ /) && ("${ARGV[0]::2}" != "./") ]]; then
            out "File detected. Copying from location ..";
            cp "${ARGV[0]}" .;
        fi
    else
        error "${ARGV[0]}: Unknown input method";
    fi

    out "Extracting Tarball ..";
    tar -jxf $filename;
    cd ${filename%.tar.bz2};
    find . -exec touch '{}' \;
    out "Making defconfig";
    make defconfig;
    if [ $? -ne 0 ]; then
       err=$?
       echo "Make defconfig failed"
       return $err
    fi
    echo "its not coming here"
    out "Making depmod ..";
    #make depmod;
    make dep;
    if [ $? -ne 0 ]; then
      err=$?
      echo "Make dep failed"
      return $err
    fi
    out "Making bzImage ..";
    make bzImage;
    if [ $? -ne 0 ]; then
      err=$?
      echo "Make bzImage failed"
      return $err
    fi
    out "Making modules ..";
    make modules;
    if [ $? -ne 0 ]; then
      err=$?
      echo "Make modules failed"
      return $err
    fi
    quit 0;
}

init "$@" && main "$@";
#quit $ENV_retval;


