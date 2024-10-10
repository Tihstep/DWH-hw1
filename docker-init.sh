docker-compose up -d postgres_master
sleep 3
docker-compose restart postgres_master
sleep 3

echo "Starting slave node..."
docker-compose up -d  postgres_slave

echo "Done" 
