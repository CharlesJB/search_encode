search_encode
=============

The `search_encode` tool was created to easily fetch ENCODE's files metadata and save them in csv format.

The tool will do a search in the ENCODE database using their REST API
(https://www.encodeproject.org/help/rest-api/).

### Dependencies
* curl
* jq (http://stedolan.github.io/jq/)
* json2csv (https://github.com/jehiah/json2csv)
* csvkit (https://csvkit.readthedocs.org/en/0.9.0/)
* Data Science at the Command Line (https://github.com/jeroenjanssens/data-science-at-the-command-line)

You should be able to call the `curl`, `jq`, `json2csv`, `csvgrep`, `csvjoin` and `body` tools directly (i.e.: without specifying the path).

### Usage
```
search_encode SEARCH_TERM

	SEARCH_TERM: The same search term that would be used to search the
		     ENCODE project web portal (https://www.encodeproject.org/)
```

### Example
```
search_encode "rna-seq+homo+sapiens+esc" > ENCODE_RNA-Seq_hESC.csv
```
