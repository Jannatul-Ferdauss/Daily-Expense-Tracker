#!/bin/bash

# main.sh - Main entry point
source auth.sh
source tracker.sh

data_dir="data/users"
session_file=".session"

mkdir -p "$data_dir"

# Initialize admin password if not exists
if [ ! -f "data/admin.secret" ]; then
    echo -n "Set admin password: "
    read -s admin_pass
    echo
    echo -n "$admin_pass" | sha256sum | cut -d' ' -f1 > data/admin.secret
    echo "Admin password set."
fi

# Clean any existing session on startup
[ -f "$session_file" ] && rm "$session_file"

main_menu() {
    while true; do
        clear
        echo "=============================="
        echo " Daily Expense Tracker System"
        echo "=============================="
        echo "1. Login"
        echo "2. Register"
        echo "3. Admin Login"
        echo "4. Exit"
        echo "=============================="
        read -p "Choose an option: " opt
        
        case $opt in
            1) 
                if login_user; then
                    username=$(cat "$session_file")
                    user_dashboard "$username"
                fi
                ;;
            2) register_user ;;
            3) 
                if login_admin; then
                    admin_dashboard
                fi
                ;;
            4) 
                echo "Goodbye!"
                exit 0
                ;;
            *) 
                echo "Invalid option. Please try again."
                sleep 1
                ;;
        esac
    done
}

# Function to handle user dashboard after login
user_dashboard() {
    local username="$1"
    echo "✅ Welcome, $username!"
    sleep 1
    main_menu_user
}

# Function to handle admin dashboard after login
admin_dashboard() {
    echo "✅ Admin access granted!"
    sleep 1
    admin_menu
}

# Start the application
main_menu