# MongoDB Sharded Cluster Practice

## Setup

```
$ docker compose up -d
$ ./initialize.sh
```

## Connect to databases

```
# Router (mongos)
$ docker compose run --rm client mongo router:27017/app

# Primary Shard
$ docker compose run --rm client mongo shard-a-01:27018/app

# Secondary Shard
$ docker compose run --rm client mongo shard-b-01:27018/app
```

## Destroy

```
$ docker compose down -v
```
