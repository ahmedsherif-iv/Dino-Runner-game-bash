#!/bin/bash

declare -A matrix
declare -A obstacles_positions

SIG_UP=USR1 #for interprocess communication
SIG_QUIT=KILL #kill signal
SIG_DEAD=HUP #hangup

alive=1 
score=0 

N_ROW=6
N_COL=80

CHARACTER="#"
GROUND="="
OBSTACLE="+"
EMPTY=" "

jump_count=0
obstacles_count=10
char_position=3
char_direction=0 #1 jump, 0 normal position

getchar() {
    trap "" SIGINT SIGQUIT
    trap "return;" $SIG_DEAD

    while true 
    do
        read -s -n 1 key # -s silet mode, -n nchars (just 1 character)
        case "$key" in
            [qQ]) kill -$SIG_QUIT $game_loop_pid #sends quit signal to the game process
                  return
                  ;;
            [wW]) kill -$SIG_UP $game_loop_pid
                  ;;
       esac
    done
}

move_char(){ 
  matrix[$(($char_position-1)),2]=$EMPTY
  matrix[$char_position,2]=$EMPTY
  if [ "${matrix[4,2]}" != "$OBSTACLE" ]
  then
   matrix[$(($char_position+1)),2]=$EMPTY
  fi
 if [ $char_direction -eq 1 ] && [ $char_position -gt 1 ]
 then
  if [ $jump_count -eq 2 ]
  then
   jump_count=0
   char_direction=0
  fi
  let jump_count+=1
  matrix[$(($char_position-1)),2]=$CHARACTER
  matrix[$(($char_position)),2]=$CHARACTER
  if [ "${matrix[4,2]}" = "$OBSTACLE" ]
  then
   let score+=1
  fi
 else
  if [ $char_position -ne 3 ]
  then
   let char_position+=1
  fi
  matrix[$char_position,2]=$CHARACTER
  if [ "${matrix[4,2]}" != "$OBSTACLE" ]
  then
   matrix[$(($char_position+1)),2]=$CHARACTER
  else
   alive=0
  fi
 fi
}

init_matrix(){
 alive=1
 for ((i=0;i<$N_ROW;i++))
 do
  for ((j=0;j<$N_COL;j++))
  do
   if [ $i -eq $(($N_ROW - 1)) ]
   then
    matrix[$i,$j]=$GROUND
   else 
    matrix[$i,$j]=$EMPTY
   fi
  done
 done
}

print_game(){
 temp=""
 for ((i=0;i<$N_ROW;i++))
 do
  for ((j=0;j<$N_COL;j++))
  do
   temp+=${matrix[$i,$j]}
  done
  temp+="\n"
 done
 echo -e "$temp"
}

init_obstacles(){
 obstacles_positions[0]=$N_COL 
 for((i=1;i<$obstacles_count;i++))
 do
  rand_value=$(( $RANDOM % 11 + 10))
  let obstacles_positions[$i]=${obstacles_positions[$(($i-1))]}+$rand_value
 done
}

generate_obstacles(){
 obstacle_row=$(($N_ROW-2))
 for ((i=0;i<$obstacles_count;i++))
  do
   t_posit=${obstacles_positions[$i]}
   matrix[$obstacle_row,$(($t_posit+1))]=$EMPTY
   matrix[$obstacle_row,$(($t_posit))]=$OBSTACLE
   matrix[$obstacle_row,$(($t_posit-1))]=$EMPTY
   let obstacles_positions[$i]-=1
   if [ ${obstacles_positions[$i]} -lt 0 ]
   then
    matrix[$obstacle_row,$(($t_posit))]=$EMPTY
    rand_value=$(( $RANDOM % 50 + 40))
    let obstacles_positions[$i]=$N_COL+50+$rand_value
   fi
  done
}

game_loop()
{
 trap "char_direction=1;" $SIG_UP #catches the signal and executes the command
 trap "exit 1;" $SIG_QUIT
 while [ "$alive" -eq 1 ]
 do
  clear
  move_char
  print_game
  generate_obstacles
  echo "Your score: $score"
  echo
  echo "press q to quit"
  sleep 0.15
 done
 
 echo "You Lost!!!!!!!!"
 kill -$SIG_DEAD $$ # $$ the process id of the script
}

init_matrix
init_obstacles

print_game

game_loop & #subprocess
game_loop_pid=$!

getchar

#exit 0


