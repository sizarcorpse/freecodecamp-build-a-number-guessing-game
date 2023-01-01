#!/bin/bash
PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"

START_GAME() {
    # game function will be add here

    # if any argument is pass will be show
    if [[ ! -z $1 ]]; then
        echo -e "$1"
    fi

    # get user guessed number
    read USER_GUESSED_NUMBER

    # if user input it not integer will restart
    if [[ ! $USER_GUESSED_NUMBER =~ ^[0-9]+$ ]]; then
        START_GAME "That is not an integer, guess again:"

    else
        # Every time user guess new numbrt will it increase the numder of tries
        ((NUMBER_OF_GUESSES += 1))

        #
        if [[ $USER_GUESSED_NUMBER == $MAX_NUMBER && $USER_GUESSED_NUMBER != $SECRET_NUMBER ]]; then
            START_GAME "It's lower than that, guess again:"
        fi

        #
        if [[ $USER_GUESSED_NUMBER == $SECRET_NUMBER ]]; then
            # congratulations message
            echo "You guessed it in $NUMBER_OF_GUESSES tries. The secret number was $SECRET_NUMBER. Nice job!"

            # update user information in database
            USER_STATS=$($PSQL "SELECT username, games_played, best_game FROM users WHERE username = '$ENTRY_USERNAME'")

            IFS="|" read USERNAME GAMES_PLAYED BEST_GAME <<<$USER_STATS

            NEW_BEST_GAME=0

            if [[ $BEST_GAME -eq 0 ]]; then
                NEW_BEST_GAME=$NUMBER_OF_GUESSES
            elif [[ $NUMBER_OF_GUESSES -lt $best_game ]]; then
                NEW_BEST_GAME=$NUMBER_OF_GUESSES
            else
                NEW_BEST_GAME=$BEST_GAME
            fi

            UPDATE_USER="$($PSQL "UPDATE users set games_played = games_played + 1, best_game = $NEW_BEST_GAME WHERE username = '$USERNAME'")"
        fi

        #
        if [[ $SECRET_NUMBER < $USER_GUESSED_NUMBER ]]; then
            START_GAME "It's higher than that, guess again:"
        fi

        #
        if [[ $SECRET_NUMBER > $USER_GUESSED_NUMBER ]]; then
            START_GAME "It's lower than that, guess again:"
        fi
    fi
}

MAIN() {
    # start main function

    MAX_NUMBER=1000
    SECRET_NUMBER=$(($RANDOM % $MAX_NUMBER + 1))
    NUMBER_OF_GUESSES=0

    # ask Username for user.
    echo "Enter your username:"
    read ENTRY_USERNAME

    # check user validation
    IS_USER=$($PSQL "SELECT username, games_played, best_game FROM users WHERE username ilike '$ENTRY_USERNAME'")

    # if user alreay exits ?

    if [[ $IS_USER ]]; then

        GET_USER_INFO=$($PSQL "SELECT username, games_played, best_game FROM users WHERE username = '$ENTRY_USERNAME'")

        IFS="|" read USERNAME GAMES_PLAYED BEST_GAME <<<$GET_USER_INFO

        echo "Welcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."

        START_GAME "Guess the secret number between 1 and 1000:"

    # if a new user
    else

        # Create an anncount for new user
        CREATED_USER=$($PSQL "INSERT INTO users(username) VALUES('$ENTRY_USERNAME')")

        if [[ $CREATED_USER == "INSERT 0 1" ]]; then
            echo -e "Welcome, $ENTRY_USERNAME! It looks like this is your first time here.\n"
        fi

        START_GAME "Guess the secret number between 1 and 1000:"

    fi
}

MAIN
