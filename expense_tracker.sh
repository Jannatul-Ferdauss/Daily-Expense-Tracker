#!/bin/bash

EXPENSE_FILE="expenses.csv"
INCOME_FILE="income.txt"
GOAL_FILE="goal.txt"

# Initialize files if not exist
touch $EXPENSE_FILE
[ ! -f $INCOME_FILE ] && echo "0" > $INCOME_FILE
[ ! -f $GOAL_FILE ] && echo "0" > $GOAL_FILE

add_income() {
    clear
    read -p "Enter income amount: " income
    current=$(cat $INCOME_FILE)
    echo $((current + income)) > $INCOME_FILE
    echo "Income added successfully."
    pause
}

add_expense() {
    clear
    read -p "Enter Date (YYYY-MM-DD): " date
    read -p "Enter Category (e.g., Food, Transport): " category
    read -p "Enter Amount: " amount
    read -p "Enter Description: " description
    echo "$date,$category,$amount,$description" >> $EXPENSE_FILE
    echo "Expense added!"
    pause
}

edit_expense() {
    clear
    view_expenses
    read -p "Enter line number to edit: " line
    sed -i "${line}d" $EXPENSE_FILE
    echo "Enter new details:"
    add_expense
}

delete_expense() {
    clear
    view_expenses
    read -p "Enter line number to delete: " line
    sed -i "${line}d" $EXPENSE_FILE
    echo "Expense deleted!"
    pause
}

view_expenses() {
    clear
    echo "Line | Date       | Category   | Amount | Description"
    echo "-----------------------------------------------------"
    nl -s ". " $EXPENSE_FILE | awk -F, '{printf "%-4s %-11s %-10s %-7s %-s\n", $1, $2, $3, $4, $5}'
    echo "-----------------------------------------------------"
}

summary_today() {
    clear
    today=$(date +%F)
    awk -F, -v today="$today" '$1==today {sum+=$3} END {print "Today's Total Expense: " sum}' $EXPENSE_FILE
    pause
}

summary_month() {
    clear
    month=$(date +%Y-%m)
    awk -F, -v m="$month" '$1 ~ m {sum+=$3} END {print "Monthly Total Expense: " sum}' $EXPENSE_FILE
    pause
}

category_summary() {
    clear
    read -p "Enter category: " cat
    awk -F, -v c="$cat" '$2==c {sum+=$3} END {print "Total spent on " c ": " sum}' $EXPENSE_FILE
    pause
}

budget_alert() {
    clear
    budget=500
    today=$(date +%F)
    spent=$(awk -F, -v today="$today" '$1==today {sum+=$3} END {print sum}' $EXPENSE_FILE)
    echo "Today's spending: $spent"
    if (( $(echo "$spent > $budget" | bc -l) )); then
        echo "⚠️ Budget exceeded!"
    else
        echo "✅ Within budget."
    fi
    pause
}

track_savings_goal() {
    clear
    read -p "Set new savings goal: " goal
    echo "$goal" > $GOAL_FILE
    echo "Goal saved!"
    pause
}

view_goal_progress() {
    clear
    income=$(cat $INCOME_FILE)
    total_exp=$(awk -F, '{sum+=$3} END {print sum}' $EXPENSE_FILE)
    goal=$(cat $GOAL_FILE)
    saved=$((income - total_exp))
    echo "Income: $income"
    echo "Expenses: $total_exp"
    echo "Saved: $saved"
    echo "Goal: $goal"
    if (( saved >= goal )); then
        echo "🎯 Goal achieved!"
    else
        echo "📉 Remaining: $((goal - saved))"
    fi
    pause
}

filter_expenses() {
    clear
    echo "1. Filter by Date"
    echo "2. Filter by Category"
    echo "3. Filter by Amount >="
    read -p "Choose option: " opt
    case $opt in
        1) read -p "Enter date (YYYY-MM-DD): " d; grep "^$d" $EXPENSE_FILE ;;
        2) read -p "Enter category: " c; awk -F, -v c="$c" '$2==c' $EXPENSE_FILE ;;
        3) read -p "Minimum amount: " a; awk -F, -v a="$a" '$3 >= a' $EXPENSE_FILE ;;
        *) echo "Invalid." ;;
    esac
    pause
}

pause() {
    echo
    read -p "Press Enter to continue..." key
    main_menu
}

main_menu() {
    clear
    echo "=============================="
    echo " Daily Expense Tracker System"
    echo "=============================="
    echo
    echo "1. Add Expense"
    echo "2. Edit Expense"
    echo "3. Delete Expense"
    echo "4. View All Expenses"
    echo "5. Daily Summary"
    echo "6. Monthly Summary"
    echo "7. Category-wise Summary"
    echo "8. Add Income"
    echo "9. View Budget Alert"
    echo "10. Set Savings Goal"
    echo "11. View Savings Progress"
    echo "12. Filter Expenses"
    echo "13. Exit"
    echo
    read -p "Choose an option: " choice
    case $choice in
        1) add_expense ;;
        2) edit_expense ;;
        3) delete_expense ;;
        4) view_expenses; pause ;;
        5) summary_today ;;
        6) summary_month ;;
        7) category_summary ;;
        8) add_income ;;
        9) budget_alert ;;
        10) track_savings_goal ;;
        11) view_goal_progress ;;
        12) filter_expenses ;;
        13) exit ;;
        *) echo "Invalid!" ; pause ;;
    esac
}

main_menu
