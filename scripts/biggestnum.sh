#! /bin/bash
# biggestnum.sh: Find the biggest number in 2 parameters.

numParam=2
numParamsPassed=$#
E_WRONGARGS="invalid number of arguments, 2 needed"
E_WRONGARG_TYPE="invalid type of arguments, numbers needed"

checkArgs()
{
  if [ $# -ne "$numParam" ];
  then
    echo "$E_WRONGARGS"
    exit 1
  fi
}

checkTypes()
{
  if [[ ! $1 =~ ^[0-9]+$ ]] || [[ ! $2 =~ ^[0-9]+$ ]];
  then
    echo "$E_WRONGARG_TYPE"
    exit 1
  fi
}

printBiggest()
{
  if [ $1 -gt $2 ];
  then
    echo $1
  elif [ $1 -lt $2 ];
  then
    echo $2
  else
    echo "The numbers are equal."
  fi
}

checkArgs "$numParamsPassed" "$numParam" "$E_WRONGARGS"
checkTypes $*
printBiggest $*