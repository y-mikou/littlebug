 
      i=$((3 * 2)); 
      if [ $(( ${i} - 4 )) -gt 0 ] && [ $(( 3 - 4 )) -lt 0 ]; then 
        echo '_center'; 
      elif [ 4 -eq 3 ]; then 
        echo '_mono'; 
      elif [ $(( ${i} - 4 )) -lt 0 ] || [ $(( 3 - 4 )) -lt 0 ]; then 
        echo '_long'; 
      else echo '_short'; 
      fi
 
      i=$((1 * 2)); 
      if [ $(( ${i} - 1 )) -gt 0 ] && [ $(( 1 - 1 )) -lt 0 ]; then 
        echo '_center'; 
      elif [ 1 -eq 1 ]; then 
        echo '_mono'; 
      elif [ $(( ${i} - 1 )) -lt 0 ] || [ $(( 1 - 1 )) -lt 0 ]; then 
        echo '_long'; 
      else echo '_short'; 
      fi
 
      i=$((3 * 2)); 
      if [ $(( ${i} - 9 )) -gt 0 ] && [ $(( 3 - 9 )) -lt 0 ]; then 
        echo '_center'; 
      elif [ 9 -eq 3 ]; then 
        echo '_mono'; 
      elif [ $(( ${i} - 9 )) -lt 0 ] || [ $(( 3 - 9 )) -lt 0 ]; then 
        echo '_long'; 
      else echo '_short'; 
      fi
 
      i=$((2 * 2)); 
      if [ $(( ${i} - 3 )) -gt 0 ] && [ $(( 2 - 3 )) -lt 0 ]; then 
        echo '_center'; 
      elif [ 3 -eq 2 ]; then 
        echo '_mono'; 
      elif [ $(( ${i} - 3 )) -lt 0 ] || [ $(( 2 - 3 )) -lt 0 ]; then 
        echo '_long'; 
      else echo '_short'; 
      fi
 
      i=$((3 * 2)); 
      if [ $(( ${i} - 4 )) -gt 0 ] && [ $(( 3 - 4 )) -lt 0 ]; then 
        echo '_center'; 
      elif [ 4 -eq 3 ]; then 
        echo '_mono'; 
      elif [ $(( ${i} - 4 )) -lt 0 ] || [ $(( 3 - 4 )) -lt 0 ]; then 
        echo '_long'; 
      else echo '_short'; 
      fi
 
      i=$((2 * 2)); 
      if [ $(( ${i} - 2 )) -gt 0 ] && [ $(( 2 - 2 )) -lt 0 ]; then 
        echo '_center'; 
      elif [ 2 -eq 2 ]; then 
        echo '_mono'; 
      elif [ $(( ${i} - 2 )) -lt 0 ] || [ $(( 2 - 2 )) -lt 0 ]; then 
        echo '_long'; 
      else echo '_short'; 
      fi
 
      i=$((5 * 2)); 
      if [ $(( ${i} - 4 )) -gt 0 ] && [ $(( 5 - 4 )) -lt 0 ]; then 
        echo '_center'; 
      elif [ 4 -eq 5 ]; then 
        echo '_mono'; 
      elif [ $(( ${i} - 4 )) -lt 0 ] || [ $(( 5 - 4 )) -lt 0 ]; then 
        echo '_long'; 
      else echo '_short'; 
      fi
 
      i=$((5 * 2)); 
      if [ $(( ${i} - 5 )) -gt 0 ] && [ $(( 5 - 5 )) -lt 0 ]; then 
        echo '_center'; 
      elif [ 5 -eq 5 ]; then 
        echo '_mono'; 
      elif [ $(( ${i} - 5 )) -lt 0 ] || [ $(( 5 - 5 )) -lt 0 ]; then 
        echo '_long'; 
      else echo '_short'; 
      fi
