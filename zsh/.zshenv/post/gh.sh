#!/bin/sh

# Open current branch PR in browser, or the create-PR page if none exists
alias gpro='gh pr view --web 2>/dev/null || gh pr create --web --fill'
