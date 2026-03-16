#!/bin/bash

# Number guessing game script

# Generate random number between 1 and 1000
SECRET_NUMBER=$(( RANDOM % 1000 + 1 ))

# PSQL variable for database queries
PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"

# Prompt for username
echo "Enter your username:"
read USERNAME

# Check if username exists (limit to 22 characters)
USERNAME=$(echo $USERNAME | cut -c1-22)

# Get user info from database
USER_INFO=$($PSQL "SELECT games_played, best_game FROM users WHERE username='$USERNAME'")

if [[ -z $USER_INFO ]]; then
  # New user
  echo "Welcome, $USERNAME! It looks like this is your first time here."
  # Insert new user
  INSERT_RESULT=$($PSQL "INSERT INTO users(username) VALUES('$USERNAME')")
else
  # Returning user
  GAMES_PLAYED=$(echo $USER_INFO | cut -d'|' -f1)
  BEST_GAME=$(echo $USER_INFO | cut -d'|' -f2)
  echo "Welcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
fi

# Start guessing game
echo "Guess the secret number between 1 and 1000:"
GUESS_COUNT=0

while true; do
  read GUESS

  # Check if input is an integer
  if ! [[ $GUESS =~ ^[0-9]+$ ]]; then
    echo "That is not an integer, guess again:"
    continue
  fi

  ((GUESS_COUNT++))

  if (( GUESS < SECRET_NUMBER )); then
    echo "It's higher than that, guess again:"
  elif (( GUESS > SECRET_NUMBER )); then
    echo "It's lower than that, guess again:"
  else
    # Correct guess
    echo "You guessed it in $GUESS_COUNT tries. The secret number was $SECRET_NUMBER. Nice job!"

    # Update database
    # Increment games played
    UPDATE_GAMES=$($PSQL "UPDATE users SET games_played = games_played + 1 WHERE username='$USERNAME'")

    # Update best game if this is better (lower guesses) or first game
    if [[ -z $BEST_GAME ]] || (( GUESS_COUNT < BEST_GAME )); then
      UPDATE_BEST=$($PSQL "UPDATE users SET best_game = $GUESS_COUNT WHERE username='$USERNAME'")
    fi

    break
  fi
done