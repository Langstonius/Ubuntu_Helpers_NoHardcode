#!/bin/bash
. /etc/lmce-build/builder.conf
. /usr/local/lmce-build/common/logging.sh

function Checkout_Git {
    DisplayMessage "**** STEP : GIT CHECKOUT"

    mkdir -p "$git_dir"

    pushd ${git_dir}
        LASTVERSION="$(date +%Y%m%d%H%M%S)"
        DisplayMessage "Cloning from ${git_url}"
        git clone "${git_url}" ${git_branch_name} || Error "Failed to clone ${git_url}"
        
        pushd ${git_branch_name}
            git checkout ${git_branch} || Error "Failed to checkout branch ${git_branch}"
        popd
    popd

    if [ "$git_private_url" != "" ]; then
        pushd ${git_dir}/${git_branch_name}/src
            DisplayMessage "Cloning private modules from ${git_private_url}"
            
            # ZWave repository
            if [ -d "ZWave" ]; then
                rm -rf ZWave
            fi
            git clone ${git_private_url}/ZWave.git ZWave || Error "Failed to clone ZWave repository"
            
            # Fiire_Scripts repository
            if [ -d "Fiire_Scripts" ]; then
                rm -rf Fiire_Scripts
            fi
            git clone ${git_private_url}/Fiire_Scripts.git Fiire_Scripts || Error "Failed to clone Fiire_Scripts repository"
            
            # RFID_Interface repository
            if [ -d "RFID_Interface" ]; then
                rm -rf RFID_Interface
            fi
            git clone ${git_private_url}/RFID_Interface.git RFID_Interface || Error "Failed to clone RFID_Interface repository"
        popd
    fi

    cp -R ${git_dir}/${git_branch_name} ${git_dir}/${git_branch_name}-last
}

function Update_Git {
    DisplayMessage "**** STEP : GIT UPDATE"

    pushd ${git_dir}/${git_branch_name}-last
        # Store the last commit hash before updating
        LASTVERSION=$(git rev-parse --short HEAD)
        DisplayMessage "Updating Git from ${git_url}, current commit: ${LASTVERSION}"
        
        # Fetch latest changes
        git fetch origin || Error "Failed to fetch from ${git_url}"
        
        # Reset and update to latest on the branch
        git reset --hard origin/${git_branch} || Error "Failed to update to latest commit"
    popd

    if [ "$git_private_url" != "" ]; then
        pushd ${git_dir}/${git_branch_name}/src
            DisplayMessage "Updating private repositories"
            
            # Update ZWave
            pushd ZWave
                git fetch origin
                git reset --hard origin/main || git reset --hard origin/master
            popd
            
            # Update Fiire_Scripts
            pushd Fiire_Scripts
                git fetch origin
                git reset --hard origin/main || git reset --hard origin/master
            popd
            
            # Update RFID_Interface
            pushd RFID_Interface
                git fetch origin
                git reset --hard origin/main || git reset --hard origin/master
            popd
        popd
    fi
    
    # Replace working directory with updated version
    rm -rf ${git_dir}/${git_branch_name}
    DisplayMessage "Copying updated checkout to work directory"
    cp -R ${git_dir}/${git_branch_name}-last ${git_dir}/${git_branch_name}
}

mkdir -p "$git_dir"

if [ -e ${git_dir}/${git_branch_name}-last ] ; then
    Update_Git
else
    Checkout_Git
fi

pushd ${git_dir}/${git_branch_name}
    # Get short commit hash
    SHORT_HASH=$(git rev-parse --short HEAD)
    # Get commit count (can be used as a numerical version)
    COMMIT_COUNT=$(git rev-list --count HEAD)
    # Combine for version info
    VERSION="${COMMIT_COUNT}-${SHORT_HASH}"
popd

DisplayMessage "Old version was $LASTVERSION, new version is $VERSION"