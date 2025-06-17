#!/bin/bash

USERS_DIR="data/users"
ADMIN_SECRET="data/admin.secret"
SESSION_FILE=".session"

mkdir -p "$USERS_DIR"

hash_secret() {
    echo -n "$1" | sha256sum | cut -d' ' -f1
}

register_user() {
    clear
    echo "===== User Registration ====="
    read -p "Choose a username: " username
    
    # Validate username
    if [[ -z "$username" ]]; then
        echo "❌ Username cannot be empty!"
        read -p "Press Enter to go back..." _
        return 1
    fi
    
    user_path="$USERS_DIR/$username.secret"

    if [ -f "$user_path" ]; then
        echo "❌ User already exists!"
        read -p "Press Enter to go back..." _
        return 1
    fi

    read -s -p "Set your secret key: " secret
    echo
    
    # Validate secret key
    if [[ -z "$secret" ]]; then
        echo "❌ Secret key cannot be empty!"
        read -p "Press Enter to go back..." _
        return 1
    fi
    
    # Create user files
    hash_secret "$secret" > "$user_path"
    touch "$USERS_DIR/$username.exp"
    echo "0" > "$USERS_DIR/$username.inc"
    echo "0" > "$USERS_DIR/$username.goal"
    echo "active" > "$USERS_DIR/$username.status"

    echo "✅ Registration successful! You can now login."
    read -p "Press Enter to return to menu..." _
    return 0
}

login_user() {
    clear
    echo "===== User Login ====="
    read -p "Username: " username
    
    if [[ -z "$username" ]]; then
        echo "❌ Username cannot be empty!"
        read -p "Press Enter..." _
        return 1
    fi
    
    user_secret_file="$USERS_DIR/$username.secret"
    user_status_file="$USERS_DIR/$username.status"

    if [ ! -f "$user_secret_file" ]; then
        echo "❌ User not found!"
        read -p "Press Enter..." _
        return 1
    fi

    if [ "$(cat $user_status_file)" = "inactive" ]; then
        echo "🚫 Your account is deactivated. Contact admin."
        read -p "Press Enter..." _
        return 1
    fi

    read -s -p "Secret Key: " secret
    echo
    
    if [[ -z "$secret" ]]; then
        echo "❌ Secret key cannot be empty!"
        read -p "Press Enter..." _
        return 1
    fi
    
    input_hash=$(hash_secret "$secret")
    stored_hash=$(cat "$user_secret_file")

    if [ "$input_hash" = "$stored_hash" ]; then
        echo "$username" > "$SESSION_FILE"
        return 0  # Success
    else
        echo "❌ Wrong secret key!"
        read -p "Press Enter..." _
        return 1  # Failure
    fi
}

login_admin() {
    clear
    echo "===== Admin Login ====="
    read -s -p "Admin Secret: " secret
    echo
    
    if [[ -z "$secret" ]]; then
        echo "❌ Admin secret cannot be empty!"
        read -p "Press Enter..." _
        return 1
    fi
    
    input_hash=$(hash_secret "$secret")
    stored_hash=$(cat "$ADMIN_SECRET")

    if [ "$input_hash" = "$stored_hash" ]; then
        return 0  # Success
    else
        echo "❌ Invalid Admin Key!"
        read -p "Press Enter..." _
        return 1  # Failure
    fi
}

admin_menu() {
    while true; do
        clear
        echo "===== Admin Panel ====="
        echo "1. View Users"
        echo "2. Deactivate a User"
        echo "3. Activate a User"
        echo "4. Delete a User"
        echo "5. View User Statistics"
        echo "6. Exit Admin Panel"
        echo "========================"
        read -p "Choose option: " opt

        case $opt in
            1)
                echo
                echo "Registered Users:"
                echo "=================="
                if ls "$USERS_DIR"/*.secret >/dev/null 2>&1; then
                    for user_file in "$USERS_DIR"/*.secret; do
                        username=$(basename "$user_file" .secret)
                        status=$(cat "$USERS_DIR/$username.status" 2>/dev/null || echo "unknown")
                        printf "%-15s [%s]\n" "$username" "$status"
                    done
                else
                    echo "No users registered yet."
                fi
                ;;
            2)
                echo
                read -p "Username to deactivate: " u
                if [ -f "$USERS_DIR/$u.secret" ]; then
                    echo "inactive" > "$USERS_DIR/$u.status"
                    echo "✅ $u is now deactivated."
                else
                    echo "❌ User not found."
                fi
                ;;
            3)
                echo
                read -p "Username to activate: " u
                if [ -f "$USERS_DIR/$u.secret" ]; then
                    echo "active" > "$USERS_DIR/$u.status"
                    echo "✅ $u is now activated."
                else
                    echo "❌ User not found."
                fi
                ;;
            4)
                echo
                read -p "Username to delete: " u
                if [ -f "$USERS_DIR/$u.secret" ]; then
                    read -p "Are you sure you want to delete user '$u'? (y/N): " confirm
                    if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
                        rm -f "$USERS_DIR/$u."*
                        echo "✅ User $u deleted."
                    else
                        echo "❌ Deletion cancelled."
                    fi
                else
                    echo "❌ User not found."
                fi
                ;;
            5)
                echo
                echo "User Statistics:"
                echo "================"
                total_users=$(ls "$USERS_DIR"/*.secret 2>/dev/null | wc -l)
                active_users=$(grep -l "active" "$USERS_DIR"/*.status 2>/dev/null | wc -l)
                inactive_users=$((total_users - active_users))
                echo "Total Users: $total_users"
                echo "Active Users: $active_users"
                echo "Inactive Users: $inactive_users"
                ;;
            6) 
                echo "Exiting admin panel..."
                break 
                ;;
            *) 
                echo "❌ Invalid choice."
                ;;
        esac
        echo
        read -p "Press Enter to continue..." _
    done
}