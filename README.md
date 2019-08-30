# El-Es

Currently, the core functionality is implemented,
and the columns chosen are controlled by the array `$ELES_COLUMNS`.

The equivalent of `ls -lh` would be:
```zsh
ELES_COLUMNS=(mode nlink user group hsize mtime filename)
el-es
```

See the current compatibility status at issues #2 and #3.

---

**Features:**

- Uses `LS_COLORS`!
- That's right, it uses `LS_COLORS`!
- Configure `ls` and `el-es` in the same way using `LS_COLORS`!
- It works.

---

An extensible `ls`.

Define a new column with a new function:

```zsh
.el_es::column::mycolumn(){
	local file size
	file=$1
	if [[ ${hstat[3][1]} = d ]]; then
		size=$stat[8]
		entry=$'\e[1m'"$size"$'\e[0m'
	else
		size='-'
		entry=$size
	fi
	# calculates the offset based on text length,
	# so don't pass it embedded escape codes:
	.el_es::util::right_justify $size
}
ELES_COLUMNS+=(mycolumn)
```
