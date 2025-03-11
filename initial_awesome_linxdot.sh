#!/bin/sh

# Script Name: initial_awesome_linxdot.sh
# Purpose: Clean crontab and prepare the system for Linxdot customization
# Author: [Your Name]
# Date: [Today's Date]

echo "Step 1: Cleaning crontab..."
echo "" > /etc/crontabs/root  # This will clear all crontab jobs
/etc/init.d/cron restart  # Restart cron service to apply changes

echo "Crontab cleaned successfully!"
