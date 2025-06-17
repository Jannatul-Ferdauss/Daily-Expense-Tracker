#!/bin/bash

USERS_DIR="data/users"
SESSION_FILE=".session"

# Get current logged-in username
get_username() {
    if [ -f "$SESSION_FILE" ]; then
        cat "$SESSION_FILE"
    else
        echo ""
    fi
}

# Initialize user files
init_user_files() {
    local username="$1"
    local exp_file="$USERS_DIR/$username.exp"
    local inc_file="$USERS_DIR/$username.inc"
    local goal_file="$USERS_DIR/$username.goal"
    
    [ ! -f "$exp_file" ] && touch "$exp_file"
    [ ! -f "$inc_file" ] && echo "0" > "$inc_file"
    [ ! -f "$goal_file" ] && echo "0" > "$goal_file"
}

add_income() {
    local username=$(get_username)
    local inc_file="$USERS_DIR/$username.inc"
    
    echo
    read -p "Enter income amount: " income
    
    # Validate input
    if ! [[ "$income" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
        echo "❌ Invalid amount. Please enter a valid number."
        pause
        return
    fi
    
    local current=$(cat "$inc_file")
    echo $((current + income)) > "$inc_file"
    echo "✅ Income of $income added successfully!"
    pause
}

add_expense() {
    local username=$(get_username)
    local exp_file="$USERS_DIR/$username.exp"
    
    echo
    read -p "Enter Date (YYYY-MM-DD) or press Enter for today: " date
    
    # Use today's date if empty
    if [[ -z "$date" ]]; then
        date=$(date +%Y-%m-%d)
    fi
    
    # Validate date format
    if ! [[ "$date" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
        echo "❌ Invalid date format. Use YYYY-MM-DD."
        pause
        return
    fi
    
    read -p "Enter Category: " category
    if [[ -z "$category" ]]; then
        echo "❌ Category cannot be empty."
        pause
        return
    fi
    
    read -p "Enter Amount: " amount
    if ! [[ "$amount" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
        echo "❌ Invalid amount. Please enter a valid number."
        pause
        return
    fi
    
    read -p "Enter Description: " description
    if [[ -z "$description" ]]; then
        description="No description"
    fi
    
    echo "$date,$category,$amount,$description" >> "$exp_file"
    echo "✅ Expense added successfully!"
    pause
}

edit_expense() {
    local username=$(get_username)
    local exp_file="$USERS_DIR/$username.exp"
    
    if [ ! -s "$exp_file" ]; then
        echo "❌ No expenses found to edit."
        pause
        return
    fi
    
    echo
    view_expenses
    echo
    read -p "Enter line number to edit: " line
    
    if ! [[ "$line" =~ ^[0-9]+$ ]]; then
        echo "❌ Invalid line number."
        pause
        return
    fi
    
    local total_lines=$(wc -l < "$exp_file")
    if (( line < 1 || line > total_lines )); then
        echo "❌ Line number out of range."
        pause
        return
    fi
    
    sed -i "${line}d" "$exp_file"
    echo "Enter new details for the expense:"
    add_expense
}

delete_expense() {
    local username=$(get_username)
    local exp_file="$USERS_DIR/$username.exp"
    
    if [ ! -s "$exp_file" ]; then
        echo "❌ No expenses found to delete."
        pause
        return
    fi
    
    echo
    view_expenses
    echo
    read -p "Enter line number to delete: " line
    
    if ! [[ "$line" =~ ^[0-9]+$ ]]; then
        echo "❌ Invalid line number."
        pause
        return
    fi
    
    local total_lines=$(wc -l < "$exp_file")
    if (( line < 1 || line > total_lines )); then
        echo "❌ Line number out of range."
        pause
        return
    fi
    
    read -p "Are you sure you want to delete this expense? (y/N): " confirm
    if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
        sed -i "${line}d" "$exp_file"
        echo "✅ Expense deleted successfully!"
    else
        echo "❌ Deletion cancelled."
    fi
    pause
}

view_expenses() {
    local username=$(get_username)
    local exp_file="$USERS_DIR/$username.exp"
    
    if [ ! -s "$exp_file" ]; then
        echo "No expenses recorded yet."
        return
    fi
    
    echo "Line | Date       | Category   | Amount | Description"
    echo "-----+------------+------------+--------+-------------"
    nl -s ". " "$exp_file" | awk -F, '{printf "%-4s | %-10s | %-10s | %-6s | %-s\n", $1, $2, $3, $4, $5}'
    echo "-----+------------+------------+--------+-------------"
}

summary_today() {
    local username=$(get_username)
    local exp_file="$USERS_DIR/$username.exp"
    local today=$(date +%Y-%m-%d)
    
    echo
    local total=$(awk -F, -v today="$today" '$1==today {sum+=$3} END {print sum+0}' "$exp_file")
    echo "📊 Today's Expenses ($today): $total"
    pause
}

summary_month() {
    local username=$(get_username)
    local exp_file="$USERS_DIR/$username.exp"
    local month=$(date +%Y-%m)
    
    echo
    local total=$(awk -F, -v m="$month" '$1 ~ m {sum+=$3} END {print sum+0}' "$exp_file")
    echo "📊 This Month's Expenses ($month): $total"
    pause
}

category_summary() {
    local username=$(get_username)
    local exp_file="$USERS_DIR/$username.exp"
    
    echo
    read -p "Enter category name: " cat
    if [[ -z "$cat" ]]; then
        echo "❌ Category cannot be empty."
        pause
        return
    fi
    
    local total=$(awk -F, -v c="$cat" '$2==c {sum+=$3} END {print sum+0}' "$exp_file")
    echo "📊 Total expenses for '$cat': $total"
    pause
}

budget_alert() {
    local username=$(get_username)
    local exp_file="$USERS_DIR/$username.exp"
    
    echo
    read -p "Enter daily budget limit: " budget
    if ! [[ "$budget" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
        echo "❌ Invalid budget amount."
        pause
        return
    fi
    
    local today=$(date +%Y-%m-%d)
    local spent=$(awk -F, -v today="$today" '$1==today {sum+=$3} END {print sum+0}' "$exp_file")
    
    echo "💰 Daily Budget: $budget"
    echo "💸 Today's Spending: $spent"
    
    if (( $(echo "$spent > $budget" | bc -l) )); then
        echo "⚠️ Budget exceeded by $((spent - budget))!"
    else
        echo "✅ Within budget. Remaining: $((budget - spent))"
    fi
    pause
}

track_goal() {
    local username=$(get_username)
    local goal_file="$USERS_DIR/$username.goal"
    
    echo
    read -p "Enter your savings goal: " goal
    if ! [[ "$goal" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
        echo "❌ Invalid goal amount."
        pause
        return
    fi
    
    echo "$goal" > "$goal_file"
    echo "✅ Savings goal of $goal set successfully!"
    pause
}

view_goal_progress() {
    local username=$(get_username)
    local inc_file="$USERS_DIR/$username.inc"
    local exp_file="$USERS_DIR/$username.exp"
    local goal_file="$USERS_DIR/$username.goal"
    
    local income=$(cat "$inc_file")
    local total_exp=$(awk -F, '{sum+=$3} END {print sum+0}' "$exp_file")
    local goal=$(cat "$goal_file")
    local saved=$((income - total_exp))
    
    echo
    echo "📊 Financial Overview:"
    echo "======================"
    echo "💰 Total Income: $income"
    echo "💸 Total Expenses: $total_exp"
    echo "💵 Amount Saved: $saved"
    echo "🎯 Savings Goal: $goal"
    echo
    
    if (( saved >= goal )); then
        echo "🎉 Congratulations! Goal reached!"
        local excess=$((saved - goal))
        if (( excess > 0 )); then
            echo "✨ You've exceeded your goal by $excess!"
        fi
    else
        local remaining=$((goal - saved))
        echo "📈 Remaining to reach goal: $remaining"
        if (( goal > 0 )); then
            local progress=$((saved * 100 / goal))
            echo "📊 Progress: $progress%"
        fi
    fi
    pause
}

filter_expenses() {
    local username=$(get_username)
    local exp_file="$USERS_DIR/$username.exp"
    
    if [ ! -s "$exp_file" ]; then
        echo "❌ No expenses found to filter."
        pause
        return
    fi
    
    echo
    echo "Filter Options:"
    echo "==============="
    echo "1. Filter by Date"
    echo "2. Filter by Category"
    echo "3. Filter by Amount >="
    echo "4. Filter by Date Range"
    read -p "Choose filter option: " opt
    
    echo
    case $opt in
        1) 
            read -p "Enter date (YYYY-MM-DD): " d
            echo "Expenses for $d:"
            echo "================="
            grep "^$d" "$exp_file" | nl -s ". " | awk -F, '{printf "%-4s | %-10s | %-10s | %-6s | %-s\n", $1, $2, $3, $4, $5}'
            ;;
        2) 
            read -p "Enter category: " c
            echo "Expenses for category '$c':"
            echo "=========================="
            awk -F, -v c="$c" '$2==c' "$exp_file" | nl -s ". " | awk -F, '{printf "%-4s | %-10s | %-10s | %-6s | %-s\n", $1, $2, $3, $4, $5}'
            ;;
        3) 
            read -p "Enter minimum amount: " a
            echo "Expenses >= $a:"
            echo "==============="
            awk -F, -v a="$a" '$3 >= a' "$exp_file" | nl -s ". " | awk -F, '{printf "%-4s | %-10s | %-10s | %-6s | %-s\n", $1, $2, $3, $4, $5}'
            ;;
        4)
            read -p "Enter start date (YYYY-MM-DD): " start_date
            read -p "Enter end date (YYYY-MM-DD): " end_date
            echo "Expenses from $start_date to $end_date:"
            echo "======================================"
            awk -F, -v start="$start_date" -v end="$end_date" '$1 >= start && $1 <= end' "$exp_file" | nl -s ". " | awk -F, '{printf "%-4s | %-10s | %-10s | %-6s | %-s\n", $1, $2, $3, $4, $5}'
            ;;
        *) 
            echo "❌ Invalid option."
            ;;
    esac
    pause
}

pause() {
    echo
    read -p "Press Enter to continue..." _
}

main_menu_user() {
    local username=$(get_username)
    
    if [[ -z "$username" ]]; then
        echo "❌ No user session found. Please login first."
        return
    fi
    
    # Initialize user files
    init_user_files "$username"
    
    while true; do
        clear
        echo "======================================="
        echo "    Expense Tracker - Welcome $username"
        echo "======================================="
        echo "1.  Add Expense"
        echo "2.  Edit Expense"
        echo "3.  Delete Expense"
        echo "4.  View All Expenses"
        echo "5.  Daily Summary"
        echo "6.  Monthly Summary"
        echo "7.  Category Summary"
        echo "8.  Add Income"
        echo "9.  Budget Alert"
        echo "10. Set Savings Goal"
        echo "11. View Goal Progress"
        echo "12. Filter Expenses"
        echo "13. Logout"
        echo "======================================="
        read -p "Choose an option (1-13): " choice

        case $choice in
            1) add_expense ;;
            2) edit_expense ;;
            3) delete_expense ;;
            4) echo; view_expenses; pause ;;
            5) summary_today ;;
            6) summary_month ;;
            7) category_summary ;;
            8) add_income ;;
            9) budget_alert ;;
            10) track_goal ;;
            11) view_goal_progress ;;
            12) filter_expenses ;;
            13) 
                echo "Logging out..."
                [ -f "$SESSION_FILE" ] && rm "$SESSION_FILE"
                echo "✅ Logged out successfully!"
                sleep 1
                break 
                ;;
            *) 
                echo "❌ Invalid option! Please choose 1-13."
                sleep 1
                ;;
        esac
    done
}