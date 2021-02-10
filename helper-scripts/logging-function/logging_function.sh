#!/bin/sh


SCRIPT_NAME=$(/usr/bin/basename "$0" | /usr/bin/awk -F "." '{print $1}')


logging() {
    # logging function
    # Takes in a log level and log string and logs to /Library/Logs. Will set the log
    # level to INFO if the first builtin $1 is passed as an empty string.
    # Example: logging "INFO" "Something describing what happened", and logging "INFO"
    #          "Something describing what happened" pass the same log string to the #          log file.
    #
    # Args:
    #   $1: Log level. Examples "info", "warning", "debug", "error"
    #   $2" Log statement in string format

    log_level=$(printf "$1" | /usr/bin/tr '[:lower:]' '[:upper:]')
    log_statement="$2"
    log_name="$SCRIPT_NAME.log"
    log_path="/Library/Logs/$log_name"

    if [ -z "$log_level" ]; then
        # If the first builtin is an empty string set it to log level INFO
        log_level="INFO"
    fi

    if [ -z "$log_statement" ]; then
        # The statement was piped to the log function from another command.
        log_statement=""
    fi

    current_date=$(/bin/date +"[%b %d, %Y %Z %T $log_level]:")
    printf "%s %s\n" "$current_date" "$log_statement" >> "$log_path"
}


logging "" "This is a test ..."
