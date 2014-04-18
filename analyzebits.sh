#!/bin/bash

#Copyright 2014@Santosh Dwivedi, All Rights Reserved.
#The code contained herein is licensed under the GNU General Public
#License. You may obtain a copy of the GNU General Public License
#Version 2 or later at the following locations:
# http://www.opensource.org/licenses/gpl-license.html
# http://www.gnu.org/copyleft/gpl.html


# This script is to define and decode cpu register bits.
Configure() {
OUTPUT=$(zenity --forms --title="Configure register" --text="cpu register" --add-entry="name") 
accepted=$?
register_name="$OUTPUT"
echo $register_name
if [ -z "$register_name" ];then
exit 0
fi
register_name+=".cpureg"
>  $WORKING_DIR/$register_name
while [ !accepted ]
do 
OUTPUT=$(zenity --forms --ok-label="Add" --cancel-label="Done" --title="Configure register bits" --text="Add bit field definition to $register_name" --separator="," --add-entry="bit field(s) name" --add-entry="field LSB" --add-entry="field MSB" >> $WORKING_DIR/$register_name)
accepted=$?
if ((accepted != 0)); then
    echo "register $register_name configuired."
    exit 1
fi
done
}

GetField()
{
val="$1"
startindex="$2"
length="$3"
bit_mask=$((((1 << length) - 1) << startindex))
extracted_bits=$((val & bit_mask)) 
local result=$((extracted_bits >> startindex)) 
echo "$result"
}

Evaluate()
{
echo "Evaluating register $1 with value $2 gui option $3"
guioption="$3"
labels=""
while read regdefs
do
#echo "$regdefs"
_name=$(awk -F, '{print $1}' <<<$regdefs)
_lsb=$(awk -F, '{print $2}' <<<$regdefs)
_msb=$(awk -F, '{print $3}' <<<$regdefs)
_length=$(($_msb-$_lsb+1))
#echo "$_name starts $_lsb length $_length"
field_value=$(GetField $2 $_lsb $_length)
echo "bit field  $_name = $field_value"
if [ ! -z "$guioption" ]; then
labels+=" --add-entry=$_name --entry-text=$field_value"  
fi

done < $WORKING_DIR/$1

if [ ! -z "$guioption" ]; then
echo "TODO: implement GUI option $labels"
while [ !accepted ]
do 
OUTPUT=$(zenity --forms --ok-label="ASSEMBLE" --cancel-label="DECODE" --title="$register_name" --text="$register_name" --separator="," $labels)
accepted=$?
done
fi

}

while getopts cd:e:glv: option
do
        case "${option}"
        in
                c) configopt=1;;
                d) DIR=${OPTARG};;
                e) evalreg=${OPTARG};;
                l) listreg=1;;
                g|gui) gui=1;;
                v) valreg=${OPTARG};;
                *) echo "Available options are:";
                   echo "-c     to configure new cpu register";
                   echo "-d dir to set dir as working directory";
                   echo "-l to list configured registers";
                   echo "-e reg.cpureg [-v value] [-g ] to decode bit fields";;
        esac
done

#echo "got options  working dir [$DIR] config[$configopt] eval[$evalreg] regval[$valreg] "
if [ -n "$DIR" ];  then 
echo "$DIR" > workingdir.tmp
fi

if [ -f workingdir.tmp ]; then
WORKING_DIR=$(< workingdir.tmp)
else 
WORKING_DIR="$(pwd)/cpu_reg"
fi

#echo "Working directory is $WORKING_DIR" 
mkdir -p $WORKING_DIR
#echo "config option is $configopt"
if [ ! -z "$configopt" ];  then 
 Configure
fi

if [ -n "$evalreg" ];  then 
echo "$evalreg = $valreg"
Evaluate "$evalreg" "$valreg" "$gui"
fi

if [ ! -z "$listreg" ];  then 
 echo "Known registers in this configuration are:"
 ls -p $WORKING_DIR | grep -v /
fi


