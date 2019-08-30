#!/usr/bin/env zsh
# {{{ Default parameter vales
(( $+ELES_COLUMNS )) || ELLES_COLUMNS=(mode_plus nlink user group hsize mtime filename _debug )
# }}}
# {{{ Util
.el_es::column::util::right_justify() {
	# [value] [column name] [ [lpad=1] [rpad=0] ]
	# handles offset and width handling
	local -i offset
	(( offset = ${#1} + ${3:-1} ))
	entry=$'\e['"$offset"D
	(( widths[$2] < offset + ${4:-0} )) &&
		(( widths[$2] = offset + ${4:-0} ))
}
# }}}
# {{{ Debug bar
.el_es::column::_debug(){
	printf -v entry ' |'
	widths[_debug]=-4
}
# }}}
# {{{ Mode
.el_es::column::mode(){
	printf -v entry $hstat[3]
	widths[mode]=-11
}
# }}}
# {{{ Mode with UID/GID mismatches faded 
.el_es::column::mode_plus(){
	entry=${hstat[3][1]}
	(( $+groups )) || groups=( ${=$(groups)} )
	# fade u(rwx)?
	if (( $stat[5] == UID ))
	then entry+="${hstat[3][2,4]}"
	else entry+=$'\e[37m'"${hstat[3][2,4]}"$'\e[0m'
	fi
	# fade g(rwx)?
	if (( ${#hstat[6]:*groups} ))
	then entry+="${hstat[3][5,7]}"
	else entry+=$'\e[37m'"${hstat[3][5,7]}"$'\e[0m'
	fi
	# o(rwx)
	entry+="${hstat[3][8,10]}"
	widths[mode_plus]=-11
}
# }}}
# {{{ Link count 
.el_es::column::nlink(){
	.el_es::column::util::right_justify $stat[4] nlink 1
	if (( hstat[4] > 1 ))
	then entry+=$stat[4]
	else entry+=$'\e[37m'$stat[4]$'\e[0m'
	fi
}
# }}}
# {{{ UID
.el_es::column::uid(){
	.el_es::column::util::right_justify $stat[5] uid
	entry+=$stat[5]
}
# }}}
# {{{ GID
.el_es::column::gid(){
	.el_es::column::util::right_justify $stat[6] gid
	entry+=$stat[6]
}
# }}}
# {{{ User
.el_es::column::user(){
	entry=$hstat[5]
	(( widths[user] > -1 - ${#hstat[5]} )) && (( widths[user] = -1 - ${#hstat[5]} ))
}
# }}}
# {{{ Group
.el_es::column::group(){
	entry=$hstat[6]
	(( widths[group] > -1 - ${#hstat[6]} )) && (( widths[group] = -1 - ${#hstat[6]} ))
}
# }}}
# {{{ Filename coloring
.el_es::column::filename::code () {
	local -i reg=0

	# file type
	case $(( $2 & 0170000 )) in
		$(( 0140000 )) ) codes=( $ftcolors[so] ) ;;
		$(( 0120000 )) ) # symlink, special handling
			if (( $+lstat ))
			then code=$ftcolors[ln]
			else code=$ftcolors[or]
			fi
			return
		;;
		$(( 0100000 )) ) codes=( ); reg=1 ;; # regular file
		$(( 0060000 )) ) codes=( $ftcolors[bd] ) ;;
		$(( 0040000 )) ) codes=( $ftcolors[di] ) ;;
		$(( 0020000 )) ) codes=( $ftcolors[cd] ) ;;
		$(( 0010000 )) ) codes=( $ftcolors[pi] ) ;;
	esac

	# setuid/setgid/sticky/other-writable
	(( $2 & 04000 )) && codes+=( $ftcolors[su] )
	(( $2 & 02000 )) && codes+=( $ftcolors[sg] )
	(( ! reg )) && case $(( $2 & 01002 )) in
		# sticky
		$(( 01000 )) ) codes+=( $ftcolors[st] ) ;;
		# other-writable
		$(( 00002 )) ) codes+=( $ftcolors[ow] ) ;;
		# other-writable and sticky
		$(( 01002 )) ) codes+=( $ftcolors[tw] ) ;;
	esac
	if (( ! $#codes )); then
		(( $2 &  0111 )) && codes+=( $ftcolors[ex] )
		(( $2 &  0111 )) && codes+=( $ftcolors[ex] )
	fi
	code=${(j:;:)codes}

	# this short-circuits
	(( ${#code:=$namecolors[(k)$1]} ))
}

.el_es::column::filename () {
	# (q+) quotes unprintables as $' '
	local name=${(q+)1}
	local code
	local -i len=
	(( len = -${#1} ))
	# get ELES_COLORS code for file
	if ! $0::code $1 $stat[3]; then
		entry=$name
		return
	fi
	local lcode=$code
	case $(( (stat[3] & 0170000 == 0120000) + $+lstat )) in
		0) # no symlink
			printf -v entry '\e[%sm%s\e[0m' $code $name ;;
		2) # working symlink
			$0::code $stat[14] $lstat[3]
			;& # fall-through
		1) # broken symlink
			printf -v entry '\e[%sm%s\e[0m ➔ \e[%sm%s\e[0m' \
				$lcode $name $code $stat[14]
			(( len -= 3 + $#stat[14] ))
			;;
	esac
	# negative width: left-justify
	(( widths[filename] > len )) && (( widths[filename] = len ))
}
# }}}
# {{{ el-es
el-es(){
	setopt localoptions octalzeroes cbases nodotglob extendedglob
	zmodload -F zsh/stat b:zstat

	# read in LS_COLORS
	local -A namecolors
	set -A namecolors ${(@s:=:)${(@s.:.)LS_COLORS}:#[[:alpha:]][[:alpha:]]=*}
	local -A ftcolors
	set -A ftcolors ${(@Ms:=:)${(@s.:.)LS_COLORS}:#[[:alpha:]][[:alpha:]]=*}

	() {
		local avail_functions=(${(@)${(@f)"$(typeset -m -f + -- '.el_es::column::*')"}#*::column::})
		for f in ${ELES_COLUMNS:|avail_functions}; do
			echo >&2 "(no such function '.el_es::column::$f')"
		done
		ELES_COLUMNS=( ${ELLES_COLUMNS:*avail_functions} )
	}

	local -A widths
	local -i len
	# declare array for each column, strip *::
	local -a $^ELES_COLUMNS

	# {{{ Prepare columns
	for f in ${@:-${~:-'*'}}; do

		(( len++ ))

		zstat    -A  stat -L $f
		zstat -s -A hstat -L $f

		# symlink?
		unset lstat hlstat
		if (( $stat[3] & 0170000 == 0120000 )); then
			zstat    -A  lstat $f
			zstat -s -A hlstat $f
		fi

		for column in ${(u)ELES_COLUMNS}; do
			local entry= width=
			.el_es::column::$column $f
			# append to column's associated array
			eval "$column"'+=( $entry )'
		done

	done
	# }}}
	# {{{ Set cursor positions for each column
	# If  w < 0,  left-justified, do not move cursor to right
	# Otherwise, right-justified, must be done by escape sequence in column
	local -A pos
	local -i i=1
	for column in $ELES_COLUMNS; do
		if (( widths[$column] < 0 ))
		then (( pos[$column] = i, i -= widths[$column] ))
		else (( pos[$column] =    i += widths[$column] ))
		fi
	done
	# }}}
	# {{{ Print columns
	for (( i=1; i <= len; i++ )); do
		for column in $ELES_COLUMNS; do
			printf '\e['"${pos[$column]}G%s" ${(P)${column##*::}[i]}
		done
		echo
	done
	# }}}
}
# }}}
[[ $- = *i* ]] || el-es "$@"
# vim:foldmethod=marker
