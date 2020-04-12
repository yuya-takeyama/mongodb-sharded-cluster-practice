#!/bin/bash

set -ue
set -o pipefail

echo "Setting up Config Server Replica Set"
docker-compose run --rm client mongo config-01:27019 --eval 'rs.initiate({_id: "rs-config", configsvr: true, members: [{_id: 0, host: "config-01:27019"}, {_id: 1, host: "config-02:27019"}, {_id: 2, host: "config-03:27019"}]});'

echo "Setting up Primary Shard Replica Set"
docker-compose run --rm client mongo shard-a-01:27018 --eval 'rs.initiate({_id: "rs-shard-a", members: [{_id: 0, host: "shard-a-01:27018"}, {_id: 1, host: "shard-a-02:27018"}, {_id: 2, host: "shard-a-03:27018"}]});'

echo "Setting up Secondary Shard Replica Set"
docker-compose run --rm client mongo shard-b-01:27018 --eval 'rs.initiate({_id: "rs-shard-b", members: [{_id: 0, host: "shard-b-01:27018"}, {_id: 1, host: "shard-b-02:27018"}, {_id: 2, host: "shard-b-03:27018"}]});'

echo "Wait for 30 seconds..."
sleep 30

echo "Setting up Shards"
docker-compose run --rm client mongo router:27017 --eval 'sh.addShard("rs-shard-a/shard-a-01:27018,shard-a-02:27018,shard-a-03:27018");'
docker-compose run --rm client mongo router:27017 --eval 'sh.addShard("rs-shard-b/shard-b-01:27018,shard-b-02:27018,shard-b-03:27018");'
docker-compose run --rm client mongo router:27017 --eval 'sh.enableSharding("app");'
docker-compose run --rm client mongo router:27017 --eval 'sh.shardCollection("app.users", {_id: "hashed"});'

echo "Wait for 10 seconds..."
sleep 10

echo "Inserting data..."
docker-compose run --rm client mongo router:27017/app --eval 'for (var i = 1; i <= 1000; i++) { db.users.insert({name: "User-" + i}); db.posts.insert({title: "Post-" + i}); }'

echo "Done"
