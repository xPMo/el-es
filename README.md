# El-Es

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
