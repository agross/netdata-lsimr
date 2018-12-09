# shellcheck shell=bash
# no need for shebang - this file is loaded from charts.d.plugin

# _update_every is a special variable - it holds the number of seconds
# between the calls of the _update() function
lsrimr_update_every=

# the priority is used to sort the charts on the dashboard
# 1 = the first chart
lsimr_priority=150000

lsimr_ssh_identity_file=
lsimr_ssh_host=

declare -A lsimr_queries
lsimr_queries[controller]='Controller = ([[:digit:]]+)'
lsimr_queries[model]='Model = ([[:print:]]+)'
lsimr_queries[serial]='Serial Number = ([[:print:]]+)'
lsimr_queries[temp]='ROC temperature\(Degree Celsius\) = ([[:digit:]]+)'
lsimr_queries[bbu]='Cachevault_Info.*[[:space:]]([[:digit:]]+)C'

declare -A lsimr_data

lsimr_get() {
  # do all the work to collect / calculate the values
  # for each dimension
  #
  # Remember:
  # 1. KEEP IT SIMPLE AND SHORT
  # 2. AVOID FORKS (avoid piping commands)
  # 3. AVOID CALLING TOO MANY EXTERNAL PROGRAMS
  # 4. USE LOCAL VARIABLES (global variables may overlap with other modules)

  local output="$(ssh -o StrictHostKeyChecking=no \
                      -o LogLevel=QUIET \
                      -o PasswordAuthentication=no \
                      -o UserKnownHostsFile=/dev/null \
                      -i "$lsimr_ssh_identity_file" \
                      "$lsimr_ssh_host" \
                      storcli /cALL show all)"

  local key query
  for key in "${!lsimr_queries[@]}"; do
    query="${lsimr_queries[$key]}"

    if [[ "$output" =~ $query ]]; then
      lsimr_data[$key]="${BASH_REMATCH[1]}"
    fi
  done

  # this should return:
  #  - 0 to send the data to netdata
  #  - 1 to report a failure to collect the data

  return 0
}

# _check is called once, to find out if this chart should be enabled or not
lsimr_check() {
  # this should return:
  #  - 0 to enable the chart
  #  - 1 to disable the chart

  # check that we can collect data.
  ssh -o StrictHostKeyChecking=no \
      -o LogLevel=ERROR \
      -o PasswordAuthentication=no \
      -o UserKnownHostsFile=/dev/null \
      -i "$lsimr_ssh_identity_file" \
      "$lsimr_ssh_host" \
      storcli -v > /dev/null
}

# _create is called once, to create the charts
lsimr_create() {
  lsimr_get || return 1

  printf 'CHART "LSI MegaRAID.%s" "" "%s temperatures" "temperature" "Controller %s" "" line %s %s\n' \
         "${lsimr_data[serial]}" "${lsimr_data[model]}" "${lsimr_data[controller]}" "$((lsimr_priority))" "$lsimr_update_every"

  printf 'DIMENSION temp "ROC temperature" absolute 1 1\n'
  printf 'DIMENSION bbu  "BBU temperature" absolute 1 1\n'

  return 0
}

# _update is called continuously, to collect the values
lsimr_update() {
  # the first argument to this function is the microseconds since last update
  # pass this parameter to the BEGIN statement (see bellow).

  lsimr_get || return 1

  # write the result of the work.
  cat <<VALUESEOF
BEGIN "LSI MegaRAID.${lsimr_data[serial]}" $1
SET temp = ${lsimr_data[temp]}
SET bbu  = ${lsimr_data[bbu]}
END
VALUESEOF

  return 0
}
