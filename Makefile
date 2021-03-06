.PHONY: clean collect test
export PATH := bin:$(PATH)
now := $(shell date '+%Y%m%d_%H%M%S')

all:
	@echo "make [target]"
	@echo "  collect        Vacuum the data from the online calendar"
	@echo "  rest-server    Start the REST server"
	@echo "  clean          Reset everything: empty database, save downloaded ics files"

start-rest-server:
	docker-compose up rest-server

start-rest-server-debug:
	sudo apid -c config/abfall.apid.conf -f start

restart-rest-server:
	sudo apid -c config/abfall.apid.conf restart

reload-rest-server:
	sudo apid -c config/abfall.apid.conf reload

collect:
	docker-compose up collect

test:

clean:
	mkdir .temp/${now}
	-mv .temp/*.ics .temp/${now}/
	-rm .temp/*.ics*
	echo 'DELETE FROM `abfall`.`appointments`;' | /opt/local/lib/mariadb/bin/mysql -hlocalhost --protocol tcp -p3306 -uabfall -pabfall -D abfall
	echo 'DELETE FROM `abfall`.`streets`;' | /opt/local/lib/mariadb/bin/mysql -hlocalhost --protocol tcp -p3306 -uabfall -pabfall -D abfall