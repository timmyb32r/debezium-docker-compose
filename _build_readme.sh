echo ''>./README.md

echo '# debezium-docker-compose' >>./README.md
echo 'demo cases:' >>./README.md

ls -1d */ | rev | cut -c2- | rev | awk -F\, '{printf("* [%s](https://github.com/timmyb32r/debezium-docker-compose/%s)\n",$1,$1)}' >>./README.md
