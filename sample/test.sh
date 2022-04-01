chrset=$(file -i Anecdote_of_the_Y.txt)

echo ${chrset##*charset=}