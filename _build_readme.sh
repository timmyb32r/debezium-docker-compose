echo ''>./README.md

echo '# debezium-docker-compose' >>./README.md
echo 'demo cases:' >>./README.md

ls -1d */ | awk '{print("* ",$1)}' | rev | cut -c2- | rev >>./README.md
