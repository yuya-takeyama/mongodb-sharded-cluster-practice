#!/bin/bash

set -ue
set -o pipefail

echo "Setting up Config Server Replica Set"
docker-compose run --rm client mongo config-01:27019 --quiet --eval 'rs.initiate({_id: "rs-config", configsvr: true, members: [{_id: 0, host: "config-01:27019"}, {_id: 1, host: "config-02:27019"}, {_id: 2, host: "config-03:27019"}]});'

echo "Setting up Secondary Shard Replica Set"
docker-compose run --rm client mongo shard-b-01:27018 --quiet --eval 'rs.initiate({_id: "rs-shard-b", members: [{_id: 0, host: "shard-b-01:27018"}, {_id: 1, host: "shard-b-02:27018"}, {_id: 2, host: "shard-b-03:27018"}]});'
docker-compose run --rm client mongo shard-c-01:27018 --quiet --eval 'rs.initiate({_id: "rs-shard-c", members: [{_id: 0, host: "shard-c-01:27018"}, {_id: 1, host: "shard-c-02:27018"}, {_id: 2, host: "shard-c-03:27018"}]});'
docker-compose run --rm client mongo shard-d-01:27018 --quiet --eval 'rs.initiate({_id: "rs-shard-d", members: [{_id: 0, host: "shard-d-01:27018"}, {_id: 1, host: "shard-d-02:27018"}, {_id: 2, host: "shard-d-03:27018"}]});'
docker-compose run --rm client mongo shard-e-01:27018 --quiet --eval 'rs.initiate({_id: "rs-shard-e", members: [{_id: 0, host: "shard-e-01:27018"}, {_id: 1, host: "shard-e-02:27018"}, {_id: 2, host: "shard-e-03:27018"}]});'
docker-compose run --rm client mongo shard-f-01:27018 --quiet --eval 'rs.initiate({_id: "rs-shard-f", members: [{_id: 0, host: "shard-f-01:27018"}, {_id: 1, host: "shard-f-02:27018"}, {_id: 2, host: "shard-f-03:27018"}]});'

echo "Wait for 10 seconds..."
sleep 10

echo "Setting up Shards"
docker-compose run --rm client mongo router:27017/config --quiet --eval '
  db.settings.save({_id: "chunksize", value: 1});
  sh.addShard("rs-shard-a/shard-a-01:27018,shard-a-02:27018,shard-a-03:27018");
  sh.addShard("rs-shard-b/shard-b-01:27018,shard-b-02:27018,shard-b-03:27018");
  sh.addShard("rs-shard-c/shard-c-01:27018,shard-c-02:27018,shard-c-03:27018");
  sh.addShard("rs-shard-d/shard-d-01:27018,shard-d-02:27018,shard-d-03:27018");
  sh.addShard("rs-shard-e/shard-e-01:27018,shard-e-02:27018,shard-e-03:27018");
  sh.addShard("rs-shard-f/shard-f-01:27018,shard-f-02:27018,shard-f-03:27018");
  sh.enableSharding("app");
  sh.shardCollection("app.users", {name: "hashed"});
'

echo "Wait for 10 seconds..."
sleep 10

echo "Inserting data..."
docker-compose run --rm client mongo router:27017/app --quiet --eval '
  sh.stopBalancer();

  for (var i = 1; i <= 100000; i++) {
    db.users.insert({
      name: "User-" + i,
      age: Math.floor(Math.random() * 100),
      introduction: {
        favorite_song: {
          artist: "Nogizaka46",
          title: "I See",
          year: 2020,
          liked: true
        },
        messages: [
          "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.",
          "Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.",
          "Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur.",
          "Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum."
        ]
      },
      created_at: new Date
    });
  }

  sh.startBalancer();
'

echo "Done"
