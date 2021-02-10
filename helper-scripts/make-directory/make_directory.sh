#!/usr/bin/env sh

#
#   A function to create a directory if the directory does not exist
#


make_directory(){
    # Make the tmp install directory
    dir="$1"
    if [ ! -d "$dir" ]; then
        # Determine if the dir does not exist. If it doesn't, create it.
        logging "" "Creating directory installation directory at $dir ..."
        /bin/mkdir -p "$dir"
    else
        # Log that the dir already exists.
        logging "" "$dir already exists."
    fi
}

# Call make_directory
make_directory "/path/to/directory"
