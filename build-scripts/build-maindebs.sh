#!/bin/bash

. /etc/lmce-build/builder.conf
. /usr/local/lmce-build/common/logging.sh
. /usr/local/lmce-build/build-scripts/name-packages.sh
. /usr/local/lmce-build/build-scripts/version-helper.sh

LC_ALL=C

set -e
#set -x

make_jobs=""
# set NUMCORES=X in /etc/lmce-build/builder.conf to enable multi-job builds
[[ -n "$NUM_CORES" ]] && [[ "$NUM_CORES" -gt 1 ]] && make_jobs="-j $NUM_CORES"

PLUTO_BUILD_CRED=""
if [ "$sql_build_host" ] ; then PLUTO_BUILD_CRED="$PLUTO_BUILD_CRED -h $sql_build_host"; fi
if [ "$sql_build_port" ] ; then PLUTO_BUILD_CRED="$PLUTO_BUILD_CRED -P $sql_build_port"; fi
if [ "$sql_build_user" ] ; then PLUTO_BUILD_CRED="$PLUTO_BUILD_CRED -u $sql_build_user"; fi
if [ "$sql_build_pass" ] ; then PLUTO_BUILD_CRED="$PLUTO_BUILD_CRED -p $sql_build_pass"; fi
export PLUTO_BUILD_CRED

MYSQL_BUILD_CRED=""
if [ "$sql_build_host" ] ; then MYSQL_BUILD_CRED="$MYSQL_BUILD_CRED -h$sql_build_host"; fi
if [ "$sql_build_port" ] ; then MYSQL_BUILD_CRED="$MYSQL_BUILD_CRED -P$sql_build_port"; fi
if [ "$sql_build_user" ] ; then MYSQL_BUILD_CRED="$MYSQL_BUILD_CRED -u$sql_build_user"; fi
if [ "$sql_build_pass" ] ; then MYSQL_BUILD_CRED="$MYSQL_BUILD_CRED -p$sql_build_pass"; fi
export MYSQL_BUILD_CRED

export SNR_CPPFLAGS="$compile_defines"

function build_main_debs() {
    export PATH=$PATH:${git_dir}/${git_branch_name}/src/bin
    echo "PATH=$PATH"
    export LD_LIBRARY_PATH="$mkr_dir:${git_dir}/${git_branch_name}/src/lib"
    echo "LD_LIBRARY_PATH=$LD_LIBRARY_PATH"

    ##FIXME Hackozaurus to build SimplePhone
    #export PKG_CONFIG_PATH=/opt/linphone-1.3.5/lib/pkgconfig
    #LinphoneVersion="$(dpkg -s 'liblinphone5' | grep '^Version: ' | cut -d' ' -f2)"
    #if [[ "$LinphoneVersion" != "1.3."* ]]; then
    #	# Linphone 1.5.1 in Ubuntu Feisty makes SimplePhone to need this
    #	export LINPHONE_CONST=const
    #fi

    #FIXME Hackozaurus for pluto-dummy-console-tools
    mkdir -p /usr/pluto/dummy-packages/
    touch /usr/pluto/dummy-packages/Readme.PlutoConsoleUtilities.dummy

    #FIXME Hackozaurus for pluto-devel-dependencies
    touch /home/README.Devel.Dependencies

    # Clear the debs output directory
    DisplayMessage "Cleaning MakeRelease debs output directory"
    rm -rf "${out_dir}" || Error "Cannot clean MakeRelease debs output directory"
    mkdir -p "${out_dir}" || Error "Cannot create MakeRelease debs output directory"

    # Prepare some params values for MakeRelease
    DisplayMessage "Compiling and building packages"
    
    # Get Git revision information
    pushd "${git_dir}"/${git_branch_name}/src > /dev/null
    GIT_HASH=$(git rev-parse --short HEAD)
    GIT_COUNT=$(git rev-list --count HEAD)
    GIT_REVISION="${GIT_COUNT}-${GIT_HASH}"
    popd > /dev/null

    exclude_list=$mkr_videolan_plugin_common
    exclude_list=$exclude_list,$mkr_videolan_plugin_server
    exclude_list=$exclude_list,$mkr_videolan_plugin_client
    exclude_list=$exclude_list,$mkr_pwc_camera_drivers
    exclude_list=$exclude_list,$mkr_ati_video_drivers
    exclude_list=$exclude_list,$mkr_alsa_drivers
    exclude_list=$exclude_list,$mkr_diskless_default_boot_file_package
    exclude_list=$exclude_list,$mkr_diskless_base_filesystem_package

    # The default version string is 2.0.0.44 and gets amended by the git count plus time of day and date
    Main_Version='2.0.0.44.'
    case "${flavor}" in
        "ubuntu")
            #FIXME Hackozaurus for ubuntu-diskless-tools
            mkdir -p /home/DisklessFS/
            diskless_image_name="PlutoMD_Debootstraped.tar.bz2"
            #cp "${diskless_dir}/$diskless_image_name" /home/DisklessFS
            #cp "${diskless_dir}/PlutoMD_Debootstraped.tar.bz2" /home/DisklessFS

            case "${build_name}" in
                "gutsy")
                    Distro_ID="15"
                    ;;
                "hardy")
                    Distro_ID="16"
                    ;;
                "intrepid")
                    Distro_ID="17"
                    exclude_list=$exclude_list,$mkr_tira
                    # USB Game Pad
                    exclude_list=$exclude_list,795,796
                    ;;
                "lucid")
                    Distro_ID="18"
                    RepositorySource=21
                    Main_Version='2.0.0.45.'
                    ;;
                "precise")
                    Distro_ID="20"
                    RepositorySource=25
                    Main_Version='2.0.0.46.'
                    ;;
                "trusty")
                    Distro_ID="21"
                    RepositorySource=25
                    Main_Version='2.0.0.47.'
                    exclude_list=$exclude_list,673,674 # lmce game player
                    case "${arch}" in
                        "armhf")
                            exclude_list=$exclude_list,452,453 # IRTrans - no armhf .so
                            exclude_list=$exclude_list,879,881 # qOrbiter for Android
                            exclude_list=$exclude_list,682,683 # mame
                            ;;
                        "amd64")
                            exclude_list=$exclude_list,879,881 # qorbiter android
                            ;;
                    esac
                    ;;
                "xenial")
                    Distro_ID="23"
                    RepositorySource=25
                    Main_Version='2.0.0.48.'
                    exclude_list=$exclude_list,673,674 # lmce game player - fails to build
                    exclude_list=$exclude_list,682,683 # mame - fails to build
                    exclude_list=$exclude_list,879,881 # qorbiter android - no sdk/ndk
                    exclude_list=$exclude_list,721,722 # dpms monitor - never work anyways
                    exclude_list=$exclude_list,826,827 # ago-control bridge
                    case "${arch}" in
                        "armhf")
                            exclude_list=$exclude_list,452,453 # IRTrans - no armhf .so
                            : ;;
                        "amd64")
                            : ;;
                    esac
                    ;;
                "jammy")
                    Distro_ID="24"
                    RepositorySource=25
                    Main_Version='2.0.0.49.'
                    exclude_list=$exclude_list,673,674 # lmce game player - fails to build
                    exclude_list=$exclude_list,682,683 # mame - fails to build
                    exclude_list=$exclude_list,879,881 # qorbiter android - no sdk/ndk
                    exclude_list=$exclude_list,721,722 # dpms monitor - never work anyways
                    exclude_list=$exclude_list,826,827 # ago-control bridge
                    case "${arch}" in
                        "armhf")
                            exclude_list=$exclude_list,452,453 # IRTrans - no armhf .so
                            : ;;
                        "amd64")
                            : ;;
                    esac
                    ;;
            esac
            ;;
        "raspbian")
            #FIXME Hackozaurus for ubuntu-diskless-tools
            mkdir -p /home/DisklessFS/
            diskless_image_name="PlutoMD_Debootstraped-$flavor-$build_name-$arch.tar.bz2"
            #cp "${diskless_dir}/$diskless_image_name" /home/DisklessFS

            case "${build_name}" in
                jessie)
                    Distro_ID="22"
                    RepositorySource=23
                    Main_Version='2.0.0.47.'
                    # not currently compatible
                    exclude_list=$exclude_list,498,499	# simplephone

                    # does not compile
                    exclude_list=$exclude_list,682,683	# MAME
                    ;;
                wheezy)
                    Distro_ID="19"
                    RepositorySource=23
                    Main_Version='2.0.0.46.'
                    # not currently compatible
                    :

                    # does not compile
                    exclude_list=$exclude_list,862,863	# Hue Controller (qt4)
                    exclude_list=$exclude_list,682,683	# MAME
                    ;;
            esac
            ;;
    esac

    # Set version of packages to todays date plus git commit count
    Q="Update Version Set VersionName= concat('$Main_Version',substr(now()+0,3,6),'$GIT_COUNT') Where PK_Version = 1;"
    mysql $PLUTO_BUILD_CRED -D 'pluto_main_build' -e "$Q"

    create_version_h ${git_dir} ${git_branch_name} ${Main_Version} "${GIT_REVISION}" "${GIT_HASH}" "${GIT_COUNT}"

    # Compile the packages
    echo "\"${mkr_dir}/MakeRelease\" $make_jobs -a -R \"$GIT_REVISION\" $PLUTO_BUILD_CRED -O \"$out_dir\" -D 'pluto_main_build' -o \"$Distro_ID\" -r \"$RepositorySource\" -m 1,1176 -K \"$exclude_list\" -s \"${git_dir}/${git_branch_name}\" -n / -d"
    arch=$arch "${mkr_dir}/MakeRelease" $make_jobs -a -R "$GIT_REVISION" $PLUTO_BUILD_CRED -O "$out_dir" -D 'pluto_main_build' -o "$Distro_ID" -r "$RepositorySource" -m 1,1176 -K "$exclude_list" -s "${git_dir}/${git_branch_name}" -n / -d || Error "MakeRelease failed"

#	# Compile the private packages
#	if [ "$git_private_url" != "" ]
#	then
#		echo "\"${mkr_dir}/MakeRelease\" $make_jobs -a -R \"$GIT_REVISION\" $PLUTO_BUILD_CRED -O \"$out_dir\" -D 'pluto_main_build' -o \"$Distro_ID\" -r \"$RepositorySource\" -m 1108 -K \"$exclude_list\" -s \"${git_dir}/${git_branch_name}\" -n / -d"
#		arch=$arch "${mkr_dir}/MakeRelease" $make_jobs -a -R "$GIT_REVISION" $PLUTO_BUILD_CRED -O "$out_dir" -D 'pluto_main_build' -o "$Distro_ID" -r "$RepositorySource" -m 1108 -K "$exclude_list" -s \"${git_dir}/${git_branch_name}\" -n / -d || Error "MakeRelease failed on private packages"
#	fi
}


DisplayMessage "*** STEP: Running MakeRelease"
trap 'Error "Undefined error in $0"' EXIT

build_main_debs

trap - EXIT
DisplayMessage "*** STEP: Finished MakeRelease"