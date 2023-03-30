#!/bin/bash
#A bash program to ask for the user to guess the number randomly generated from 1 to 1000 saving user and guess database

PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"

MAIN(){
  #Number between 1 to 1000 that the user guesses
  NUMBER_TO_GUESS=$(( $RANDOM % 1000 +1 ))
  
  #Call to get the user information if in the database already
  GET_USER

  #Initialize the guess try count and call function to guess the number
  echo -e "\nGuess the secret number between 1 and 1000:"
  TRY_COUNT=0
  GUESS_NUMBER
}

#Function to ask for username to get past information or store new user to database
GET_USER(){
  #Get a username from Player
  echo "Enter your username:"
  read USERNAME
  USERNAME_SEARCH=$($PSQL "SELECT games_played,best_game FROM user_guess_game_stats WHERE username='$USERNAME'")

  #If the username doesn't exist
  if [[ -z $USERNAME_SEARCH ]]
  then
    #Create new user in the database table
    echo -e "\nWelcome, $USERNAME! It looks like this is your first time here."
    ADD_USER=$($PSQL "INSERT INTO user_guess_game_stats(username) VALUES('$USERNAME')")
  
  #If user exist get its number of games and best game stats
  else
    IFS="|" read NUM_GAMES BEST_GAME <<< $USERNAME_SEARCH
    echo -e "\nWelcome back, $USERNAME! You have played $NUM_GAMES games, and your best game took $BEST_GAME guesses."
  fi
}

#Recursive function calling itself until the guess input matches the number to be guessed
GUESS_NUMBER(){
  #read input and increment the number of tries
  read GUESS
  (( TRY_COUNT ++ ))

  #If the input guess is not a number
  if [[ ! $GUESS =~ ^[0-9]+$ ]]
  then 
    echo -e "\nThat is not an integer, guess again:"
  else
    #if the input is less than that number
    if [[ $GUESS -lt $NUMBER_TO_GUESS ]]
    then
      echo -e "\nIt's higher than that, guess again:"
      GUESS_NUMBER
    #if the input is higher that that number
    elif [[ $GUESS -gt $NUMBER_TO_GUESS ]] 
    then
      echo -e "\nIt's lower than that, guess again:"
      GUESS_NUMBER
    #if the input and the number to be guessed are equal
    else
      UPDATE_STATS
      echo -e "\nYou guessed it in $TRY_COUNT tries. The secret number was $NUMBER_TO_GUESS. Nice job!"
    fi
  fi
}

#Function to update the games played and best game of a user after finishing a game/round
UPDATE_STATS(){
  #Add one to the number of games played
  INCREMENT_GAMES=$($PSQL "UPDATE user_guess_game_stats SET games_played=games_played+1 WHERE username='$USERNAME'")

  #If the best game in database is higher than this game's try count or User is just initialized, update it
  if [[ $TRY_COUNT -lt $BEST_GAME ||  $BEST_GAME -eq 0 ]]
  then
    UPDATE_BEST_GAME=$($PSQL "UPDATE user_guess_game_stats SET best_game=$TRY_COUNT")
  fi
}

MAIN