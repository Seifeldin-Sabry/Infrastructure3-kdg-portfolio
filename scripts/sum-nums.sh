#! /bin/bash
# biggestnum.sh: Find the biggest number in 2 parameters.

numParam=2
numParamsPassed=$#
E_WRONGARGS="invalid number of arguments, 2 needed"
E_WRONGARG_TYPE="invalid type of arguments, numbers needed"

checkArgs()
{
  if [ $# -ne "$numParamsPassed" ];
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

printSum()
{
  echo $(($1 + $2))
}

checkArgs "$numParamsPassed" "$E_WRONGARGS"
checkTypes $*
printSum $*