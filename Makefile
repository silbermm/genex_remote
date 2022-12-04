
DB_PATH := genex_v2_dev.db
PORT 	  := 4001

help:
	@fgrep -h "##" $(MAKEFILE_LIST) | fgrep -v fgrep | sed -e 's/\\$$//' | sed -e 's/##//'

iex:
	iex --sname a -S mix phx.server

iex2:
	DATABASE_PATH="${DB_PATH}" PORT=${PORT} iex --sname b -S mix phx.server

