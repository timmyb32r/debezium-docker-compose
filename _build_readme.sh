echo ''>./README.md

echo '# debezium-docker-compose\n\n' >>./README.md
echo 'demo cases:\n\n' >>./README.md

ls -1d */ | awk '{print("* ",$1)}' | rev | cut -c2- | rev >>./README.md
