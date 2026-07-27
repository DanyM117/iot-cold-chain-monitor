#!/bin/bash

function validate_internet(){
    if ! ping -c 4 8.8.8.8 > /dev/null 2>&1 ;then
        echo "No internet connection detected"
        return 1
    fi
    echo "Internet connection confirmed"
    return 0
}
validate_internet
