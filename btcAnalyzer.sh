#!/bin/bash

# Author: Anthony A.

greenColour="\e[0;32m\033[1m"
endColour="\033[0m\e[0m"
redColour="\e[0;31m\033[1m"
blueColour="\e[0;34m\033[1m"
yellowColour="\e[0;33m\033[1m"
purpleColour="\e[0;35m\033[1m"
turquoiseColour="\e[0;36m\033[1m"
grayColour="\e[0;37m\033[1m"

trap ctrl_c INT

function ctrl_c() {
  echo -e "\n${redColour}[!] Saliendo...${endColour}"

  rm ut.t* 2>/dev/null
  tput cnorm; exit 1
}

function helpPanel() {
  echo -e "\n${redColour}[!] Uso: /.btcAnalyzer.sh${endColour}";
  for i in $(seq 1 80); do echo -ne "${redColour}-"; done; echo -ne "${endColour}"

  echo -e "\n\n\t${grayColour}[-e]${endColour}${yellowColour} Modo exploración${endColour}"
  echo -e "\t\t${purpleColour}unconfirmed_transactions${endColour}${yellowColour}:\t Listar transacciones no confirmadas${endColour}"
  echo -e "\t\t${purpleColour}inspect${endColour}${yellowColour}:\t\t\t Inspeccionar un hash de transacción${endColour}"  
  echo -e "\t\t${purpleColour}address${endColour}${yellowColour}:\t\t\t Inspeccionar una transacción de dirección${endColour}" 
  echo -e "\n\t${grayColour}[-n]${endColour}${yellowColour} Limitar el número de resultados${endColour}${blueColour} (Ejemplo: -n 10)${endColour}"
  echo -e "\n\t${grayColour}[-i]${endColour}${yellowColour} Proporcionar el identificador de la transaccion${endColour}${blueColour} (Ejemplo: -i b66asd5a4ad2s47wdbs44has1a)${endColour}" 
  echo -e "\n\t${grayColour}[-a]${endColour}${yellowColour} Proporcionar una direccion de transaccion${endColour}${blueColour} (Ejemplo: -a bsad644asd7e8sddb557ssdsdh)${endColour}"
  echo -e "\n\t${grayColour}[-h]${endColour}${yellowColour} Mostrar el panel de ayuda ${endColour}\n"

  tput cnorm; exit 1
}

# Variables globales
unconfirmed_transaction="https://www.blockchain.com/es/btc/unconfirmed-transactions"
inspect_transaction_url="https://www.blockchain.com/es/btc/tx/"
inspect_address_url="https://www.blockchain.com/es/btc/address/"

function printTable(){

    local -r delimiter="${1}"
    local -r data="$(removeEmptyLines "${2}")"

    if [[ "${delimiter}" != '' && "$(isEmptyString "${data}")" = 'false' ]]
    then
        local -r numberOfLines="$(wc -l <<< "${data}")"

        if [[ "${numberOfLines}" -gt '0' ]]
        then
            local table=''
            local i=1

            for ((i = 1; i <= "${numberOfLines}"; i = i + 1))
            do
                local line=''
                line="$(sed "${i}q;d" <<< "${data}")"

                local numberOfColumns='0'
                numberOfColumns="$(awk -F "${delimiter}" '{print NF}' <<< "${line}")"

                if [[ "${i}" -eq '1' ]]
                then
                    table="${table}$(printf '%s#+' "$(repeatString '#+' "${numberOfColumns}")")"
                fi

                table="${table}\n"

                local j=1

                for ((j = 1; j <= "${numberOfColumns}"; j = j + 1))
                do
                    table="${table}$(printf '#| %s' "$(cut -d "${delimiter}" -f "${j}" <<< "${line}")")"
                done

                table="${table}#|\n"

                if [[ "${i}" -eq '1' ]] || [[ "${numberOfLines}" -gt '1' && "${i}" -eq "${numberOfLines}" ]]
                then
                    table="${table}$(printf '%s#+' "$(repeatString '#+' "${numberOfColumns}")")"
                fi
            done

            if [[ "$(isEmptyString "${table}")" = 'false' ]]
            then
                echo -e "${table}" | column -s '#' -t | awk '/^\+/{gsub(" ", "-", $0)}1'
            fi
        fi
    fi
}

function removeEmptyLines(){

    local -r content="${1}"
    echo -e "${content}" | sed '/^\s*$/d'
}

function repeatString(){

    local -r string="${1}"
    local -r numberToRepeat="${2}"

    if [[ "${string}" != '' && "${numberToRepeat}" =~ ^[1-9][0-9]*$ ]]
    then
        local -r result="$(printf "%${numberToRepeat}s")"
        echo -e "${result// /${string}}"
    fi
}

function isEmptyString(){

    local -r string="${1}"

    if [[ "$(trimString "${string}")" = '' ]]
    then
        echo 'true' && return 0
    fi

    echo 'false' && return 1
}

function trimString(){

    local -r string="${1}"
    sed 's,^[[:blank:]]*,,' <<< "${string}" | sed 's,[[:blank:]]*$,,'
}

function unconfirmedTransactions() {

  number_output=$1

  echo '' > ut.tmp

  while [ "$(cat ut.tmp | wc -l)" == "1" ]; do
    curl -s "$unconfirmed_transaction" | html2text > ut.tmp
  done


  hashes=$(cat ut.tmp | less -S | grep "Hash" -A 2 | grep -v -E "Hash|\--" | grep -o "\[.*]" | tr -d '[]' | head -n $number_output)
    
  echo "Hash_Cantidad_Bitcoin_Tiempo" > ut.table

  for hash in $hashes; do 
    echo "${hash}_$(cat ut.tmp | grep "$hash" -A 12 | tail -n 1)_$(cat ut.tmp | grep "$hash" -A 8 | tail -n 1)_$(cat ut.tmp | grep "$hash" -A 4 | tail -n 1)" >> ut.table
  done

  cat ut.table | tr '_' " " | awk '{print $2}' | grep -v "Cantidad" | sed 's/\..*//g' | tr -d ',' > money

  money=0; cat money | while read money_line; do
    let money+=$money_line
    echo $money > money.tmp
  done;

  echo -n "Cantidad total_" > amount.table
  cat money.tmp >> amount.table

    if [ "$(cat ut.table | wc -l)" != "1" ]; then
      echo -ne "${yellowColour}"
      printTable '_' "$(cat ut.table)"
      echo -ne "${endColour}"
      echo -ne "${blueColour}"
      printTable '_' "$(cat amount.table)"
      echo -ne "${endColour}"
      rm ut.* money* amount.table 2>/dev/null
      tput cnorm; exit 0
    else
      rm ut.t* 2>/dev/null 
    fi

    rm ut.* money* amount.table

    tput cnorm;
}

function inspectTransaction() {
  inspect_transation_hash=$1

  echo "Entradas Totales_Gastos Totales" > total_entrada_salida.tmp

  echo ${inspect_transaction_url}${inspect_transation_hash}

  while [ "$(cat total_entrada_salida.tmp | wc -l)" == "1" ]; do
    curl -s "${inspect_transaction_url}${inspect_transation_hash}" | html2text | grep -E "Entradas totales|Gastos totales"  -A 2 | grep -v "\--" | grep -v -E "Entradas totales|Gastos totales" | sed '/^$/d' | xargs | tr ' ' '_' | sed 's/_BTC/ BTC/g' >> total_entrada_salida.tmp
  done
  
  echo -ne "${grayColour}"
  printTable '_' "$(cat total_entrada_salida.tmp)"
  echo -ne "${endColour}"

  rm total_entrada_salida.tmp 2>/dev/null

  echo "Direccion (Entradas)_Valor" > entradas.tmp

  while [ "$(cat entradas.tmp | wc -l)" == "1" ]; do

  curl -s "${inspect_transaction_url}${inspect_transation_hash}" | html2text | grep "Entradas" -A 500 | grep "Gastos" -B 500  | grep "Direcci" -A 6 | grep -v -E "Direcci|Valor|\--" | sed '/^$/d' | tr -d '[]' | sed -e 's/([^()]*)//g' | sed 'N;s/\n/ /' | awk '{print $1 "_" $2 " " $3}' >> entradas.tmp
  done

  echo -ne "${greenColour}"
  printTable "_" "$(cat entradas.tmp)"
  echo -ne "${endColour}"

  rm entradas.tmp 2>/dev/null

  echo "Direccion (Salidas)_Valor" > salidas.tmp

  while [ "$(cat salidas.tmp | wc -l)" == "1" ]; do

  curl -s "${inspect_transaction_url}${inspect_transation_hash}" | html2text | grep "Gastos" -A 500 | grep "Ya lo has pensado" -B 500 | grep "Direcci" -A 6 | grep -v -E "Direcci|Valor|\--" | sed '/^$/d' | tr -d '[]' | sed -e 's/([^()]*)//g' | sed 'N;s/\n/ /' | awk '{print $1 "_" $2 " " $3}' >> salidas.tmp
  done

  echo -ne "${greenColour}"
  printTable "_" "$(cat salidas.tmp)"
  echo -ne "${endColour}"

  rm salidas.tmp 2>/dev/null
  tput cnorm
}

function inspectAddress() {
  address_hash=$1

  echo "Transacciones realizadas_Cantidad total recibida (BTC)_Cantidad total enviada (BTC)_Saldo total en la cuenta (BTC)" > address.information

  curl -s "${inspect_address_url}${address_hash}" | html2text | grep -E "Transacciones|Total recibido|Total enviado|Saldo final" -A 2 | head -n -4 | grep -v "\--" | sed '/^$/d' | grep -v -E "Transacciones|Total enviado|Total recibido|Saldo final" | xargs | tr ' ' '_' | sed 's/_BTC/ BTC/g' >> address.information

  echo -ne "${grayColour}"
  printTable "_" "$(cat address.information)"
  echo -ne "${endColour}"
  rm address.information 2>/dev/null
}
  

parameter_counter=0; while getopts "e:n:i:a:h:" arg; do
  case $arg in 
    e) exploration_mode=$OPTARG; let parameter_counter+=1;;
    n) number_output=$OPTARG; let parameter_counter+=1;;
    i) inspect_transation=$OPTARG; let parameter_counter+=1;;
    a) inspect_address=$OPTARG; let parameter_counter+=1;;
    h) helpPanel;; 
  esac
done

tput civis 

if [ $parameter_counter -eq 0 ]; then
  helpPanel
else
  if [ "$(echo $exploration_mode)" == "unconfirmed_transactions" ]; then
    if [ ! "$number_output" ]; then
      number_output=100
      unconfirmedTransactions $number_output
    else
      unconfirmedTransactions $number_output
    fi
  elif [ "$(echo $exploration_mode)" == "inspect" ]; then
      inspectTransaction $inspect_transation
  elif [ "$(echo $exploration_mode)" == "address" ]; then
      inspectAddress $inspect_address
  fi  
fi  
